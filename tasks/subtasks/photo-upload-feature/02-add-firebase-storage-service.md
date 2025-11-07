# 02: Add Firebase Storage Service

## Task Description
Create a new service to handle image uploads to Firebase Storage.

## Files to Create/Modify
- `lib/services/storage_service.dart` (new file)

## Steps
1. Create `StorageService` class.
2. Add Firebase Storage dependency import.
3. Implement `uploadImage()` method that takes a `File` or `Uint8List` and returns the download URL.
4. Use a unique path for each image (e.g., `reports/${userId}/${timestamp}.jpg`).
5. Handle upload task completion and return the URL.

## Dependencies
- Ensure `firebase_storage` is added to `pubspec.yaml`.

## Acceptance Criteria
- Service can upload images and return URLs.
- Unique paths prevent overwrites.
- Basic error handling for upload failures.

## Time Estimate: 15-20 minutes