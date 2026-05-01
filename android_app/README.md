# Android App — Hacienda La Ilusión

Flutter offline-first app for field workers. Target: Android API 26+.

## Setup

```bash
flutter pub get
flutter run                    # run on emulator
flutter build apk --release   # build APK for WhatsApp distribution
```

## Architecture

- **Offline login**: cod_cosechero + 4-digit PIN against local SQLite
- **Local SQLite**: all records stored first, synced when online
- **WorkManager**: background sync every 15 minutes when connected
- **UUID on device**: cosecha_id generated on device, never on server

## First-time Setup

On first launch with network:
1. Login with cod_cosechero + PIN (must have seeded DB or be online)
2. App auto-downloads: lotes, tarifas, incentivos, trabajadores from backend
3. All subsequent actions work fully offline

## Config

Edit [lib/config/api_config.dart](lib/config/api_config.dart):
```dart
static const String apiBaseUrl = 'https://your-railway-url.railway.app';
```

## Screens

| Screen | Role |
|--------|------|
| Login | All |
| Inicio | All (role-aware content) |
| Registrar Cosecha | cosechador / recolector |
| Registrar Fertilización | fertilizador |
| Mis Ganancias | All |
| Leaderboard | All |
| Sincronización | All |

## APK Distribution

```bash
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
# Send via WhatsApp to workers
```
