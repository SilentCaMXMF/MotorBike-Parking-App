# Frontend Deployment Guide - Motorbike Parking App

**Project:** Motorbike Parking App (Flutter Web)
**Frontend URL:** https://motorbike-web.vercel.app
**Backend URL:** https://homelab-backendpi.pedroocalado.eu
**Date:** March 11, 2026
**Version:** 2.1 - Local Build Deployment

---

## Deployment Method

**Important:** Vercel is used as **static hosting only**. Flutter is built locally and the `build/web` folder is deployed. This is because:
- Vercel's build environment doesn't have Flutter installed
- Local builds ensure consistent environment
- Faster deployments (no build step on Vercel)

### Deployment Workflow

```bash
# 1. Build locally
flutter build web --release

# 2. Deploy to Vercel
cd build/web
vercel deploy --prod --yes
```

```
┌──────────────────────────────────────────────────────────────┐
│                    🌐 INTERNET                                │
│                                                             │
│  ┌──────────────────────┐    ┌──────────────────────┐      │
│  │  Flutter Web App     │    │  Backend API         │      │
│  │                      │    │                      │      │
│  │  Mobile/Web          │    │  https://               │      │
│  │  Shared Codebase     │    │  homelab-backendpi     │      │
│  │                      │    │  .pedroocalado.eu      │      │
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

**Important:** The app uses platform-specific configuration:
- **Mobile (.env file)**: Uses environment variables from .env file
- **Web (Vercel)**: Uses hardcoded values matching Vercel environment

#### For Mobile Development

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

#### For Web Deployment

The web app uses hardcoded values in `lib/config/environment.dart` that match Vercel environment variables:

```dart
static Map<String, String?> _loadWebEnv() {
  // On web, use hardcoded fallback values (same as Vercel env vars)
  return {
    'DEV_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
    'PROD_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
    'ENVIRONMENT': 'development',
    'GOOGLE_MAPS_API_KEY': 'AIzaSyCj7NygIqVX9qpdYhtmiksowqfjOHyHshQ',
    'API_TIMEOUT': '30000',
  };
}
```

**Production API Key (already configured):** `AIzaSyCj7NygIqVX9qpdYhtmiksowqfjOHyHshQ`

**Important:** Never commit `.env` file to git!

### Step 3: Verify Environment Configuration

The configuration is handled automatically in `lib/config/environment.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum EnvironmentType {
  development,
  staging,
  production,
}

class Environment {
  static EnvironmentType _currentEnvironment = EnvironmentType.development;

  static Map<String, String?> get _env {
    if (kIsWeb) {
      return _loadWebEnv(); // Web uses hardcoded values
    }
    return dotenv.env; // Mobile uses .env file
  }

  static String get apiBaseUrl {
    final env = _env;
    switch (_currentEnvironment) {
      case EnvironmentType.development:
        return env['DEV_API_BASE_URL'] ??
            'https://homelab-backendpi.pedroocalado.eu';
      case EnvironmentType.staging:
        return env['STAGING_API_BASE_URL'] ?? 'http://staging.example.com';
      case EnvironmentType.production:
        return env['PROD_API_BASE_URL'] ??
            'https://homelab-backendpi.pedroocalado.eu';
    }
  }

  static int get apiTimeout {
    final env = _env;
    return int.tryParse(env['API_TIMEOUT'] ?? '30000') ?? 30000;
  }

  static String get googleMapsApiKey {
    final env = _env;
    return env['GOOGLE_MAPS_API_KEY'] ??
        'AIzaSyCj7NygIqVX9qpdYhtmiksowqfjOHyHshQ';
  }

  static EnvironmentType get currentEnvironment => _currentEnvironment;

  static void setEnvironment(EnvironmentType env) {
    _currentEnvironment = env;
  }

  static Future<void> initialize() async {
    if (!kIsWeb) {
      await dotenv.load(fileName: '.env');
    }

    String envString;
    if (kIsWeb) {
      envString = _env['ENVIRONMENT'] ?? 'development';
    } else {
      envString = dotenv.env['ENVIRONMENT'] ?? 'development';
    }

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

### Test Web App with Hardcoded Configuration

The web app now uses hardcoded environment variables matching Vercel deployment:

```dart
// In environment.dart, web uses:
'GOOGLE_MAPS_API_KEY': 'AIzaSyCj7NygIqVX9qpdYhtmiksowqfjOHyHshQ',
'API_TIMEOUT': '30000',
'DEV_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
'PROD_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
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

**Vercel Configuration:**
The app includes `vercel.json` for security and caching headers:

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "outputDirectory": "build/web",
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        }
      ]
    },
    {
      "source": "/flutter_service_worker.js",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "no-cache, no-store, must-revalidate"
        }
      ]
    },
    {
      "source": "/index.html",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "no-cache, no-store, must-revalidate"
        }
      ]
    }
  ]
}
```

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

**Enhanced Features:**
- Better error handling with user-friendly messages
- Token expiration handling (401 Unauthorized)
- Enhanced logging with LoggerService
- Improved response parsing
- Web-compatible file upload support

### Environment Configuration

**File:** `lib/config/environment.dart`

**Key Changes:**
- Platform detection with `kIsWeb`
- Web uses hardcoded fallback values (no .env file needed)
- Backend URL hardcoded as `https://homelab-backendpi.pedroocalado.eu` for web
- Google Maps API key included: `AIzaSyCj7NygIqVX9qpdYhtmiksowqfjOHyHshQ`

### Vercel Configuration

**File:** `vercel.json`

Security headers configured:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`

Caching control:
- Flutter service worker: no cache
- index.html: no cache
- Other files: Vercel managed

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
1. **Web App:** API key is hardcoded in environment.dart: `AIzaSyCj7NygIqVX9qpdYhtmiksowqfjOHyHshQ`
2. **Mobile App:** Verify API key is in `.env`: `GOOGLE_MAPS_API_KEY=...`
3. Check API key has Maps JavaScript API enabled
4. Verify API key has billing enabled (or is free tier)
5. Check browser console for API errors
6. Test API key: `curl "https://maps.googleapis.com/maps/api/js?key=YOUR_KEY"`

**Important:** Web app automatically uses production API key without needing .env file.

### Web Platform Issues

**Problem:** App doesn't work on web platform

**Solutions:**
1. Verify platform detection is working: check `kIsWeb` in code
2. Ensure `dart:io` is not imported in files used by web
3. Use conditional imports: `import 'dart:io' if (dart.library.html) 'dart:html'`
4. Test on web first before deploying: `flutter build web --release`
5. Check browser console for Dart compilation errors

**Common Web Issues:**
- File uploads need bytes instead of File objects
- Notifications not supported on web
- FlutterSecureStorage has limited web support
- Location services require browser permissions

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

**For Mobile App:**
1. Change `.env` file: `PROD_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu`
2. Commit and push to GitHub
3. Vercel auto-deploys
4. Wait 1-2 minutes for deployment

**For Web App:**
1. Edit `lib/config/environment.dart`
2. Update hardcoded values in `_loadWebEnv()`:
   ```dart
   'DEV_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
   'PROD_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
   ```
3. Commit and push to GitHub
4. Vercel auto-deploys
5. Wait 1-2 minutes for deployment

**Note:** Web app uses hardcoded values, no .env file needed.

### Versioning

- **Frontend Version:** Flutter Web App (Vercel)
- **Backend Version:** Node.js API (Cloudflare Tunnel)
- **Database Version:** MariaDB 10.11.14

---

## Web Platform Features & Limitations

### Supported Features
- ✅ User authentication (login/register)
- ✅ Parking zone browsing
- ✅ Report submission
- ✅ Image uploads
- ✅ Google Maps integration
- ✅ Responsive design
- ✅ Basic offline support (Flutter service worker)

### Limited Features (Web Only)
- ⚠️ Notifications (not supported in browsers)
- ⚠️ Deep linking (limited)
- ⚠️ Some file operations (requires special handling)
- ⚠️ Camera access (requires permissions)

### Recommended Web Browsers
- Chrome 80+
- Firefox 75+
- Safari 13+
- Edge 80+

---

## Production Checklist

### Before Deploying to Vercel:

- [ ] **Backend URL:** Verify Cloudflare tunnel is running
- [ ] **API Key:** Confirm Google Maps API key is correct
- [ ] **Environment:** Test on web before deployment
- [ ] **Error Handling:** Verify user-friendly error messages
- [ ] **File Uploads:** Test image uploads on web platform
- [ ] **Maps:** Confirm Google Maps loads correctly
- [ ] **CORS:** Verify backend allows web origin
- [ ] **Security:** Check Vercel headers in vercel.json
- [ ] **Performance:** Test loading speed (Lighthouse score > 90)
- [ ] **Mobile:** Test responsive design on mobile browsers

---

## References

- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Vercel Documentation](https://vercel.com/docs)
- [Environment Configuration](https://pub.dev/packages/flutter_dotenv)

---

**Last Updated:** March 11, 2026
**Version:** 2.0 - Web Support Added
**Status:** ✅ Production Active
**Frontend:** https://web-smoky-chi-34.vercel.app
**Backend:** https://homelab-backendpi.pedroocalado.eu

**Key Changes in Version 2.0:**
- ✅ Web platform support added
- ✅ Shared codebase for mobile and web
- ✅ Google Maps API key integrated
- ✅ Enhanced error handling in API service
- ✅ Vercel configuration with security headers
- ✅ Platform-specific environment configuration
