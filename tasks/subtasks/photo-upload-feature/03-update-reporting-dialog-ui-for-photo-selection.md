# 03: Update ReportingDialog UI for Photo Selection

## Task Description
Modify the ReportingDialog to include UI elements for selecting and displaying photos.

## Files to Modify
- `lib/widgets/reporting_dialog.dart`

## Steps
1. Add `image_picker` dependency to `pubspec.yaml` if not present.
2. Import necessary packages.
3. Add state variables for selected images (List<File> or similar).
4. Add a button or icon to pick images from gallery/camera.
5. Display selected images in a grid or list below the form.
6. Add remove buttons for each selected image.

## Acceptance Criteria
- Users can select multiple images.
- Selected images are previewed in the dialog.
- UI is responsive and fits within the dialog.

## Time Estimate: 15-20 minutes