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
flutter run --debug                # Run in debug mode

# Code quality
flutter analyze                    # Run static analysis (lint)
flutter format .                  # Format all Dart files

# Testing
flutter test                     # Run all tests
flutter test test/path/to/file.dart       # Run single test file
flutter test --plain-name "test name"     # Run tests matching name
flutter test --reporter expanded         # Detailed test output
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
npm run lint           # Run ESLint
```

---

## 2. Project Structure

```
lib/
├── main.dart                  # App entry point
├── config/
│   └── environment.dart      # Environment configuration
├── models/
│   ├── models.dart           # Barrel file
│   ├── parking_zone.dart    # Parking zone model
│   └── user_report.dart     # User report model
├── screens/
│   ├── auth_screen.dart     # Authentication screen
│   └── map_screen.dart     # Main map screen
├── services/
│   ├── api_service.dart     # HTTP client (singleton)
│   ├── auth_service.dart   # Auth (Firebase stubbed)
│   ├── location_service.dart   # GPS location
│   ├── notification_service.dart  # Push notifications
│   ├── polling_service.dart  # Background polling
│   ├── sql_service.dart     # Database operations
│   ├── storage_service.dart # File storage (Firebase stubbed)
│   ├── logger_service.dart  # Logging utility
│   └── availability_engine.dart  # Business logic
├── widgets/
│   └── reporting_dialog.dart  # Report submission dialog
└── utils/
    └── error_messages.dart    # Error message constants

backend/
├── src/
│   ├── server.js            # Express server entry
│   ├── config/             # Database config
│   ├── controllers/       # Route handlers
│   ├── middleware/        # Auth, validation
│   └── routes/            # API routes
└── package.json
```

---

## 3. Code Style Guidelines

### Imports
- Use relative imports for files in `lib/`: `import '../services/api_service.dart'`
- Use `package:` for external packages: `import 'package:dio/dio.dart'`
- Avoid `dart:io` in files used by web (use conditional imports: `import 'dart:io' if (dart.library.html) 'dart:html'`)
- Use platform detection: `import 'package:flutter/foundation.dart'` then `kIsWeb`

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
Future<void() async {> fetchData ... }
final List<ParkingZone> zones = [];

// Avoid
var token = "...";
fetchData() async { ... }
final zones = [];
```

### Async/Await
- Always use `async`/`await` over `.then()` chains
- Handle `Future` properly with try-catch
- Return meaningful error messages

```dart
// Good
Future<AuthResponse> signIn(String email, String password) async {
  try {
    final response = await post('/api/auth/login', body: {...});
    return AuthResponse.fromJson(response.data);
  } catch (e) {
    LoggerService.error('Login failed: $e');
    rethrow;
  }
}
```

---

## 4. Error Handling

### Frontend (Flutter)
- Wrap async calls in try-catch
- Show user-friendly SnackBars for errors
- Log errors with LoggerService
- Don't expose raw error messages to users

```dart
try {
  await _apiService.signIn(email, password);
} catch (e) {
  LoggerService.error('Sign in failed', error: e);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login failed. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Backend (Node.js)
- Use middleware for error handling
- Return proper HTTP status codes
- Log errors server-side

---

## 5. State Management

- Use `setState()` for simple UI state
- Consider Provider for complex shared state
- Keep stateful widgets focused and small
- Extract reusable state logic into services

---

## 6. Web Platform Considerations

### Critical: Avoid dart:io for Web
```dart
// WRONG - will break web build
import 'dart:io';
final file = File(path);

// CORRECT - conditional import
import 'dart:io' as io;
final file = io.File(path);

// OR use kIsWeb check
import 'package:flutter/foundation.dart';
if (kIsWeb) {
  // Web-specific code
} else {
  // Mobile-specific code
}
```

### Common Web Issues
- `flutter_secure_storage` - works on web but limited
- Location services - need browser permissions
- File uploads - use bytes not File on web
- Notifications - not supported, always skip

---

## 7. API Integration

### Response Parsing
The backend returns different JSON structures. Always check response format:
```dart
// Backend returns: { token: "...", user: { id: "...", email: "..." } }
// NOT wrapped in 'data' field for anonymous login
final json = response.data is Map ? Map<String, dynamic>.from(response.data) : {};
final token = json['token'] as String?;
```

### Authentication
- Store JWT in flutter_secure_storage
- Include token in Authorization header
- Handle 401 responses (token expired)

---

## 8. Testing Guidelines

- Write unit tests for services
- Write widget tests for UI components
- Mock external dependencies
- Test error handling paths

```dart
// Test example
test('signIn returns AuthResponse on success', () async {
  final service = ApiService();
  final response = await service.signIn('test@test.com', 'password');
  expect(response.token, isNotEmpty);
});
```

---

## 9. Git Conventions

- Run `flutter format .` before commits
- Run `flutter analyze` to check for errors
- Write meaningful commit messages
- Don't commit secrets (use .env)

---

## 10. Important Notes

### Backend URL
- Development: Uses Cloudflare Tunnel URL (changes on restart)
- Update `.env` file with current URL
- Rebuild and redeploy after URL changes

### Firebase
- Currently stubbed (using API-based auth instead)
- To re-enable: uncomment imports in main.dart, add packages to pubspec.yaml

### Environment Variables
- `DEV_API_BASE_URL` - Development API URL
- `PROD_API_BASE_URL` - Production API URL  
- `GOOGLE_MAPS_API_KEY` - Required for map functionality
