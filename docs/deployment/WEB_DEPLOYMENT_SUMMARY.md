# Motorbike Parking App - Web Deployment Work Summary

**Date:** 2026-02-27  
**Author:** AI Assistant (OpenCode)

---

## Overview

This document summarizes the work done to deploy the Motorbike Parking App as a web application, making it accessible from Vercel while connecting to a Raspberry Pi backend via Cloudflare Tunnel.

---

## Live URLs

| Service | URL |
|---------|-----|
| Web App (Vercel) | https://motorbike-web.vercel.app |
| Backend API (Cloudflare) | https://homelab-backendpi.pedroocalado.eu |

---

## 1. Web Compatibility Fixes

### Problem
The app used `dart:io` which doesn't work on web platforms.

### Solution
- Removed `dart:io` imports from:
  - `api_service.dart`
  - `sql_service.dart`
  - `reporting_dialog.dart`
- Added `kIsWeb` platform detection with conditional code paths

### Files Modified
- `lib/services/api_service.dart`
- `lib/services/sql_service.dart`
- `lib/widgets/reporting_dialog.dart`

---

## 2. Google Maps API Integration

### Configuration
- Added `GOOGLE_MAPS_API_KEY` environment variable
- Injected API key into JavaScript via `main.dart`
- Updated `index.html` to load Maps API dynamically

### Files Modified
- `.env` - Added `GOOGLE_MAPS_API_KEY`
- `.env.example` - Added documentation
- `lib/config/environment.dart` - Added getter
- `lib/main.dart` - JS injection
- `web/index.html` - Dynamic script loading

---

## 3. Backend Integration Fixes

### CORS Issue
- Fixed: `credentials: true` with `origin: '*'` doesn't work in browsers
- Changed to: `credentials: false`

### Anonymous Login Response Parsing
- Backend returns: `{ token, user }`
- App expected: `{ data: { token, user } }`
- Fixed parsing in `api_service.dart`

### Files Modified
- `backend/src/server.js`
- `lib/services/api_service.dart`

---

## 4. Location Service Web Support

### Problem
Geolocator package needed special handling for web.

### Solution
- Added `_getWebLocation()` method with:
  - Better permission checking
  - Null safety for permission responses
  - Detailed logging

### Files Modified
- `lib/services/location_service.dart`

---

## 5. Firebase Services Stubbed

### Reason
Backend uses API-based authentication instead of Firebase.

### Services Stubbed
- `auth_service.dart` - Returns errors explaining Firebase is disabled
- `storage_service.dart` - Returns errors explaining Firebase is disabled

### To Re-enable
1. Add `firebase_auth` and `firebase_storage` to `pubspec.yaml`
2. Uncomment imports in `main.dart`
3. Re-enable service implementations

---

## 6. App Icons

### Custom Design
Created icons from provided SVG design:
- Blue background (#3B82F6)
- Motorbike silhouette with white wheels
- "P" badge in blue circle

### Generated Files
- `web/icons/Icon-192.png` (192x192)
- `web/icons/Icon-512.png` (512x512)
- `web/favicon.png` (32x32)

---

## 7. Infrastructure Setup

### Raspberry Pi (Backend)
- MariaDB 10.11.14 running
- Node.js Express API
- PM2 process manager
- Cloudflare Tunnel for public access

### Database Status
- Database: `motorbike_parking_app`
- Tables: users, parking_zones, parking_zone_availability, user_reports, recent_user_reports, report_images
- Users: 119
- Parking Zones: 58 (Lisbon area)

### Vercel (Frontend)
- Automatic deployment from GitHub
- Static web hosting

---

## 8. Known Issues / TODO

### Temporary URLs
- Cloudflare Tunnel creates new URLs on restart
- Need domain for permanent URL

### Web Location
- Browser geolocation may fail if permissions not granted
- User needs to allow location access

### Google Maps Warning
- Console shows warning about async loading
- Non-critical, app still works

---

## Commands Reference

### Backend (Raspberry Pi)
```bash
# Pull latest changes
cd ~/motorbike_app/backend
git pull origin main

# Restart backend
pm2 restart motorbike-api

# Check status
pm2 status
pm2 logs motorbike-api
```

### Frontend (Local Build Deployment)

Vercel is used as **static hosting only** - Flutter is built locally before deployment.

```bash
# Build web locally
flutter build web --release

# Deploy the build folder to Vercel
cd build/web
vercel deploy --prod --yes
```

### Environment Variables
```
DEV_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu
PROD_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu
GOOGLE_MAPS_API_KEY=<your-key>
```

---

## Git Commits

| Commit | Description |
|--------|-------------|
| f3b7c3b | Fix CORS: set credentials to false for web compatibility |
| 76edf3c | Add web support: platform detection, Google Maps API key, file upload fixes |
| 9796f15 | Fix web auth and location issues |

---

## Future Improvements

1. ~~Permanent Domain~~ - ✅ DONE: Using homelab-backendpi.pedroocalado.eu
2. **PWA Features** - Add service worker for offline support
3. **Better Error Handling** - Improve user-facing error messages
4. **Performance** - Address Google Maps async loading warning
