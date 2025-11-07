# 06: Add Error Handling for Photo Upload

## Task Description
Implement comprehensive error handling for photo upload failures.

## Files to Modify
- `lib/widgets/reporting_dialog.dart`
- `lib/services/storage_service.dart`

## Steps
1. In `StorageService.uploadImage()`, wrap upload in try-catch and throw custom exceptions.
2. In `ReportingDialog`, catch upload errors and display user-friendly messages via SnackBar.
3. Handle cases like network issues, permission denied, invalid file types.
4. Allow retry or skip failed uploads.

## Acceptance Criteria
- Upload failures are communicated to the user.
- App doesn't crash on upload errors.
- Graceful degradation (e.g., submit report without images if upload fails).

## Time Estimate: 10-15 minutes