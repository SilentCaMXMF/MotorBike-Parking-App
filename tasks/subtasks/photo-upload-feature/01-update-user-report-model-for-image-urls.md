# 01: Update UserReport Model for Image URLs

## Task Description
Add support for storing image URLs in the UserReport model to associate photos with parking reports.

## Files to Modify
- `lib/models/user_report.dart`

## Steps
1. Add a `List<String> imageUrls` field to the UserReport class.
2. Update the constructor to accept the imageUrls parameter.
3. Update the `toMap()` method to include imageUrls.
4. Update the `fromMap()` factory constructor to parse imageUrls.
5. Update the `copyWith()` method if it exists, or add one for immutability.

## Acceptance Criteria
- UserReport can store multiple image URLs.
- Serialization/deserialization works correctly.
- Model remains backward compatible (default to empty list).

## Time Estimate: 10-15 minutes