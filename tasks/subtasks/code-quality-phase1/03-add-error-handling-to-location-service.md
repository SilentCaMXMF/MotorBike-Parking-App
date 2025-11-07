# 03: Add Error Handling to LocationService

## Objective
Improve error handling in `lib/services/location_service.dart` for location permissions and services.

## Tasks
- Enhance permission request error handling
- Add timeout handling for location requests
- Provide more specific error messages for different failure scenarios
- Handle platform-specific location errors

## Files to Modify
- `lib/services/location_service.dart`

## Implementation Notes
- Use `LocationServiceDisabledException`, `PermissionDeniedException` from Geolocator
- Add timeout to `getCurrentPosition` call
- Return custom error messages suitable for UI display

## Estimated Time: 10 minutes