# Frontend Deployment Guide - Motorbike Parking App

**Project:** Motorbike Parking App (Flutter Web)
**Frontend URL:** https://web-smoky-chi-34.vercel.app
**Backend URL:** https://homelab-backendpi.pedroocalado.eu
**Date:** March 10, 2026

---

## Overview

This guide documents the frontend deployment strategy, connecting the Flutter web app to the Cloudflare-tunneled backend API.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    🌐 INTERNET                                │
│                                                             │
│  ┌──────────────────────┐    ┌──────────────────────┐      │
│  │  Flutter Web App     │    │  Backend API         │      │
│  │                      │    │                      │      │
│  │  https://              │    │  https://               │      │
│  │  web-smoky-chi-34     │    │  homelab-backendpi     │      │
│  │  .vercel.app          │    │  .pedroocalado.eu      │      │
│  └──────────┬───────────┘    └──────────┬───────────┘      │
│             │                            │                   │
│             └────────────┬───────────────┘                   │
│                          │                                   │
│                          ▼                                   │
│                 ┌────────────────────┐                       │
│                 │  Flutter API Client │                       │
│                 │  (lib/services/)    │                       │
│                 └──────────┬─────────┘                       │
│                            │                                 │
│                            ▼                                 │
│                 ┌────────────────────┐                       │
│                 │  Environment Config │                       │
│                 │  (environment.dart) │                       │
│                 └────────────────────┘                       │
└──────────────────────────────────────────────────────────────┘
```

---

## Environment Setup

### Step 1: Clone the Repository

```bash
cd ~/motorbike_app
git pull origin main
```

### Step 2: Configure Environment Variables

Edit `.env` file in the motorbike_app root:

```env
# API Configuration
DEV_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu
PROD_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu

# API Timeout (milliseconds)
API_TIMEOUT=30000

# Google Maps API Key
GOOGLE_MAPS_API_KEY=your_google_maps_key_here
```

**Important:** Never commit `.env` file to git!

### Step 3: Verify Environment Configuration

Edit `lib/config/environment.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum EnvironmentType {
  development,
  staging,
  production,
}

class Environment {
  static EnvironmentType _currentEnvironment = EnvironmentType.development;

  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case EnvironmentType.development:
        return dotenv.env['DEV_API_BASE_URL'] ?? 'http://localhost:3000';
      case EnvironmentType.staging:
        return dotenv.env['STAGING_API_BASE_URL'] ?? 'http://staging.example.com';
      case EnvironmentType.production:
        return dotenv.env['PROD_API_BASE_URL'] ?? 'http://192.168.1.67:3000';
    }
  }

  static int get apiTimeout {
    return int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');
  }

  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  static EnvironmentType get currentEnvironment => _currentEnvironment;

  static void setEnvironment(EnvironmentType env) {
    _currentEnvironment = env;
  }

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final envString = dotenv.env['ENVIRONMENT'] ?? 'development';
    switch (envString.toLowerCase()) {
      case 'production':
        _currentEnvironment = EnvironmentType.production;
        break;
      case 'staging':
        _currentEnvironment = EnvironmentType.staging;
        break;
      default:
        _currentEnvironment = EnvironmentType.development;
    }
  }
}
```

---

## Development

### Local Development

1. **Install dependencies:**
   ```bash
   cd ~/motorbike_app
   flutter pub get
   ```

2. **Configure local backend:**
   ```env
   DEV_API_BASE_URL=http://localhost:3000
   ```

3. **Run the app:**
   ```bash
   flutter run -d chrome
   ```

### Test API Connection

```bash
# Test local backend
curl http://localhost:3000/health

# Test tunnel backend
curl https://homelab-backendpi.pedroocalado.eu/health

# Test API endpoints
curl https://homelab-backendpi.pedroocalado.eu/api/users
```

---

## Production Build

### Step 1: Build Web App

```bash
cd ~/motorbike_app
flutter clean
flutter pub get
flutter build web --release
```

Output location: `build/web/`

### Step 2: Deploy to Vercel

**Option A: Using Vercel CLI**
```bash
cd ~/motorbike_app/build/web
vercel --prod
```

**Option B: Using GitHub Integration**
1. Push to GitHub: `git push origin main`
2. Go to [Vercel Dashboard](https://vercel.com/new)
3. Import GitHub repository
4. Set build command: `flutter build web`
5. Set output directory: `web`
6. Deploy

### Step 3: Verify Deployment

Visit: https://web-smoky-chi-34.vercel.app

Test endpoints:
- ✅ Home page loads
- ✅ Authentication works (login/register)
- ✅ API calls succeed
- ✅ Maps load correctly
- ✅ File uploads work

---

## Configuration Reference

### API Service Configuration

**File:** `lib/services/api_service.dart`

Key configurations:
```dart
// Base URL from environment
String baseUrl = Environment.apiBaseUrl;

// Timeout from environment
int timeout = Environment.apiTimeout;

// Headers
Map<String, String> getHeaders() {
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
```

### Database Configuration

**File:** `lib/services/sql_service.dart`

```dart
String getDatabaseUrl() {
  return 'mysql://$user:$password@$host:$port/$database';
}
```

---

## CORS Configuration

### Backend CORS Settings

**File:** `backend/src/server.js`

```javascript
const corsOptions = {
  origin: [
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:4200',
    'https://web-smoky-chi-34.vercel.app',
    'https://homelab-backendpi.pedroocalado.eu',
  ],
  credentials: false, // Changed from true for web compatibility
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};
```

---

## Troubleshooting

### API Connection Errors

**Problem:** `Connection refused` or `Network not available`

**Solutions:**
1. Verify backend is running: `pm2 status`
2. Test backend URL: `curl https://homelab-backendpi.pedroocalado.eu/health`
3. Check backend logs: `pm2 logs motorbike-api`
4. Verify Cloudflare tunnel is running (see Backend Deployment Guide)

### CORS Errors

**Problem:** `Access to fetch at '...' from origin '...' has been blocked by CORS policy`

**Solutions:**
1. Verify origin is in backend CORS whitelist
2. Check backend server.js for correct origin configuration
3. Ensure credentials: false (not true) for web apps
4. Restart backend after changing CORS: `pm2 restart motorbike-api`

### Authentication Issues

**Problem:** `Unauthorized` or authentication fails

**Solutions:**
1. Check JWT secret matches between frontend and backend
2. Verify token expiration time is appropriate (7d configured)
3. Test login manually: `curl -X POST https://homelab-backendpi.pedroocalado.eu/api/auth/login`
4. Check backend logs for authentication errors

### Maps Not Loading

**Problem:** Google Maps doesn't display

**Solutions:**
1. Verify API key is in `.env`: `GOOGLE_MAPS_API_KEY=...`
2. Check API key has Maps JavaScript API enabled
3. Verify API key has billing enabled (or is free tier)
4. Check browser console for API errors
5. Test API key: `curl "https://maps.googleapis.com/maps/api/js?key=YOUR_KEY"`

---

## Performance Optimization

### Flutter Web Build Tips

1. **Optimize images:**
   ```bash
   flutter clean
   flutter pub get
   flutter build web --release --tree-shake-icons
   ```

2. **Enable compression:** Vercel handles this automatically

3. **Service Worker:** Vercel includes PWA service worker for offline caching

4. **Code Splitting:** Flutter automatically code splits for Flutter Web

### Analytics

Add Vercel Analytics:

1. Install: `flutter pub add vercel_analytics`
2. Initialize in main.dart:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Environment.initialize();

     // Initialize Vercel Analytics
     if (kReleaseMode) {
       VercelAnalytics.init(
         scriptURL: 'https://vercel.com/web-smoky-chi-34/vercel-analytics/script.js',
       );
     }

     runApp(MyApp());
   }
   ```

---

## Testing Checklist

Before production deployment:

- [ ] All API endpoints respond successfully
- [ ] Authentication (login/register) works
- [ ] User profile CRUD operations work
- [ ] Parking zone browsing and search works
- [ ] Report submission and viewing works
- [ ] Image uploads work (including preview)
- [ ] Google Maps displays correctly
- [ ] Responsive design works on mobile/tablet
- [ ] Offline mode doesn't break critical features
- [ ] Error handling shows user-friendly messages
- [ ] No console errors or warnings
- [ ] Performance is acceptable (Lighthouse score > 90)

---

## Updates & Maintenance

### Updating Frontend

1. Make changes in Flutter code
2. Test locally: `flutter run`
3. Build web: `flutter build web --release`
4. Deploy to Vercel: `vercel --prod`

### Updating Backend URL

1. Change `.env` file: `PROD_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu`
2. Commit and push to GitHub
3. Vercel auto-deploys
4. Wait 1-2 minutes for deployment

### Versioning

- **Frontend Version:** Flutter Web App (Vercel)
- **Backend Version:** Node.js API (Cloudflare Tunnel)
- **Database Version:** MariaDB 10.11.14

---

## References

- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Vercel Documentation](https://vercel.com/docs)
- [Environment Configuration](https://pub.dev/packages/flutter_dotenv)

---

**Last Updated:** March 10, 2026
**Status:** ✅ Production Active
**Frontend:** https://web-smoky-chi-34.vercel.app
**Backend:** https://homelab-backendpi.pedroocalado.eu
