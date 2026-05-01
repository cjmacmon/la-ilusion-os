# Dashboard — Hacienda La Ilusión

React + Vite + Tailwind CSS web dashboard for operations managers and finance.

## Setup

```bash
npm install
cp .env.example .env
# Edit VITE_API_URL to point to your backend
npm run dev
```

Dashboard runs on http://localhost:5173

## Login

- Use cédula + password (admin or supervisor roles only)
- Field workers use the Android app, not the dashboard

## Pages

| Route | Description |
|-------|-------------|
| `/` | Dashboard principal — KPIs, charts, production table |
| `/cosechas` | Harvest records — filterable, exportable to Libra CSV |
| `/trabajadores` | Worker list — profiles, edit zone/role/status |
| `/liquidaciones` | Bi-weekly payment calculator + approval flow |
| `/incentivos` | Manage milestone incentive plans |
| `/configuracion` | Manage lotes, tarifas, Libra export |

## Deployment (Vercel)

```bash
npm run build
# Deploy dist/ to Vercel
# Set VITE_API_URL env var in Vercel dashboard
```
