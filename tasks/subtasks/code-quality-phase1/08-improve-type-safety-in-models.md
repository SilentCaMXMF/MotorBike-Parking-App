# 08: Improve Type Safety in Models

## Objective
Enhance type safety in `lib/models/parking_zone.dart` and `lib/models/user_report.dart`.

## Tasks
- Add null checks and safe casting in `fromJson` methods
- Handle missing or invalid JSON fields gracefully
- Use nullable types appropriately
- Add validation for required fields

## Files to Modify
- `lib/models/parking_zone.dart`
- `lib/models/user_report.dart`

## Implementation Notes
- Use `as` with null checks or `?.` operators
- Provide default values for optional fields
- Throw descriptive errors for missing required fields

## Estimated Time: 15 minutes