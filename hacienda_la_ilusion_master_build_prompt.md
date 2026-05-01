# 🌴 Sistema de Gestión Agrícola — Palma Africana
## Master Build Prompt v2.0 — Hacienda La Ilusión

---

## Role

Act as a **senior full-stack software architect and agricultural technology specialist** with deep experience building:
- Offline-first mobile applications for field operations with zero connectivity
- Agricultural management systems for tropical crop operations in Latin America
- Payment calculation engines based on weight-per-bunch × price-per-kg tariff structures
- Gamified worker-facing applications designed for retention in blue-collar environments
- Real-time sync architectures that reconcile offline data when connectivity is restored
- Web dashboards for operations managers tracking up to 200 field workers

You are the technical lead for this project. You make stack decisions, define the architecture, write the code, structure the database, and build every component autonomously using Claude Code. You never ask unnecessary questions — you build, show the result, and iterate.

---

## System Overview

Build a **three-layer agricultural management system** for Hacienda La Ilusión, an African palm (palma de aceite) operation in Colombia:

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: Android Field App (Offline-First)                 │
│  Flutter · SQLite · Background Sync                          │
│  Used by: cosechadores, recolectores, fertilizadores        │
│  Primary purpose: earnings transparency + gamification      │
├─────────────────────────────────────────────────────────────┤
│  LAYER 2: Backend API + Database                             │
│  Node.js + Express · PostgreSQL · REST API                   │
│  Used by: sync engine, dashboard, payment calculator        │
├─────────────────────────────────────────────────────────────┤
│  LAYER 3: Web Dashboard (Online)                             │
│  React + Vite + Tailwind · Real-time KPIs                    │
│  Used by: administrators, finance, operations managers      │
└─────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Android App: Flutter
- Superior offline SQLite integration via `sqflite`
- Background sync via `workmanager`
- Native Android performance — critical for budget devices
- Target: Android API 26+ (covers 95%+ of Colombian field devices)
- Direct APK distribution via WhatsApp — no Play Store required

### Backend: Node.js + Express + PostgreSQL
- Hosted on Railway (zero-maintenance deployment)
- REST API for sync, authentication, dashboard data
- JWT authentication per role
- No ORM — raw parameterized SQL

### Web Dashboard: React + Vite + Tailwind CSS
- Operations manager and finance dashboard
- 60-second polling for KPI refresh
- Recharts for production charts
- CSV export matching Libra ERP import format

---

## Business Context

**The core problem being solved is worker retention, not just data collection.**

Workers currently don't know what they've earned until payday (bi-weekly). This lack of transparency combined with weak incentives is causing personnel shortages that directly reduce harvest output. The Android app's primary job is to make earnings visible, motivating, and gamified — so workers stay and perform.

**Existing system:** Libra ERP (EDISA) receives harvest data via CSV export. Our system must produce a CSV that matches Libra's import format exactly, so the finance team's workflow is not disrupted.

---

## Domain Data Model

```
TRABAJADOR (Field Worker)
├── trabajador_id (PK, UUID)
├── cod_cosechero (unique — e.g., HLI050, TT639 — matches Libra ERP)
├── cedula (national ID, secondary identifier)
├── nombre_completo
├── telefono
├── pin (4-digit, for offline app login)
├── rol (cosechador / recolector / fertilizador / supervisor / admin)
├── zona (1 / 2 / 3 / 4 — determines which lotes they work)
├── activo (boolean)
└── fecha_ingreso

LOTE
├── lote_id (PK)
├── cod_lote (matches Libra — e.g., "042")
├── nombre (e.g., "Lote 21A")
├── zona (1–4)
├── hectareas
├── numero_palmas
├── peso_promedio_kg (average bunch weight for this lote — used in payment calc)
└── año_siembra

COSECHA (Harvest Event — one row per worker per lote per ticket)
├── cosecha_id (UUID — generated on device)
├── trabajador_id (FK)
├── cod_cosechero (denormalized for Libra export)
├── lote_id (FK)
├── ticket_extractora
├── fecha_corte (date of harvest)
├── fecha_creacion (when record was created on device)
├── tipo_cosecha (RECOLECTOR_DE_RACIMOS / MECANIZADA)
├── metodo_recoleccion (CON_TIJERA / NO_APLICA)
├── total_racimos (integer)
├── peso_extractora_sin_recolector (kg — authoritative weight from plant)
├── total_racimos_recolector (if tipo = RECOLECTOR)
├── peso_extractora_recolector (if tipo = RECOLECTOR)
├── observaciones
├── sync_status (pending / synced)
├── created_offline (boolean)
└── device_id

FERTILIZACION (Fertilization Event)
├── fertilizacion_id (UUID — generated on device)
├── trabajador_id (FK)
├── lote_id (FK)
├── fecha
├── palmas_fertilizadas (count)
├── dosis_por_palma (kg or units — varies by lote/zone)
├── total_aplicado (palmas × dosis — calculated)
├── observaciones
├── sync_status (pending / synced)
└── device_id

AUSENCIA (Absence Record)
├── ausencia_id (UUID)
├── trabajador_id (FK)
├── fecha
├── justificada (boolean)
├── motivo
└── registrado_por (supervisor cod_cosechero)

TARIFA (Admin-Configurable Rate Table)
├── tarifa_id (PK)
├── tipo_labor (cosecha_recolector / cosecha_mecanizada / fertilizacion)
├── zona (1–4, nullable = applies to all zones)
├── precio_por_kg (COP — for cosecha types)
├── precio_por_unidad (COP — for fertilizacion)
├── fecha_inicio
├── fecha_fin (nullable = currently active)
└── activa (boolean)

INCENTIVO (Milestone Incentive Plan)
├── incentivo_id (PK)
├── nombre (e.g., "Bono por asistencia perfecta")
├── tipo (dias_trabajados / racimos_semana / racimos_quincena)
├── umbral (threshold value — e.g., 10 days worked)
├── monto_bono (COP)
├── activo (boolean)
└── descripcion

LIQUIDACION (Bi-weekly Payment Settlement)
├── liquidacion_id (PK)
├── trabajador_id (FK)
├── periodo_inicio
├── periodo_fin
├── dias_trabajados
├── dias_ausencia_injustificada
├── total_racimos
├── total_kg
├── monto_cosecha (COP)
├── monto_fertilizacion (COP)
├── monto_bonos (COP)
├── deducciones (COP)
├── total_pagar (COP)
├── estado (pendiente / aprobada / pagada)
└── fecha_pago
```

---

## Payment Calculation Engine

```
FOR EACH cosecha record in period (by trabajador + fecha range):

  IF tipo_cosecha = 'RECOLECTOR_DE_RACIMOS':
    pago_cosecha = peso_extractora_sin_recolector × tarifa(cosecha_recolector, zona)
    pago_recolector = peso_extractora_recolector × tarifa(cosecha_recolector, zona)
    subtotal = pago_cosecha + pago_recolector

  IF tipo_cosecha = 'MECANIZADA':
    subtotal = peso_extractora_sin_recolector × tarifa(cosecha_mecanizada, zona)

FOR EACH fertilizacion record in period:
  pago_fertilizacion = total_aplicado × tarifa(fertilizacion, zona)

BONOS:
  FOR EACH active incentivo:
    IF tipo = 'dias_trabajados' AND dias_trabajados >= umbral:
      monto_bonos += incentivo.monto_bono
    IF tipo = 'racimos_quincena' AND total_racimos >= umbral:
      monto_bonos += incentivo.monto_bono

DEDUCCIONES:
  deduccion_ausencias = dias_ausencia_injustificada × valor_dia_base

TOTAL = monto_cosecha + monto_fertilizacion + monto_bonos - deducciones
```

---

## Libra ERP Export Format

The system must export CSV files matching this exact column structure for Libra import:

```
FECHA CREACION, TICKET EXTRACTORA, COD COSECHERO, COSECHERO,
COD LOTE, LOTE, ZONA, TIPO COSECHA, METODO_RECOLECCION,
TOTAL RACIMOS, PESO EXTRACTORA SIN RECOLECTOR
```

Export is available from the dashboard for any date range. Format must match Hacienda La Ilusión's existing Libra configuration exactly — period separators for thousands, comma for decimals, DD/MM/YYYY dates.

---

## Phase 1 — Database & Backend API

### Claude Code Prompt — Phase 1:

```
## Role
You are a senior backend engineer building an agricultural management API
for Hacienda La Ilusión, an African palm operation in Colombia.

## Task
1. Initialize a Node.js project with:
   express, pg, jsonwebtoken, bcrypt, dotenv, cors, uuid, date-fns-tz

2. Create PostgreSQL schema (schema.sql) with all tables:
   trabajador, lote, cosecha, fertilizacion, ausencia,
   tarifa, incentivo, liquidacion
   (full schema defined above in master prompt)

3. Build REST API with these endpoint groups:

   AUTH:
   POST /auth/login → JWT with role payload
     - Admin/supervisor: cedula + password
     - Field worker: cod_cosechero + 4-digit PIN

   TRABAJADORES:
   GET  /trabajadores → list with filters (zona, rol, activo)
   POST /trabajadores → create worker
   PUT  /trabajadores/:id → update worker
   GET  /trabajadores/:id/resumen → earnings summary for gamification

   LOTES:
   GET  /lotes → list with zona filter
   POST /lotes → create lote
   PUT  /lotes/:id → update (including peso_promedio)

   COSECHA:
   POST /cosecha → single record
   GET  /cosecha → filter by trabajador, lote, fecha range
   POST /cosecha/sync → BATCH sync from Android:
     - Receives array of cosecha records
     - Deduplicates by cosecha_id (UUID) — idempotent
     - Returns { synced: N, duplicates: N, errors: [] }

   FERTILIZACION:
   POST /fertilizacion/sync → batch sync, same pattern as cosecha
   GET  /fertilizacion → filter by trabajador, lote, fecha

   AUSENCIAS:
   POST /ausencias → record absence (supervisor only)
   GET  /ausencias?trabajador_id=&periodo=

   TARIFAS:
   GET  /tarifas → current active rates
   POST /tarifas → create new rate (deactivates previous)

   INCENTIVOS:
   GET  /incentivos → all active incentive plans
   POST /incentivos → create incentive milestone
   PUT  /incentivos/:id → update or deactivate

   LIQUIDACION:
   POST /liquidacion/calcular → calculate payment for worker + period
     Returns full itemized breakdown per the payment engine above
   GET  /liquidacion → list with filters
   PUT  /liquidacion/:id/estado → approve / mark paid
   GET  /liquidacion/export/csv → Libra-format CSV export

   DASHBOARD:
   GET /dashboard/kpis → {
     racimos_hoy, racimos_semana, kg_hoy, kg_semana,
     trabajadores_activos_hoy, pagos_pendientes_cop,
     produccion_por_zona, top_trabajadores_semana (top 7 by racimos),
     registros_pendientes_sync
   }

   GAMIFICATION (called by Android app):
   GET /gamificacion/:cod_cosechero/hoy → {
     racimos_hoy, kg_hoy, ganancias_hoy_cop,
     ganancias_quincena_cop, dias_trabajados_quincena,
     proximo_bono: { nombre, umbral, progreso, monto_cop },
     posicion_leaderboard (1–7 or null if outside top 7),
     leaderboard_top7: [{ nombre, racimos_semana, posicion }]
   }

4. Build the payment calculation engine in /services/paymentEngine.js
   implementing the exact formula defined in the master prompt above.

5. Build the Libra CSV export service in /services/libraExport.js:
   - Exact column headers matching Libra format
   - DD/MM/YYYY date format
   - Colombian number format (period thousands, comma decimal)
   - Filterable by date range

6. Create seed data (seed.sql):
   - 4 zonas, 10 lotes (matching real Lote names from CSV: Lote 21A, Lote 10B, etc.)
   - 15 trabajadores (mix of cosechadores, recolectores, fertilizadores)
   - 2 active tarifas (cosecha_recolector + mecanizada)
   - 1 fertilizacion tarifa
   - 2 incentivos (dias_trabajados threshold + racimos_quincena threshold)
   - 30 sample cosecha records across 7 days

## Constraints
- America/Bogota timezone for all date operations
- UUID for all sync-able entities (cosecha_id, fertilizacion_id)
- Consistent response envelope: { success: boolean, data: {}, error: string }
- Log every sync: worker, records_received, inserted, duplicates
- Role-based middleware: admin routes reject non-admin tokens
- Never hardcode credentials — all from .env
- Raw SQL only — no ORM

## Output files:
/backend/server.js
/backend/routes/ (one per entity)
/backend/services/paymentEngine.js
/backend/services/libraExport.js
/backend/middleware/auth.js
/backend/db/schema.sql
/backend/db/seed.sql
/backend/.env.example
/backend/README.md

## Stop Condition
Stop after all files are created and the server starts without errors.
Run: node server.js and confirm "Server running on port 3000".
Show me the list of all endpoints before proceeding.
```

---

## Phase 2 — Flutter Android App (Offline-First + Gamified)

### Claude Code Prompt — Phase 2:

```
## Role
You are a senior Flutter developer building an offline-first Android app
for field workers at Hacienda La Ilusión, an African palm plantation in Colombia.
The app's primary purpose is earnings transparency and gamification to improve
worker retention. Data collection is secondary.

## Task
1. Initialize Flutter project targeting Android API 26+
2. pubspec.yaml dependencies:
   sqflite, connectivity_plus, workmanager, http, uuid,
   shared_preferences, provider, intl, fl_chart, lottie

3. Role-based app experience:
   The app detects worker role on login and shows role-specific screens:
   - cosechador / recolector → Cosecha flow + earnings
   - fertilizador → Fertilización flow + earnings
   - supervisor → All workers summary + absence recording
   All roles see: leaderboard, personal earnings, sync status

4. LOCAL SQLite SCHEMA (mirrors backend):
   trabajador_local, lote_local, cosecha_local (+ sync_status),
   fertilizacion_local (+ sync_status), ausencia_local,
   tarifa_local, incentivo_local

5. SCREENS:

   SCREEN 1 — Login (fully offline):
   - Input: cod_cosechero + 4-digit PIN
   - Authenticate against local trabajador_local table
   - Large text, high contrast, Spanish only
   - Show worker name and zone on success

   SCREEN 2 — Inicio (Home — role-aware):
   COSECHADOR/RECOLECTOR HOME:
   - Hero number: "Ganancias hoy" in large COP format
   - Secondary: racimos hoy / kg hoy
   - Progress bar: días trabajados esta quincena toward bono milestone
   - Próximo bono card: "Trabaja X días más y ganas $XX,000"
   - Quick action button: "Registrar Cosecha" (one tap)

   FERTILIZADOR HOME:
   - Hero number: "Ganancias hoy" in large COP format
   - Secondary: palmas fertilizadas hoy
   - Progress bar: días trabajados toward milestone
   - Quick action: "Registrar Fertilización"

   SUPERVISOR HOME:
   - Team summary: workers active today, total racimos team
   - Pending sync records count
   - Quick action: "Registrar Ausencia"

   SCREEN 3 — Registrar Cosecha (cosechador/recolector only):
   Target: 4 taps maximum to complete a record
   - Lote selector (dropdown — pre-filtered by worker's zona)
   - Tipo cosecha (RECOLECTOR_DE_RACIMOS / MECANIZADA) — toggle
   - Total racimos (numeric input, large keyboard)
   - Peso extractora (optional — may not be known in field)
   - Save → cosecha_local with sync_status='pending', UUID generated on device
   - Confirmation: "✅ Registrado. Ganancias estimadas hoy: $XX,000"
   - Estimated earnings calculated locally from tarifa_local

   SCREEN 4 — Registrar Fertilización (fertilizador only):
   - Lote selector (filtered by zona)
   - Palmas fertilizadas (numeric)
   - Dosis por palma (pre-filled from lote config, editable)
   - Total aplicado: auto-calculated (palmas × dosis)
   - Save → fertilizacion_local with sync_status='pending'
   - Confirmation with estimated earnings

   SCREEN 5 — Mis Ganancias:
   - Quincena actual: breakdown card
     Cosecha: $XX,000 | Fertilización: $XX,000 | Bonos: $XX,000
   - Daily bar chart: earnings per day this quincena (fl_chart)
   - Días trabajados: progress toward next milestone
   - All calculated locally from local DB + tarifa_local

   SCREEN 6 — Leaderboard (all roles):
   - Title: "Top 7 esta semana"
   - Show only top 7 workers by racimos this week
   - Each card: position medal (🥇🥈🥉 then 4–7), nombre, racimos
   - If logged-in worker IS in top 7: highlight their card
   - If NOT in top 7: show their personal stats below leaderboard
     "Tu posición: #12 | Tus racimos: 847 | Sigue así 💪"
   - Never show workers ranked below 7 to others

   SCREEN 7 — Sincronización:
   - Pending cosecha records count
   - Pending fertilizacion records count
   - Last sync timestamp
   - Manual sync button
   - Connectivity indicator: 🔴 Sin señal / 🟢 Conectado
   - Log of last 5 sync events

6. SYNC ENGINE:
   ConnectivityService: monitor network continuously
   SyncService:
   a. Collect all cosecha_local WHERE sync_status='pending'
   b. Collect all fertilizacion_local WHERE sync_status='pending'
   c. POST batches to /cosecha/sync and /fertilizacion/sync
   d. On 200: UPDATE sync_status='synced', fetch fresh gamification data
   e. On fail: keep pending, retry next connection
   WorkManager: background sync every 15 minutes
   Post-sync: call GET /gamificacion/:cod/hoy → update local display

7. SEED SERVICE (first install or manual refresh):
   If online: download lotes, trabajadores, tarifas, incentivos
   Store in local SQLite for offline operation

## Design constraints:
- Large buttons, minimum 48dp touch targets
- High contrast: dark green (#1B4332) primary, amber (#F59E0B) accent
- All text Spanish — zero English in UI
- Earnings always formatted: $ 47.500 (Colombian peso format)
- Offline = full functionality, no blocking spinners
- Budget Android devices: smooth on 4GB RAM, Android 8.0+
- App must work for workers who are not tech-savvy

## Output files:
/android_app/lib/main.dart
/android_app/lib/screens/ (one per screen)
/android_app/lib/services/sync_service.dart
/android_app/lib/services/connectivity_service.dart
/android_app/lib/services/seed_service.dart
/android_app/lib/services/gamification_service.dart
/android_app/lib/db/local_database.dart
/android_app/lib/models/ (one per entity)
/android_app/pubspec.yaml
/android_app/README.md

## Stop Condition
Stop after flutter pub get runs without errors and the app
launches on Android emulator showing the Login screen.
Show me the Login screen before proceeding to next screen.
```

---

## Phase 3 — Web Dashboard

### Claude Code Prompt — Phase 3:

```
## Role
You are a senior frontend engineer building an operations dashboard
for the management team at Hacienda La Ilusión, an African palm operation in Colombia.

## Task
1. Initialize React + Vite + Tailwind CSS
2. Install: recharts, axios, date-fns, react-router-dom,
   @tanstack/react-table, file-saver, papaparse

3. PAGES:

   PAGE 1 — Dashboard Principal (/)
   KPI row (top):
   - Racimos hoy | Kg hoy | Trabajadores activos | Pagos pendientes (COP)
   Charts:
   - Bar chart: Producción por zona (last 7 days)
   - Line chart: Racimos diarios (last 30 days)
   - Bar chart: Top 7 cosechadores esta semana (racimos)
   Table: Producción por lote hoy (lote, zona, racimos, kg, trabajadores)

   PAGE 2 — Cosechas (/cosechas)
   - Filterable table: trabajador, lote, zona, tipo_cosecha, fecha range
   - Columns: fecha_corte, ticket_extractora, cosechero, lote, zona,
     tipo_cosecha, total_racimos, peso_extractora_sin_recolector, sync_status
   - Color: pending=yellow, synced=green
   - Export to CSV (Libra format) button — calls /liquidacion/export/csv

   PAGE 3 — Trabajadores (/trabajadores)
   - List with role badge and zona badge
   - Click → worker profile: harvest history, earnings to date, attendance record
   - Edit: update tariff zone, role, PIN reset, activate/deactivate

   PAGE 4 — Liquidaciones (/liquidaciones)
   - Select worker + quincena → preview full payment calculation
   - Itemized: cosecha COP + fertilización COP + bonos COP - deducciones = total
   - Approve / reject
   - Mark as paid with date
   - Batch export: all approved liquidaciones for a period → CSV for accounting

   PAGE 5 — Incentivos (/incentivos)
   - View and manage milestone incentive plans
   - Create new: tipo (dias/racimos), umbral, monto_bono
   - Activate / deactivate
   - Preview: how many current workers would qualify based on last quincena

   PAGE 6 — Configuración (/configuracion)
   - Manage lotes: add/edit, update peso_promedio_kg per lote
   - Manage tarifas: set new rate per tipo_labor + zona, see history
   - System: export Libra CSV for any date range

4. AUTH:
   - Login: cedula + password for admin/supervisor
   - JWT in localStorage
   - Protected routes
   - Role display in navbar

5. DESIGN:
   - Color palette: deep green (#1B4332) primary, amber (#D4A017) accent
   - Bold KPI numbers, clean card layout
   - Spanish language throughout
   - Colombian date format: DD/MM/YYYY
   - Colombian currency: $ 1.250.000
   - Mobile-responsive (manager checks on phone)
   - 60-second polling on dashboard KPIs

## Output files:
/dashboard/src/pages/ (one per page)
/dashboard/src/components/ (KPICard, DataTable, ChartCard, WorkerProfile)
/dashboard/src/services/api.js
/dashboard/src/context/AuthContext.jsx
/dashboard/.env.example
/dashboard/README.md

## Stop Condition
Stop after npm run dev launches and Dashboard Principal loads
with KPI cards visible (can use mock data for now).
Show me the dashboard before building additional pages.
```

---

## Phase 4 — Integration & Deployment

### Claude Code Prompt — Phase 4:

```
## Role
Senior DevOps engineer finalizing deployment for Hacienda La Ilusión's
three-tier agricultural management system.

## Task
1. docker-compose.yml:
   - postgres:15, backend (port 3000), dashboard (port 5173)
   - Internal network 'palm-network'
   - Volumes for postgres data persistence

2. Dockerfiles for /backend and /dashboard

3. Integration test script (test_integration.sh):
   - Login as admin → get JWT
   - Create test worker (cosechador, zona 2)
   - POST single cosecha record
   - POST batch of 5 cosecha records (simulate Android sync)
   - POST batch of 2 fertilizacion records
   - GET /dashboard/kpis → verify records appear
   - GET /gamificacion/:cod/hoy → verify earnings calculation
   - POST /liquidacion/calcular → verify payment engine
   - GET /liquidacion/export/csv → verify Libra column format
   - Print PASSED/FAILED per step

4. Railway deployment guide (DEPLOYMENT.md):
   - PostgreSQL on Railway
   - Backend on Railway
   - Dashboard on Vercel
   - Android APK: how to build release APK and distribute via WhatsApp
   - Environment variables for each service

5. Generate CLAUDE.md for future sessions (content below)

## CLAUDE.md content:
---
# Hacienda La Ilusión — Sistema de Gestión Palma Africana

## Business Context
Agricultural management system for an African palm operation in Colombia.
Core problem: worker retention through earnings transparency and gamification.
Workers didn't know earnings until bi-weekly payday — causing personnel
shortages and reduced harvest output.

## Architecture
- Android App: Flutter · SQLite offline · WorkManager sync · APK via WhatsApp
- Backend: Node.js + Express · PostgreSQL · Railway hosting
- Dashboard: React + Vite + Tailwind · Vercel hosting

## Worker Roles
- cosechador: cuts + picks + loads wagon (corte, recolección, cargue)
- recolector: picking only (cannot cut)
- fertilizador: separate team, logs palms fertilized × dosage
- supervisor/mayordomo: records absences, views team summary
- admin: full dashboard access

## Payment Engine
RECOLECTOR_DE_RACIMOS:
  pago = peso_extractora_sin_recolector × tarifa(zona)
        + peso_extractora_recolector × tarifa(zona)

MECANIZADA:
  pago = peso_extractora_sin_recolector × tarifa(zona)

FERTILIZACION:
  pago = palmas_fertilizadas × dosis_por_palma × tarifa(zona)

BONOS: milestone-based (dias_trabajados thresholds — not racimo thresholds)
DEDUCCIONES: dias_ausencia_injustificada × valor_dia_base

## Libra ERP Integration
Export CSV must match exactly:
FECHA CREACION, TICKET EXTRACTORA, COD COSECHERO, COSECHERO,
COD LOTE, LOTE, ZONA, TIPO COSECHA, METODO_RECOLECCION,
TOTAL RACIMOS, PESO EXTRACTORA SIN RECOLECTOR

Colombian format: DD/MM/YYYY dates, period thousands, comma decimal

## Worker Identity
Primary: cod_cosechero (e.g., HLI050, TT639) — matches Libra
Secondary: cedula

## Gamification Design
- Leaderboard: top 7 only by racimos this week
- Workers outside top 7 see only their own rank + racimos (not others)
- Milestones: days_worked thresholds trigger bonos
- Home screen hero: today's earnings in large COP format
- Post-record confirmation always shows estimated earnings update

## Key API Endpoints
POST /auth/login
POST /cosecha/sync          ← offline batch upload (most critical)
POST /fertilizacion/sync    ← offline batch upload
GET  /gamificacion/:cod/hoy ← powers worker home screen
POST /liquidacion/calcular  ← bi-weekly payment engine
GET  /liquidacion/export/csv ← Libra ERP export

## Sync Protocol
Device generates UUID → saves locally with sync_status='pending'
On connectivity: batch POST to /cosecha/sync or /fertilizacion/sync
Server deduplicates by UUID — idempotent, never errors on duplicates
Device updates sync_status='synced' on 200 response
Pending records survive: app crash, reboot, battery death

## Environment Variables
Backend: DATABASE_URL, JWT_SECRET, PORT=3000, NODE_ENV
Dashboard: VITE_API_URL
Android: lib/config/api_config.dart → const String apiBaseUrl

## Critical Rules
- Offline-first: app works 100% with zero internet
- UUID on device: never wait for server to generate cosecha_id
- Idempotent sync: duplicate UUID = silent ignore, never error
- Never delete pending records
- Spanish only in all UIs
- COP format: $ 1.250.000 everywhere
- Tariff rates come from admin-configured tarifa table — never hardcoded
- Payment matrix (detailed rates per zona/tipo) to be loaded via admin UI
  or seed script once provided by operations team
---

## Stop Condition
Stop after docker-compose up starts all three services without errors
and the integration test script passes all steps.
Print final test results summary.
```

---

## KPI Framework

### Operational (daily):

| KPI | Formula |
|---|---|
| Racimos hoy | SUM(total_racimos) WHERE fecha_corte = today |
| Kg hoy | SUM(peso_extractora_sin_recolector) WHERE fecha_corte = today |
| Trabajadores activos | COUNT DISTINCT trabajador WHERE fecha_corte = today |
| Registros pendientes sync | COUNT WHERE sync_status = 'pending' |

### Financial (bi-weekly):

| KPI | Formula |
|---|---|
| Costo por kg | total_liquidado / total_kg |
| Pagos pendientes aprobación | SUM(total_pagar) WHERE estado='pendiente' |
| Bonos otorgados período | SUM(monto_bonos) WHERE periodo |

### By zone:

| KPI | Description |
|---|---|
| Producción por zona | Racimos + kg grouped by zona |
| Top 7 cosechadores | By total racimos this week |

---

## Colombian Palm Industry Context

### Key terminology:

| Term | Definition |
|---|---|
| RFF | Racimo de Fruta Fresca — the fresh fruit bunch being harvested |
| CPO | Crude Palm Oil — what RFF becomes after processing |
| Cosechador | Worker who cuts and loads fruit bunches |
| Recolector | Worker who picks loose fruit from ground (cannot cut) |
| Fertilizador | Worker who applies fertilizer — separate team |
| Mayordomo | Field supervisor |
| Lote | Production block within the plantation |
| Zona | Group of lotes (1–4) — determines tariff and team assignment |
| Destajo | Payment per unit produced (all workers in this system) |
| Quincena | Bi-weekly pay period |
| Extractora | Palm oil extraction plant — authoritative weight source |
| Ticket Extractora | Transport ticket number — Libra's primary harvest reference |

### Tariff structure (configurable in admin panel):
- `cosecha_recolector`: COP per kg of `peso_extractora_sin_recolector`
- `cosecha_mecanizada`: COP per kg of `peso_extractora_sin_recolector`
- `fertilizacion`: COP per unit of `total_aplicado` (palmas × dosis)
- All rates vary by zona and are set via admin dashboard
- Detailed payment matrix to be provided by operations team and loaded via seed/admin UI

---

## General Constraints — Apply Across All Phases

- **Offline-first is #1 priority** — Android app must work with zero internet for core functions
- **UUID everywhere** — generated on device for cosecha and fertilizacion, never on server
- **Idempotent sync** — duplicate records never cause errors or duplicates
- **Spanish UI only** — every label, button, error message in Spanish
- **Colombian formats** — `$ 1.250.000` currency, `DD/MM/YYYY` dates throughout
- **Libra compatibility** — CSV export must match exactly, no manual reformatting
- **Zero maintenance hosting** — Railway + Vercel, no DevOps expertise required
- **Budget devices** — smooth on Android 8.0+, 4GB RAM
- **Data safety** — pending records survive app crash, reboot, battery death
- **Role-aware UI** — each role sees only their relevant screens and data
- **Tariff rates configurable** — never hardcoded, always from tarifa table
- **APK distribution via WhatsApp** — no Play Store, no $25 fee, updates in minutes

---

## Execution Order

```
Step 1: Read this entire document
Step 2: Create CLAUDE.md in project root
Step 3: Execute Phase 1 (Backend) — verify API runs on Railway
Step 4: Execute Phase 2 (Flutter App) — verify offline recording + earnings display
Step 5: Execute Phase 3 (Dashboard) — verify KPIs + Libra export
Step 6: Execute Phase 4 (Integration) — verify end-to-end sync
Step 7: Run integration test — all steps must pass
```

---

## Stop Condition — Full System Complete

The system is complete when:
- [ ] A cosechador records a cosecha on Android with no internet
- [ ] App immediately shows updated estimated earnings for the day
- [ ] Phone gets signal → background sync fires automatically
- [ ] Record appears in web dashboard within 60 seconds
- [ ] Leaderboard updates with worker's new racimo count
- [ ] Manager generates bi-weekly liquidación with full itemized breakdown
- [ ] Manager exports Libra-format CSV — finance team imports without changes
- [ ] Worker sees their bono progress milestone updating toward next threshold
