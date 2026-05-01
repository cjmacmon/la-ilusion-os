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

## Project Structure
```
/backend          Node.js + Express + PostgreSQL API
/android_app      Flutter offline-first Android app
/dashboard        React + Vite + Tailwind web dashboard
CLAUDE.md         This file
```
