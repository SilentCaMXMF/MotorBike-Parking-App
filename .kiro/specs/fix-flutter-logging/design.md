# Design Document: Fix Flutter Logging for Logcat Visibility

## Overview

This design addresses the critical issue where application logs are not visible in Android logcat due to the use of `dart:developer` logging. The solution replaces `developer.log()` with `debugPrint()` and `print()` to ensure logs appear in logcat while maintaining structured logging, component tagging, and build-type conditional behavior.

## Architecture

### Current Implementation Issues

1. **LoggerService uses `developer.log()`** - Only outputs to Flutter DevTools, not logcat
2. **Invisible in production** - Release builds have no visible logs for debugging
3. **Physical device debugging** - Cannot see logs when testing APKs on real devices
4. **Inconsistent with print statements** - Some code uses `print()` (visible) while LoggerService is invisible

### Proposed Solution

Replace `developer.log()` with Flutter's standard output methods:

- **debugPrint()** for debug/info logs (respects kDebugMode)
- **print()** for warnings/errors (always visible)
- Maintain structured formatting with tags and component names
- Preserve existing API to avoid breaking changes

## Components and Interfaces

### LoggerService (Modified)

**Location:** `lib/services/logger_service.dart`

**Key Changes:**

1. Remove `dart:developer` import
2. Replace `developer.log()` with `debugPrint()` and `print()`
3. Add structured formatting with prefixes
4. Maintain log level filtering based on build mode

**Public API (Unchanged):**

```dart
class LoggerService {
  static void debug(String message, {String? component});
  static void info(String message, {String? component});
  static void warning(String message, {String? component});
  static void error(String message, {Object? error, StackTrace? stackTrace, String? component});
  static void logNetworkRequest(String method, String url, {Map<String, dynamic>? body});
  static void logNetworkResponse(int statusCode, String url, {dynamic body});
  static void logNetworkError(String url, Object error);
}
```

## Data Models

### Log Message Format

Each log message will follow this structure:

```
[TAG][LEVEL][COMPONENT] Message
```

**Examples:**

```
[MotorbikeParking][DEBUG][MapScreen] MapScreen initialized
[MotorbikeParking][INFO][Network] HTTP GET http://192.168.1.67:3000/api/spots
[MotorbikeParking][WARNING][ReportingDialog] Invalid reported count: 15 (capacity: 10)
[MotorbikeParking][ERROR][Network] Network error for http://192.168.1.67:3000/api/reports
```

### Log Levels

| Level   | Build Mode         | Output Method  | Visibility             |
| ------- | ------------------ | -------------- | ---------------------- |
| DEBUG   | Debug/Profile only | `debugPrint()` | Logcat in debug builds |
| INFO    | Debug/Profile only | `debugPrint()` | Logcat in debug builds |
| WARNING | All modes          | `print()`      | Always in logcat       |
| ERROR   | All modes          | `print()`      | Always in logcat       |

## Implementation Details

### 1. LoggerService Refactoring

**Before:**

```dart
static void debug(String message, {String? component}) {
  if (kDebugMode || kProfileMode) {
    final prefix = component != null ? '[$component]' : '';
    developer.log(
      '$prefix $message',
      name: _tag,
      level: 500,
    );
  }
}
```

**After:**

```dart
static void debug(String message, {String? component}) {
  if (kDebugMode || kProfileMode) {
    final componentTag = component != null ? '[$component]' : '';
    debugPrint('[$_tag][DEBUG]$componentTag $message');
  }
}
```

### 2. Error Logging with Stack Traces

Errors will format stack traces for readability in logcat:

```dart
static void error(
  String message, {
  Object? error,
  StackTrace? stackTrace,
  String? component,
}) {
  final componentTag = component != null ? '[$component]' : '';
  print('[$_tag][ERROR]$componentTag $message');

  if (error != null) {
    print('[$_tag][ERROR]$componentTag Error details: $error');
  }

  if (stackTrace != null) {
    print('[$_tag][ERROR]$componentTag Stack trace:\n$stackTrace');
  }
}
```

### 3. Network Logging

Network logs will include method, URL, and status codes:

```dart
static void logNetworkRequest(
  String method,
  String url, {
  Map<String, dynamic>? body,
}) {
  if (kDebugMode || kProfileMode) {
    final bodyInfo = body != null ? ' with body: ${body.keys.join(", ")}' : '';
    info('HTTP $method $url$bodyInfo', component: 'Network');
  }
}

static void logNetworkResponse(
  int statusCode,
  String url, {
  dynamic body,
}) {
  if (kDebugMode || kProfileMode) {
    final statusEmoji = statusCode >= 200 && statusCode < 300 ? '✓' : '✗';
    info('HTTP $statusEmoji $statusCode from $url', component: 'Network');
  }
}
```

### 4. Build Mode Behavior

| Build Mode | Debug Logs | Info Logs | Warning Logs | Error Logs |
| ---------- | ---------- | --------- | ------------ | ---------- |
| Debug      | ✓ Visible  | ✓ Visible | ✓ Visible    | ✓ Visible  |
| Profile    | ✓ Visible  | ✓ Visible | ✓ Visible    | ✓ Visible  |
| Release    | ✗ Hidden   | ✗ Hidden  | ✓ Visible    | ✓ Visible  |

## Testing Strategy

### Manual Testing

1. **Debug Build Testing:**

   - Run `flutter run --debug` on physical device
   - Execute `adb logcat | grep MotorbikeParking`
   - Verify all log levels appear in logcat
   - Confirm component tags are visible

2. **Release Build Testing:**

   - Build release APK: `flutter build apk --release`
   - Install on physical device
   - Execute `adb logcat | grep MotorbikeParking`
   - Verify only WARNING and ERROR logs appear
   - Confirm no DEBUG/INFO logs in output

3. **Network Logging Testing:**

   - Trigger API calls (login, fetch parking zones, submit report)
   - Verify HTTP request/response logs appear in debug mode
   - Confirm network logs include method, URL, and status codes

4. **Error Logging Testing:**
   - Trigger errors (network failure, validation error)
   - Verify error messages appear with stack traces
   - Confirm error details are readable in logcat

### Logcat Filtering Commands

```bash
# View all app logs
adb logcat | grep MotorbikeParking

# View only errors
adb logcat | grep "\[ERROR\]"

# View specific component
adb logcat | grep "\[MapScreen\]"

# View network logs
adb logcat | grep "\[Network\]"

# Clear and follow logs
adb logcat -c && adb logcat | grep MotorbikeParking
```

## Error Handling

### Potential Issues

1. **Log Flooding:** Too many debug logs can overwhelm logcat

   - **Solution:** Use appropriate log levels; avoid logging in tight loops

2. **Performance Impact:** Excessive logging in release builds

   - **Solution:** Limit release logs to warnings/errors only

3. **Sensitive Data:** Accidentally logging passwords or tokens
   - **Solution:** Review network logging to ensure no sensitive data in logs

## Migration Notes

### Backward Compatibility

- All existing `LoggerService` calls remain unchanged
- No code changes required in components using LoggerService
- Drop-in replacement for existing implementation

### Verification Checklist

After implementation:

- [ ] All existing log calls work without modification
- [ ] Logs appear in logcat during debug builds
- [ ] Warnings/errors appear in release builds
- [ ] Component tags are visible and filterable
- [ ] Network logs show HTTP details
- [ ] Error logs include stack traces
- [ ] No performance degradation in release builds

## Performance Considerations

### Debug Builds

- `debugPrint()` automatically throttles output to prevent overwhelming the system
- No significant performance impact expected

### Release Builds

- Only warnings and errors are logged
- Minimal performance overhead
- No debug/info logs processed or output

## Future Enhancements

1. **Log Levels Configuration:** Add runtime configuration for log levels
2. **Remote Logging:** Send error logs to crash reporting service
3. **Log Persistence:** Save logs to file for offline debugging
4. **Structured JSON Logs:** Format logs as JSON for better parsing
5. **Log Filtering UI:** Add in-app log viewer for debugging
