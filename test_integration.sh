#!/bin/bash
# Integration test script — Hacienda La Ilusión
# Run after: docker-compose up -d

BASE_URL="${API_URL:-http://localhost:3000}"
PASS=0
FAIL=0

pass() { echo "✅ PASS: $1"; ((PASS++)); }
fail() { echo "❌ FAIL: $1 — $2"; ((FAIL++)); }

check() {
  local label="$1"
  local response="$2"
  local expected="$3"
  if echo "$response" | grep -q "$expected"; then
    pass "$label"
  else
    fail "$label" "Expected '$expected' in: $response"
  fi
}

echo ""
echo "🌴 Hacienda La Ilusión — Integration Tests"
echo "   Target: $BASE_URL"
echo "==========================================="

# ── STEP 1: Health check ──────────────────────────────────────
R=$(curl -s "$BASE_URL/health")
check "Health check" "$R" '"status":"ok"'

# ── STEP 2: Admin login ───────────────────────────────────────
R=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"cedula":"1099999999","password":"admin1234"}')
check "Admin login (cedula+password)" "$R" '"success":true'
TOKEN=$(echo "$R" | sed 's/.*"token":"\([^"]*\)".*/\1/')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "$R" ]; then
  fail "Extract JWT token" "Token not found in response"
  echo ""
  echo "⚠️  Cannot continue without auth token. Check admin password in seed.sql"
  echo "   Remaining tests skipped."
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi
pass "Extract JWT token"

AUTH="Authorization: Bearer $TOKEN"

# ── STEP 3: Create test worker ────────────────────────────────
WORKER_COD="TEST$(date +%s)"
R=$(curl -s -X POST "$BASE_URL/trabajadores" \
  -H "Content-Type: application/json" \
  -H "$AUTH" \
  -d "{\"cod_cosechero\":\"$WORKER_COD\",\"cedula\":\"9$(date +%s)\",\"nombre_completo\":\"Test Cosechador\",\"pin\":\"1111\",\"rol\":\"cosechador\",\"zona\":1}")
check "Create test worker" "$R" '"success":true'
WORKER_ID=$(echo "$R" | sed 's/.*"trabajador_id":"\([^"]*\)".*/\1/')

# ── STEP 4: Worker PIN login ──────────────────────────────────
R=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"cod_cosechero\":\"$WORKER_COD\",\"pin\":\"1111\"}")
check "Worker login (cod+PIN)" "$R" '"success":true'
WORKER_TOKEN=$(echo "$R" | sed 's/.*"token":"\([^"]*\)".*/\1/')
WORKER_AUTH="Authorization: Bearer $WORKER_TOKEN"

# ── STEP 5: Get lotes ─────────────────────────────────────────
R=$(curl -s "$BASE_URL/lotes" -H "$AUTH")
check "Get lotes" "$R" '"success":true'
LOTE_ID=$(echo "$R" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data'][0]['lote_id'])" 2>/dev/null || echo "1")

# ── STEP 6: Single cosecha record ────────────────────────────
UUID1=$(python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || cat /proc/sys/kernel/random/uuid)
R=$(curl -s -X POST "$BASE_URL/cosecha" \
  -H "Content-Type: application/json" \
  -H "$WORKER_AUTH" \
  -d "{\"cosecha_id\":\"$UUID1\",\"trabajador_id\":\"$WORKER_ID\",\"cod_cosechero\":\"$WORKER_COD\",\"lote_id\":$LOTE_ID,\"fecha_corte\":\"$(date +%Y-%m-%d)\",\"tipo_cosecha\":\"MECANIZADA\",\"total_racimos\":85,\"peso_extractora_sin_recolector\":1250.5}")
check "POST single cosecha" "$R" '"success":true'

# ── STEP 7: Batch cosecha sync (5 records) ───────────────────
BATCH_RECORDS="["
for i in 1 2 3 4 5; do
  UID=$(python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || cat /dev/urandom | tr -dc 'a-f0-9' | head -c 32 | sed 's/\(.\{8\}\)\(.\{4\}\)\(.\{4\}\)\(.\{4\}\)\(.\{12\}\)/\1-\2-\3-\4-\5/')
  BATCH_RECORDS="$BATCH_RECORDS{\"cosecha_id\":\"$UID\",\"trabajador_id\":\"$WORKER_ID\",\"cod_cosechero\":\"$WORKER_COD\",\"lote_id\":$LOTE_ID,\"fecha_corte\":\"$(date +%Y-%m-%d)\",\"tipo_cosecha\":\"MECANIZADA\",\"total_racimos\":$((50+i*10)),\"peso_extractora_sin_recolector\":$((800+i*100)).0,\"created_offline\":true}"
  [ $i -lt 5 ] && BATCH_RECORDS="$BATCH_RECORDS,"
done
BATCH_RECORDS="$BATCH_RECORDS]"

R=$(curl -s -X POST "$BASE_URL/cosecha/sync" \
  -H "Content-Type: application/json" \
  -H "$WORKER_AUTH" \
  -d "{\"records\":$BATCH_RECORDS}")
check "POST cosecha/sync (5 records)" "$R" '"synced":5'

# ── STEP 8: Idempotent sync (same records, should be duplicates) ──
R=$(curl -s -X POST "$BASE_URL/cosecha/sync" \
  -H "Content-Type: application/json" \
  -H "$WORKER_AUTH" \
  -d "{\"records\":$BATCH_RECORDS}")
check "Idempotent sync (duplicates=5)" "$R" '"duplicates":5'

# ── STEP 9: Batch fertilizacion sync (2 records) ─────────────
FERT_RECORDS="["
for i in 1 2; do
  UID=$(python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || cat /dev/urandom | tr -dc 'a-f0-9' | head -c 32)
  FERT_RECORDS="$FERT_RECORDS{\"fertilizacion_id\":\"$UID\",\"trabajador_id\":\"$WORKER_ID\",\"lote_id\":$LOTE_ID,\"fecha\":\"$(date +%Y-%m-%d)\",\"palmas_fertilizadas\":$((80+i*20)),\"dosis_por_palma\":2.5,\"total_aplicado\":$((200+i*50)).0}"
  [ $i -lt 2 ] && FERT_RECORDS="$FERT_RECORDS,"
done
FERT_RECORDS="$FERT_RECORDS]"

R=$(curl -s -X POST "$BASE_URL/fertilizacion/sync" \
  -H "Content-Type: application/json" \
  -H "$WORKER_AUTH" \
  -d "{\"records\":$FERT_RECORDS}")
check "POST fertilizacion/sync (2 records)" "$R" '"synced":2'

# ── STEP 10: Dashboard KPIs ───────────────────────────────────
R=$(curl -s "$BASE_URL/dashboard/kpis" -H "$AUTH")
check "GET dashboard/kpis" "$R" '"success":true'
check "KPIs has racimos_hoy" "$R" 'racimos_hoy'
check "KPIs has top_trabajadores" "$R" 'top_trabajadores_semana'

# ── STEP 11: Gamification endpoint ───────────────────────────
R=$(curl -s "$BASE_URL/gamificacion/$WORKER_COD/hoy" -H "$WORKER_AUTH")
check "GET gamificacion/:cod/hoy" "$R" '"success":true'
check "Gamification has ganancias_hoy_cop" "$R" 'ganancias_hoy_cop'

# ── STEP 12: Payment engine ───────────────────────────────────
TODAY=$(date +%Y-%m-%d)
DAY=$(date +%d)
if [ "$DAY" -le 15 ]; then
  PERIODO_INICIO="$(date +%Y-%m)-01"
  PERIODO_FIN="$(date +%Y-%m)-15"
else
  PERIODO_INICIO="$(date +%Y-%m)-16"
  PERIODO_FIN="$(date +%Y-%m-%d)"
fi

R=$(curl -s -X POST "$BASE_URL/liquidacion/calcular" \
  -H "Content-Type: application/json" \
  -H "$AUTH" \
  -d "{\"trabajador_id\":\"$WORKER_ID\",\"periodo_inicio\":\"$PERIODO_INICIO\",\"periodo_fin\":\"$PERIODO_FIN\"}")
check "POST liquidacion/calcular" "$R" '"success":true'
check "Payment engine has total_pagar" "$R" 'total_pagar'
check "Payment engine has detalle" "$R" 'detalle'

# ── STEP 13: Libra CSV export ─────────────────────────────────
R=$(curl -s -o /dev/null -w "%{http_code}" \
  "$BASE_URL/liquidacion/export/csv?fecha_inicio=$PERIODO_INICIO&fecha_fin=$PERIODO_FIN" \
  -H "$AUTH")
if [ "$R" = "200" ]; then
  pass "GET liquidacion/export/csv (HTTP 200)"
else
  fail "GET liquidacion/export/csv" "Got HTTP $R"
fi

# Verify column headers
R=$(curl -s "$BASE_URL/liquidacion/export/csv?fecha_inicio=$PERIODO_INICIO&fecha_fin=$PERIODO_FIN" -H "$AUTH")
check "Libra CSV has FECHA CREACION column" "$R" 'FECHA CREACION'
check "Libra CSV has COD COSECHERO column" "$R" 'COD COSECHERO'
check "Libra CSV has PESO EXTRACTORA SIN RECOLECTOR column" "$R" 'PESO EXTRACTORA SIN RECOLECTOR'

# ── RESULTS ───────────────────────────────────────────────────
echo ""
echo "==========================================="
echo "Test Results: $PASS passed  |  $FAIL failed"
echo "==========================================="
echo ""
[ $FAIL -eq 0 ] && echo "🎉 All tests passed!" && exit 0 || exit 1
