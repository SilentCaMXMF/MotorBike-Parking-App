# 05: Add Error Handling to AvailabilityEngine

## Objective
Add input validation and error handling to `lib/services/availability_engine.dart` calculations.

## Tasks
- Add validation for empty or invalid report lists
- Handle division by zero in calculations
- Validate capacity and occupancy values
- Ensure confidence score stays within 0.0-1.0 bounds

## Files to Modify
- `lib/services/availability_engine.dart`

## Implementation Notes
- Return default values (0 occupancy, 0.0 confidence) for invalid inputs
- Add assertions or early returns for edge cases
- Keep calculations robust against malformed data

## Estimated Time: 15 minutes