# 02: Add Error Handling to FirestoreService

## Objective
Add comprehensive error handling to `lib/services/firestore_service.dart` for Firestore operations and data parsing.

## Tasks
- Wrap Firestore read/write operations in try-catch blocks
- Handle `FirebaseException` for connection/query errors
- Add null safety checks in `getParkingZone` and data parsing
- Ensure `fromJson` methods in models handle missing fields gracefully
- Catch errors in `addUserReport` and related updates

## Files to Modify
- `lib/services/firestore_service.dart`
- Potentially `lib/models/parking_zone.dart` and `lib/models/user_report.dart` for safer fromJson

## Implementation Notes
- Use `FirebaseException` for Firestore-specific errors
- Return null or empty lists on errors where appropriate
- Log errors for debugging but don't expose internal details

## Estimated Time: 20 minutes