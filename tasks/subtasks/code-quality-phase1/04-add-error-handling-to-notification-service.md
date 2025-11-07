# 04: Add Error Handling to NotificationService

## Objective
Add error handling to `lib/services/notification_service.dart` for notification initialization and display.

## Tasks
- Wrap `initialize()` method in try-catch
- Add error handling to `showNotification()` method
- Handle platform-specific notification errors
- Gracefully handle cases where notifications are disabled

## Files to Modify
- `lib/services/notification_service.dart`

## Implementation Notes
- Catch `PlatformException` for platform-specific errors
- Log errors but don't throw; notifications are non-critical
- Ensure initialization failures don't break app startup

## Estimated Time: 10 minutes