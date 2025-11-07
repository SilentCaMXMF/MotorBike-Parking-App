# 05: Update Firestore Service to Store Image URLs

## Task Description
Ensure the Firestore service properly stores the image URLs when saving UserReport.

## Files to Modify
- `lib/services/firestore_service.dart`

## Steps
1. Verify that the `saveUserReport()` method uses `report.toMap()` which now includes `imageUrls`.
2. If needed, update any specific handling for the report data.
3. Ensure the collection/document structure supports the new field.

## Acceptance Criteria
- Image URLs are saved to Firestore with the report.
- Retrieval of reports includes image URLs.

## Time Estimate: 5-10 minutes