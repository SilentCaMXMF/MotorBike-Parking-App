# 04: Integrate Photo Upload Logic in ReportingDialog

## Task Description
Integrate the photo upload process into the report submission flow in ReportingDialog.

## Files to Modify
- `lib/widgets/reporting_dialog.dart`

## Steps
1. Import `StorageService`.
2. In the submit method, before saving the report:
   - Upload each selected image using `StorageService.uploadImage()`.
   - Collect the returned URLs into a list.
3. Pass the list of URLs to the UserReport creation.
4. Show loading indicator during uploads.
5. Handle upload failures by showing errors and preventing submission.

## Acceptance Criteria
- Photos are uploaded before report submission.
- Report includes image URLs.
- User feedback during upload process.

## Time Estimate: 15-20 minutes