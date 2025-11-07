# 07: Add Validation for Uploaded Images

## Task Description
Add validation checks for selected images before upload.

## Files to Modify
- `lib/widgets/reporting_dialog.dart`
- `lib/services/storage_service.dart`

## Steps
1. Validate image file size (e.g., max 5MB).
2. Validate image type (e.g., only JPEG, PNG).
3. Check number of images (e.g., max 5).
4. Show validation errors in UI before upload.
5. Prevent invalid images from being selected or uploaded.

## Acceptance Criteria
- Invalid images are rejected with clear messages.
- Validation happens early in the process.
- Users understand the limits.

## Time Estimate: 10-15 minutes