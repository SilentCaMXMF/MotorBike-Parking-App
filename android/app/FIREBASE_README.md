# Firebase Configuration Files - Not Currently Used

## google-services.json

This file is preserved for future scaling needs but is **NOT currently used** by the application.

The app has been migrated to use a custom REST API backend instead of Firebase services.

### Purpose
This file contains Firebase project configuration for Android and is kept in the repository to enable quick rollback to Firebase if the local Raspberry Pi backend reaches capacity limits.

### Re-enabling Firebase
To re-enable Firebase for Android:

1. Uncomment Firebase packages in `pubspec.yaml`
2. Uncomment Firebase initialization in `lib/main.dart`
3. Uncomment Firebase configuration in `lib/firebase_options.dart`
4. Uncomment google-services plugin in `android/app/build.gradle`
5. Uncomment Firebase plugin classpath in `android/build.gradle`
6. Run: `flutter pub get`
7. Run: `flutter clean && flutter build apk`

### Current Status
- **Status**: Inactive (commented out)
- **Migration Date**: 2025
- **Reason**: Cost reduction and data ownership via local backend
