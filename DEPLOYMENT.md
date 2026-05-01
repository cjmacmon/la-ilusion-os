# Deployment Guide — Hacienda La Ilusión

## Option A: Docker Compose (local / VPS)

```bash
# Start all services
docker-compose up -d

# Load schema + seed (first run only — handled by Docker entrypoint)
# Verify
docker-compose logs backend | grep "Server running"

# Run integration tests
./test_integration.sh

# Stop
docker-compose down
```

## Option B: Railway (recommended for zero-maintenance)

### 1. PostgreSQL on Railway

1. Create new project → Add PostgreSQL
2. Copy `DATABASE_URL` from Railway dashboard

### 2. Backend on Railway

1. New service → Deploy from GitHub (or upload /backend folder)
2. Set environment variables:
   ```
   DATABASE_URL=<from Railway Postgres>
   JWT_SECRET=<generate: openssl rand -hex 32>
   PORT=3000
   NODE_ENV=production
   ```
3. After first deploy, run schema + seed:
   ```bash
   # In Railway console or via psql:
   psql $DATABASE_URL -f backend/db/schema.sql
   psql $DATABASE_URL -f backend/db/seed.sql
   ```
4. Note your backend URL: `https://your-project.railway.app`

### 3. Dashboard on Vercel

1. `cd dashboard && npm run build`
2. Deploy `dist/` to Vercel or: `vercel --prod`
3. Set environment variable in Vercel:
   ```
   VITE_API_URL=https://your-project.railway.app
   ```

**Important**: Dashboard uses Vite env vars at build time.  
Rebuild after changing `VITE_API_URL`.

## Android APK Distribution

### Build release APK

```bash
cd android_app

# Update API URL first:
# Edit lib/config/api_config.dart:
# static const String apiBaseUrl = 'https://your-project.railway.app';

flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Distribute via WhatsApp

1. Send APK file via WhatsApp to workers or supervisor
2. Worker enables "Install unknown apps" in Android settings
3. Opens APK → installs → opens app
4. First launch: needs WiFi to seed lote/tarifa data
5. After seed: works fully offline

### Update distribution

Build new APK → send via WhatsApp → workers install over old version (data preserved).

## Admin Password Setup

The seed data creates an admin user (`ADMIN01`) but with a placeholder bcrypt hash.  
Set a real password:

```bash
# Generate hash (Node.js)
node -e "const b=require('bcrypt'); b.hash('your-password',10).then(console.log)"

# Update in database
psql $DATABASE_URL -c "UPDATE trabajador SET password_hash='<hash>' WHERE cod_cosechero='ADMIN01';"
```

## Environment Variables Summary

| Service | Variable | Description |
|---------|----------|-------------|
| Backend | `DATABASE_URL` | PostgreSQL connection string |
| Backend | `JWT_SECRET` | Secret for JWT signing (min 32 chars) |
| Backend | `PORT` | Default: 3000 |
| Backend | `NODE_ENV` | `production` or `development` |
| Dashboard | `VITE_API_URL` | Backend URL (build-time) |
| Android | `apiBaseUrl` in `api_config.dart` | Backend URL (build-time) |
