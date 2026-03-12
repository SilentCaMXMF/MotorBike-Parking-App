# AGENTS.md - Coding Guidelines for Motorbike Parking App

This file provides guidelines for AI agents working on this codebase.

---

## 1. Build/Lint/Test Commands

### Flutter Commands
```bash
# Build commands
flutter build apk --release          # Build Android APK
flutter build ios --release         # Build iOS (macOS only)
flutter build web --release         # Build Web app
flutter run --debug                 # Run in debug mode

# Code quality
flutter analyze                     # Run static analysis (lint)
flutter format .                    # Format all Dart files

# Testing
flutter test                        # Run all tests
flutter test test/path/to/file.dart # Run single test file
flutter test --plain-name "name"   # Run tests matching name
flutter test --reporter expanded   # Detailed test output
```

### Backend Commands
```bash
cd backend

# Development
npm run dev              # Run with nodemon
npm start               # Production start

# Testing
npm test                # Run all tests
npm test -- --testNamePattern="pattern"  # Run matching tests

# Linting
npm run lint            # Run ESLint
```

---

## 2. Project Structure

```
lib/
├── main.dart                  # App entry point
├── config/environment.dart    # Environment configuration
├── models/                   # Data models
├── screens/                  # UI screens (auth_screen, map_screen)
├── services/                 # API, auth, location, notifications
├── widgets/                  # Reusable widgets
└── utils/                    # Utilities

backend/
├── src/
│   ├── server.js             # Express entry
│   ├── config/               # Database config
│   ├── controllers/          # Route handlers
│   ├── middleware/           # Auth, validation
│   └── routes/              # API routes
└── package.json
```

---

## 3. Code Style Guidelines

### Imports
- Use relative imports in `lib/`: `import '../services/api_service.dart'`
- Use `package:` for external packages: `import 'package:dio/dio.dart'`
- **Avoid `dart:io`** in web files - use conditional imports or `kIsWeb` check

### Naming Conventions
- **Classes**: PascalCase (`ApiService`, `ParkingZone`)
- **Functions/Variables**: camelCase (`getCurrentLocation`, `isLoading`)
- **Constants**: UPPER_CASE (`_tokenKey`, `maxRetries`)
- **Files**: snake_case (`api_service.dart`, `auth_screen.dart`)

### Types
- Always specify return types explicitly
- Avoid `var` for non-obvious types
- Use `late` for lazily initialized fields
- Use `?` for nullable types

```dart
// Good
final String token;
Future<void> fetchData() async {}
final List<ParkingZone> zones = [];

// Avoid
var token = "...";
fetchData() async {}  // missing return type
final zones = [];     // missing type
```

### Async/Await
- Always use `async`/`await` over `.then()` chains
- Handle errors with try-catch
- Return meaningful error messages

---

## 4. Error Handling

### Flutter
- Wrap async calls in try-catch
- Show user-friendly SnackBars
- Log errors with LoggerService
- Don't expose raw errors to users

```dart
try {
  await _apiService.signIn(email, password);
} catch (e) {
  LoggerService.error('Sign in failed', error: e);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed. Please try again.')),
    );
  }
}
```

### Backend
- Use middleware for error handling
- Return proper HTTP status codes (200, 400, 401, 404, 500)
- Log errors server-side

---

## 5. Web Platform Considerations

### Critical: Avoid dart:io for Web
```dart
// WRONG - breaks web build
import 'dart:io';

// CORRECT - conditional import
import 'dart:io' as io;

// OR use kIsWeb check
import 'package:flutter/foundation.dart';
if (kIsWeb) {
  // Web-specific code
} else {
  // Mobile-specific code
}
```

### Common Web Issues
- `flutter_secure_storage` - limited on web, wrap in try-catch
- Location services - need browser permissions
- Notifications - not supported on web, always skip

---

## 6. API Integration

### Response Parsing
Backend returns different JSON structures. Check format:
```dart
final json = response.data is Map ? Map<String, dynamic>.from(response.data) : {};
final token = json['token'] as String?;
```

### Authentication
- Store JWT in flutter_secure_storage
- Include token in Authorization header
- Handle 401 responses (token expired)

---

## 7. Testing Guidelines

- Write unit tests for services
- Mock external dependencies
- Test error handling paths

```dart
test('signIn returns AuthResponse on success', () async {
  final service = ApiService();
  final response = await service.signIn('test@test.com', 'password');
  expect(response.token, isNotEmpty);
});
```

---

## 8. Git Conventions

- Run `flutter format .` before commits
- Run `flutter analyze` to check for errors
- Write meaningful commit messages
- Don't commit secrets (use .env)

---

## 9. Important Notes

### Environment Variables
- `DEV_API_BASE_URL` - Development API URL
- `PROD_API_BASE_URL` - Production API URL
- `GOOGLE_MAPS_API_KEY` - Required for map functionality

### Web Deployment
- Build: `flutter build web --release`
- Deploy `build/web` folder to Vercel
- Add Google Maps API script to index.html for web

### Backend URL
- Uses Cloudflare Tunnel: `https://homelab-backendpi.pedroocalado.eu`
- Update .env file when URL changes
