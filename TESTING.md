# Testing and Debugging Instructions

## Prerequisites
- Install Flutter SDK: https://flutter.dev/docs/get-started/install
- Set up Android Studio or Xcode for emulators
- Create Firebase project and add google-services.json / GoogleService-Info.plist
- Replace API key placeholders in AndroidManifest.xml and firebase_options.dart

## Testing Steps

### 1. Run Tests
```bash
flutter test
```

### 2. Build and Run on Android
```bash
flutter run --debug
```
- Test location permissions popup
- Check map displays and centers on location
- Test authentication (sign up, sign in, anonymous)
- Verify markers appear for parking zones
- Test reporting dialog and submission
- Check notifications on proximity to zones

### 3. Build and Run on iOS
```bash
flutter run --debug
```
- Same tests as Android

### 4. Edge Cases to Test
- No internet connection
- Location services disabled
- No parking zones in database
- Low confidence zones (gray markers)
- Full zones (red markers)
- Multiple reports from same user
- Anonymous user reporting

### 5. Permissions
- Location: ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION
- Notifications: Local notifications enabled
- Firebase: Auth and Firestore access

### 6. Debug Tips
- Use Flutter DevTools for performance
- Check Firebase console for data
- Test on real devices for location accuracy
- Monitor console for errors

## Known Issues
- API keys need to be configured
- Photo upload not implemented
- Background location not implemented
- User reputation not implemented