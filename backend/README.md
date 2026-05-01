# Backend — Hacienda La Ilusión

Node.js + Express + PostgreSQL REST API.

## Setup

```bash
npm install
cp .env.example .env
# Edit .env with your DATABASE_URL and JWT_SECRET
```

## Database

```bash
psql $DATABASE_URL -f db/schema.sql
psql $DATABASE_URL -f db/seed.sql
```

## Run

```bash
node server.js        # production
npm run dev           # development (nodemon)
```

Server starts on port 3000 (or $PORT).

## Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /auth/login | — | Login (PIN or password) |
| GET | /trabajadores | JWT | List workers |
| POST | /trabajadores | admin | Create worker |
| PUT | /trabajadores/:id | admin/supervisor | Update worker |
| GET | /trabajadores/:id/resumen | JWT | Worker earnings summary |
| GET | /lotes | JWT | List lotes |
| POST | /lotes | admin | Create lote |
| PUT | /lotes/:id | admin | Update lote |
| GET | /cosecha | JWT | List harvest records |
| POST | /cosecha | JWT | Single harvest record |
| POST | /cosecha/sync | JWT | **Batch sync from Android** |
| GET | /fertilizacion | JWT | List fertilization records |
| POST | /fertilizacion/sync | JWT | **Batch sync from Android** |
| GET | /ausencias | supervisor/admin | List absences |
| POST | /ausencias | supervisor/admin | Record absence |
| GET | /tarifas | JWT | Active rates |
| POST | /tarifas | admin | Create rate (deactivates old) |
| GET | /incentivos | JWT | Active incentive plans |
| POST | /incentivos | admin | Create incentive |
| PUT | /incentivos/:id | admin | Update incentive |
| POST | /liquidacion/calcular | admin/supervisor | Calculate payment (preview) |
| POST | /liquidacion | admin | Save liquidacion |
| GET | /liquidacion | admin/supervisor | List liquidaciones |
| PUT | /liquidacion/:id/estado | admin | Approve/mark paid |
| GET | /liquidacion/export/csv | admin/supervisor | **Libra ERP export** |
| GET | /dashboard/kpis | admin/supervisor | Dashboard KPIs |
| GET | /gamificacion/:cod/hoy | JWT | Worker gamification data |

## Sync Protocol

Android devices POST batches to `/cosecha/sync` or `/fertilizacion/sync`.
Server deduplicates by UUID — idempotent, never errors on duplicates.
Response: `{ synced: N, duplicates: N, errors: [] }`
