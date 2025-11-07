# 07: Add Input Validation to ReportingDialog

## Objective
Add input validation to `lib/widgets/reporting_dialog.dart` for report submission.

## Tasks
- Validate that reported count is within zone capacity bounds
- Ensure user is authenticated before submission
- Add validation for image upload (file size, format)
- Prevent submission with invalid or missing required data

## Files to Modify
- `lib/widgets/reporting_dialog.dart`

## Implementation Notes
- Show validation errors in SnackBar
- Disable submit button when validation fails
- Handle optional fields (location, image) gracefully

## Estimated Time: 15 minutes