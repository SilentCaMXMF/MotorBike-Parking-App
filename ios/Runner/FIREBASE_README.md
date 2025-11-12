# Firebase Configuration Files - Not Currently Used

## Overview

This directory contains Firebase configuration files that are preserved for future scaling needs but are **NOT currently used** by the application.

The app has been migrated to use a custom REST API backend instead of Firebase services.

## Files

### GoogleService-Info.plist

This file contains Firebase project configuration for iOS and is kept in the repository to enable quick rollback to Firebase if the local Raspberry Pi backend reaches capacity limits.

### Podfile (ios/Podfile)

The iOS Podfile has been created with Firebase pod references documented but not active. Since Firebase packages are commented out in `pubspec.yaml`, no Firebase pods will be installed when running `pod install`.

## Current Configuration Status

### ✅ Completed Migration Steps

1. **Firebase packages commented out** in `pubspec.yaml`:

   - `firebase_core`
   - `firebase_auth`
   - `cloud_firestore`
   - `firebase_storage`

2. **Firebase initialization commented out** in `lib/main.dart`

3. **Firebase options commented out** in `lib/firebase_options.dart`

4. **Android Firebase configuration commented out**:

   - `android/build.gradle` - Firebase plugin classpath
   - `android/app/build.gradle` - google-services plugin

5. **iOS Firebase configuration documented** in `ios/Podfile`:
   - Firebase pod references documented but not active
   - Pods automatically managed by Flutter based on pubspec.yaml

## Re-enabling Firebase (Rollback Procedure)

To re-enable Firebase for iOS:

1. **Uncomment Firebase packages in `pubspec.yaml`**

   ```yaml
   firebase_core: ^2.17.0
   firebase_auth: ^4.10.0
   cloud_firestore: ^4.9.3
   firebase_storage: ^11.2.8
   ```

2. **Uncomment Firebase initialization in `lib/main.dart`**

3. **Uncomment Firebase configuration in `lib/firebase_options.dart`**

4. **Run Flutter pub get**

   ```bash
   flutter pub get
   ```

5. **Install iOS pods (requires macOS)**

   ```bash
   cd ios
   pod install
   cd ..
   ```

6. **Uncomment FirestoreService implementation**

7. **Update service injection to use FirestoreService**

8. **Clean and rebuild**
   ```bash
   flutter clean
   flutter pub get
   flutter build ios
   ```

## Verification Steps

To verify iOS builds successfully without Firebase:

1. **Check Firebase packages are commented out**

   ```bash
   grep "^  # firebase" pubspec.yaml
   ```

2. **Run pod install (requires macOS with CocoaPods)**

   ```bash
   cd ios
   pod install
   ```

3. **Verify no Firebase pods installed**

   ```bash
   ls ios/Pods 2>/dev/null | grep -i firebase
   # Should return no results
   ```

4. **Build iOS app (requires macOS with Xcode)**
   ```bash
   flutter build ios --release
   ```

## Current Status

- **Status**: Inactive (commented out)
- **Migration Date**: November 2025
- **Reason**: Cost reduction and data ownership via local backend
- **Rollback Capability**: Preserved and documented

## Notes

- iOS development and building requires macOS with Xcode and CocoaPods installed
- The `GoogleService-Info.plist` file is kept for future use but is not loaded by the app
- Firebase pods are automatically managed by Flutter's plugin system based on pubspec.yaml dependencies
- Since Firebase packages are commented out in pubspec.yaml, no Firebase pods will be included when running `pod install`
- Keep `GoogleService-Info.plist` secure and do not commit sensitive credentials to version control
