# FirestoreService - Commented Out for API Migration

## Current Status: INACTIVE

The FirestoreService has been **commented out** as part of the migration from Firebase to a custom REST API backend.

## Overview

The app has been migrated to use:
- **Backend**: Custom REST API on Raspberry Pi
- **Database**: MariaDB
- **Service**: ApiService (lib/services/api_service.dart)

The FirestoreService implementation is preserved in the codebase to enable quick rollback to Firebase if the local backend reaches capacity limits.

## Files Affected

### Main Service
- **lib/services/firestore_service.dart** - Entire class commented out with rollback instructions

### Test Mocks
- **test/mocks/mock_firestore_service.dart** - Mock implementation commented out

## Current Configuration

### What's Commented Out

1. **FirestoreService class** - All methods and Firebase Firestore integration
2. **Mock FirestoreService** - Test mocks for FirestoreService
3. **Firebase packages** in pubspec.yaml:
   - `firebase_core`
   - `cloud_firestore`
   - `firebase_auth`
   - `firebase_storage`

### What's Active

- **ApiService** - REST API client using Dio
- **JWT Authentication** - Token-based auth with flutter_secure_storage
- **MariaDB Backend** - Local database on Raspberry Pi

## FirestoreService Methods (Preserved)

The following methods are preserved in commented code:

- `initializeFirebase()` - Initialize Firebase app
- `getParkingZones()` - Stream of all parking zones
- `getParkingZone(String id)` - Get specific parking zone
- `setParkingZone(ParkingZone zone)` - Add/update parking zone
- `addUserReport(UserReport report)` - Add user report
- `updateUserReport(String id, UserReport report)` - Update user report
- `getRecentReports(String spotId)` - Get recent reports for a zone
- `updateZoneOccupancy(String zoneId, int newOccupancy)` - Update zone occupancy

## Rollback to Firebase

To re-enable FirestoreService and rollback to Firebase:

### Step 1: Uncomment Firebase Packages

Edit `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.17.0
  firebase_auth: ^4.10.0
  cloud_firestore: ^4.9.3
  firebase_storage: ^11.2.8
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Uncomment FirestoreService

Edit `lib/services/firestore_service.dart`:
- Remove the `/*` and `*/` comment markers
- Uncomment the imports at the top

### Step 4: Uncomment Mock (for tests)

Edit `test/mocks/mock_firestore_service.dart`:
- Remove the `/*` and `*/` comment markers
- Uncomment the imports

### Step 5: Uncomment Firebase Initialization

Edit `lib/main.dart`:
```dart
// Uncomment this line:
await FirestoreService().initializeFirebase();
```

### Step 6: Update Service Injection

Replace ApiService with FirestoreService in your app initialization.

### Step 7: Uncomment Firebase Configuration

- **lib/firebase_options.dart** - Uncomment the configuration
- **android/build.gradle** - Uncomment Firebase plugin classpath
- **android/app/build.gradle** - Uncomment google-services plugin
- **ios/Podfile** - Firebase pods will be auto-included via Flutter

### Step 8: Install iOS Pods (macOS only)

```bash
cd ios
pod install
cd ..
```

### Step 9: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter build apk  # For Android
flutter build ios  # For iOS (requires macOS)
```

## API Service vs FirestoreService

### FirestoreService (Commented Out)
- Real-time streams with `Stream<List<ParkingZone>>`
- Direct Firestore integration
- Automatic data synchronization
- Cloud-based (Firebase)
- Requires internet connection
- Costs scale with usage

### ApiService (Current)
- REST API calls with `Future<List<ParkingZone>>`
- HTTP requests using Dio
- Manual data fetching
- Local backend (Raspberry Pi)
- Requires local network or VPN
- Fixed infrastructure cost

## Migration Benefits

1. **Cost Reduction** - No Firebase usage fees
2. **Data Ownership** - Full control over data
3. **Local Processing** - Faster for local users
4. **Customization** - Full backend control

## Migration Considerations

1. **Capacity** - Local backend has physical limits
2. **Scalability** - Firebase scales automatically
3. **Maintenance** - Local backend requires maintenance
4. **Availability** - Depends on Raspberry Pi uptime

## Requirements Satisfied

This implementation satisfies requirement **4.5**:
- FirestoreService implementation commented out
- File preserved for future scaling needs
- Rollback instructions documented
- No breaking changes to codebase

## Status

- **Migration Date**: November 2025
- **Status**: Inactive (commented out)
- **Rollback Capability**: Fully preserved and documented
- **Current Service**: ApiService with REST API backend

## Notes

- The FirestoreService code is fully functional when uncommented
- All Firebase configuration files are preserved
- Tests using FirestoreService mocks are also commented out
- The app builds successfully without FirestoreService
- No imports of FirestoreService exist in active code
