# Firebase Configuration Files - Not Currently Used

## GoogleService-Info.plist

This file is preserved for future scaling needs but is **NOT currently used** by the application.

The app has been migrated to use a custom REST API backend instead of Firebase services.

### Purpose

This file contains Firebase project configuration for iOS and is kept in the repository to enable quick rollback to Firebase if the local Raspberry Pi backend reaches capacity limits.

### Re-enabling Firebase

To re-enable Firebase for iOS:

1. Uncomment Firebase packages in `pubspec.yaml`
2. Uncomment Firebase initialization in `lib/main.dart`
3. Uncomment Firebase configuration in `lib/firebase_options.dart`
4. Uncomment Firebase pod references in `ios/Podfile`
5. Run: `flutter pub get`
6. Run: `cd ios && pod install`
7. Run: `flutter clean && flutter build ios`

### Current Status

- **Status**: Inactive (commented out)
- **Migration Date**: 2025
- **Reason**: Cost reduction and data ownership via local backend
