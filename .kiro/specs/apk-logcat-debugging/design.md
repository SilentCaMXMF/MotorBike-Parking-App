# APK Logcat Debugging Design Document

## Overview

This design establishes a comprehensive debugging workflow for the Motorbike Parking App APK using Android's logcat system. The solution combines command-line tools (ADB), IDE extensions, and Flutter-specific debugging techniques to capture, filter, and analyze runtime logs from both debug and release builds.

The design focuses on practical, actionable debugging steps that developers can execute immediately when encountering APK issues, with particular emphasis on the differences between development and production builds.

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Developer Workstation                    │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │   IDE/Editor   │  │  ADB Client  │  │  Log Analysis   │ │
│  │   + Extension  │  │              │  │     Tools       │ │
│  └────────┬───────┘  └──────┬───────┘  └────────┬────────┘ │
│           │                  │                    │          │
└───────────┼──────────────────┼────────────────────┼──────────┘
            │                  │                    │
            └──────────────────┼────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │   ADB Server        │
                    │   (USB/WiFi)        │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Android Device     │
                    │  ┌───────────────┐  │
                    │  │  APK Running  │  │
                    │  │  (Debug/Rel)  │  │
                    │  └───────┬───────┘  │
                    │          │          │
                    │  ┌───────▼───────┐  │
                    │  │ Logcat Buffer │  │
                    │  │ (System Logs) │  │
                    │  └───────────────┘  │
                    └─────────────────────┘
```

### Debugging Workflow Stages

1. **Setup Phase**: Install tools, configure environment, connect device
2. **Capture Phase**: Start log collection with appropriate filters
3. **Reproduction Phase**: Execute app actions that trigger issues
4. **Analysis Phase**: Review logs, identify error patterns, locate stack traces
5. **Resolution Phase**: Apply fixes, rebuild, verify with new log session

## Components and Interfaces

### 1. ADB Command-Line Interface

**Purpose**: Direct interaction with Android device for log capture and device management.

**Key Commands**:

```bash
# Device connection and verification
adb devices                          # List connected devices
adb connect <ip>:5555               # Connect via WiFi (if enabled)

# Basic log capture
adb logcat                          # Stream all logs
adb logcat -c                       # Clear log buffer
adb logcat -d > logs.txt            # Dump logs to file

# Filtered log capture
adb logcat *:E                      # Show only Error level and above
adb logcat *:W                      # Show Warning level and above
adb logcat flutter:V *:S            # Show only Flutter logs (verbose)
adb logcat | grep -i "exception"    # Filter for exceptions

# Flutter-specific filtering
adb logcat | grep "flutter"         # All Flutter output
adb logcat | grep "E/flutter"       # Flutter errors only
adb logcat | grep -E "flutter|DartVM" # Flutter and Dart VM logs

# Application-specific filtering (replace with your package name)
adb logcat | grep "com.example.motorbike_parking"
adb logcat --pid=$(adb shell pidof -s com.example.motorbike_parking)

# Time-based filtering
adb logcat -t 500                   # Last 500 lines
adb logcat -T "01-17 12:00:00.000"  # Since specific timestamp

# Format options
adb logcat -v time                  # Include timestamps
adb logcat -v threadtime            # Include thread info
adb logcat -v long                  # Detailed format
```

**Output Format**:

```
<timestamp> <priority>/<tag>(<pid>): <message>
```

### 2. IDE Extensions

**Recommended Extensions**:

#### For VS Code:

- **Android iOS Emulator** (by DiemasMichiels): Device management and logcat viewer
- **Flutter** (by Dart Code): Integrated Flutter debugging with log output
- **Logcat** (by abhiagr): Dedicated logcat viewer with filtering

**Installation**:

```bash
# Via VS Code command palette
# Ctrl+Shift+P -> Extensions: Install Extensions -> Search for extension name
```

**Configuration** (settings.json):

```json
{
  "flutter.flutterSdkPath": "/path/to/flutter",
  "dart.flutterSdkPath": "/path/to/flutter",
  "logcat.autoStart": true,
  "logcat.filterSpecs": ["*:W"],
  "logcat.format": "threadtime"
}
```

#### For Android Studio:

- **Built-in Logcat**: Native support with advanced filtering UI
- **ADB Idea**: Enhanced ADB operations from IDE

**Access**: View → Tool Windows → Logcat

### 3. Flutter Logging Enhancement

**Purpose**: Add structured logging to the Flutter app for better debugging.

**Implementation Strategy**:

```dart
// lib/services/logger_service.dart
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class LoggerService {
  static const String _tag = 'MotorbikeParking';

  static void debug(String message, {String? component}) {
    final prefix = component != null ? '[$component]' : '';
    developer.log(
      '$prefix $message',
      name: _tag,
      level: 500, // Debug level
    );
  }

  static void info(String message, {String? component}) {
    final prefix = component != null ? '[$component]' : '';
    developer.log(
      '$prefix $message',
      name: _tag,
      level: 800, // Info level
    );
  }

  static void warning(String message, {String? component}) {
    final prefix = component != null ? '[$component]' : '';
    developer.log(
      '$prefix $message',
      name: _tag,
      level: 900, // Warning level
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String? component}) {
    final prefix = component != null ? '[$component]' : '';
    developer.log(
      '$prefix $message',
      name: _tag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Network-specific logging
  static void logNetworkRequest(String method, String url, {Map<String, dynamic>? body}) {
    if (kDebugMode || kProfileMode) {
      info('HTTP $method $url ${body != null ? "with body" : ""}', component: 'Network');
    }
  }

  static void logNetworkResponse(int statusCode, String url, {dynamic body}) {
    if (kDebugMode || kProfileMode) {
      info('HTTP Response $statusCode from $url', component: 'Network');
    }
  }

  static void logNetworkError(String url, Object error) {
    LoggerService.error('Network error for $url', error: error, component: 'Network');
  }
}
```

**Usage in API Service**:

```dart
// lib/services/api_service.dart
Future<Response> _makeRequest(String method, String endpoint, {dynamic body}) async {
  final url = '$baseUrl$endpoint';

  LoggerService.logNetworkRequest(method, url, body: body);

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    LoggerService.logNetworkResponse(response.statusCode, url, body: response.body);

    return response;
  } catch (e, stackTrace) {
    LoggerService.logNetworkError(url, e);
    rethrow;
  }
}
```

### 4. Log Analysis Tools

**Purpose**: Process and analyze captured logs for patterns and issues.

**Shell Script for Common Filters** (save as `analyze_logs.sh`):

```bash
#!/bin/bash

LOG_FILE=${1:-"logcat.txt"}

if [ ! -f "$LOG_FILE" ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

echo "=== Flutter Errors ==="
grep -i "E/flutter" "$LOG_FILE"

echo -e "\n=== Exceptions ==="
grep -i "exception" "$LOG_FILE"

echo -e "\n=== Fatal Errors ==="
grep -i "fatal" "$LOG_FILE"

echo -e "\n=== Network Errors ==="
grep -i "network\|http\|connection" "$LOG_FILE" | grep -i "error\|fail"

echo -e "\n=== Dart VM Errors ==="
grep "E/DartVM" "$LOG_FILE"

echo -e "\n=== Stack Traces ==="
grep -A 10 "StackTrace" "$LOG_FILE"

echo -e "\n=== Crash Summary ==="
grep -i "crash\|segfault\|signal" "$LOG_FILE"
```

## Data Models

### Log Entry Structure

```dart
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final int pid;
  final String message;
  final String? component;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.pid,
    required this.message,
    this.component,
  });
}

enum LogLevel {
  verbose,  // V
  debug,    // D
  info,     // I
  warning,  // W
  error,    // E
  fatal,    // F
}
```

### Debug Session Metadata

```dart
class DebugSession {
  final String deviceId;
  final String deviceModel;
  final String androidVersion;
  final String appVersion;
  final String buildType; // debug or release
  final DateTime startTime;
  final String? description;

  DebugSession({
    required this.deviceId,
    required this.deviceModel,
    required this.androidVersion,
    required this.appVersion,
    required this.buildType,
    required this.startTime,
    this.description,
  });

  String toHeader() {
    return '''
=== Debug Session ===
Device: $deviceModel ($deviceId)
Android: $androidVersion
App Version: $appVersion
Build Type: $buildType
Started: $startTime
Description: ${description ?? 'N/A'}
====================
''';
  }
}
```

## Error Handling

### Common APK Issues and Log Patterns

#### 1. Network Connection Failures

**Symptoms**: API calls fail, timeout errors
**Log Pattern**:

```
E/flutter: [Network] Network error for http://...
E/flutter: SocketException: Failed host lookup
```

**Debug Steps**:

- Check internet permission in AndroidManifest.xml
- Verify network security config for HTTP (if using HTTP)
- Test API endpoint accessibility from device browser
- Check for certificate issues with HTTPS

#### 2. Permission Errors

**Symptoms**: Features fail silently, permission denied errors
**Log Pattern**:

```
E/PermissionManager: Permission denied for ...
E/flutter: PlatformException(PERMISSION_DENIED, ...)
```

**Debug Steps**:

- Verify permissions declared in AndroidManifest.xml
- Check runtime permission requests in code
- Test on different Android versions (permissions changed in Android 6+)

#### 3. Build Configuration Issues

**Symptoms**: App crashes on startup, missing resources
**Log Pattern**:

```
E/AndroidRuntime: FATAL EXCEPTION: main
E/flutter: Unable to load asset: ...
```

**Debug Steps**:

- Check pubspec.yaml for asset declarations
- Verify ProGuard rules for release builds
- Check for missing native dependencies

#### 4. State Management Errors

**Symptoms**: UI doesn't update, setState called after dispose
**Log Pattern**:

```
E/flutter: setState() called after dispose()
E/flutter: Null check operator used on a null value
```

**Debug Steps**:

- Add lifecycle logging to StatefulWidgets
- Check for async operations completing after widget disposal
- Verify null safety handling

### Error Recovery Strategies

```dart
// Wrap critical operations with comprehensive error handling
Future<void> criticalOperation() async {
  try {
    LoggerService.debug('Starting critical operation', component: 'Feature');

    // Operation code

    LoggerService.info('Critical operation completed', component: 'Feature');
  } on SocketException catch (e, stackTrace) {
    LoggerService.error('Network error in critical operation',
      error: e, stackTrace: stackTrace, component: 'Feature');
    // Show user-friendly error
  } on FormatException catch (e, stackTrace) {
    LoggerService.error('Data format error in critical operation',
      error: e, stackTrace: stackTrace, component: 'Feature');
    // Handle parsing errors
  } catch (e, stackTrace) {
    LoggerService.error('Unexpected error in critical operation',
      error: e, stackTrace: stackTrace, component: 'Feature');
    // Generic error handling
  }
}
```

## Testing Strategy

### Debug vs Release Build Testing

#### Debug Build Characteristics:

- Full logging enabled
- No code obfuscation
- Larger APK size
- Slower performance
- Easier to debug

**Build Command**:

```bash
flutter build apk --debug
```

**Log Capture**:

```bash
adb logcat flutter:V *:S
```

#### Release Build Characteristics:

- Minimal logging
- Code obfuscation enabled
- Optimized APK size
- Better performance
- Harder to debug

**Build Command**:

```bash
flutter build apk --release
```

**Log Capture** (with symbols):

```bash
# Capture logs
adb logcat *:E > release_logs.txt

# Deobfuscate stack traces (if needed)
flutter symbolize -i release_logs.txt -d build/app/outputs/mapping/release/
```

### Testing Workflow

1. **Initial Debug Build Test**:

   - Install debug APK
   - Start logcat with verbose filtering
   - Execute all app features
   - Document any errors

2. **Release Build Test**:

   - Install release APK
   - Start logcat with error filtering
   - Execute same feature set
   - Compare behavior with debug build

3. **Regression Testing**:
   - After fixes, rebuild APK
   - Clear logcat buffer
   - Re-test problematic features
   - Verify errors are resolved

### Log Collection Best Practices

```bash
# Start a new debug session
SESSION_NAME="debug_$(date +%Y%m%d_%H%M%S)"
mkdir -p logs/$SESSION_NAME

# Capture device info
adb shell getprop > logs/$SESSION_NAME/device_info.txt

# Clear old logs
adb logcat -c

# Start log capture
adb logcat -v threadtime > logs/$SESSION_NAME/logcat.txt &
LOGCAT_PID=$!

# Run your tests...
echo "Logging to logs/$SESSION_NAME/logcat.txt"
echo "Press Enter when done..."
read

# Stop log capture
kill $LOGCAT_PID

# Analyze logs
./analyze_logs.sh logs/$SESSION_NAME/logcat.txt > logs/$SESSION_NAME/analysis.txt

echo "Session saved to logs/$SESSION_NAME/"
```

## Implementation Notes

### Environment Setup Checklist

- [ ] ADB installed and in PATH
- [ ] Device connected and authorized (check `adb devices`)
- [ ] USB debugging enabled on device
- [ ] IDE extension installed (if using)
- [ ] Flutter SDK properly configured
- [ ] Log analysis scripts created and executable

### Quick Start Commands

```bash
# 1. Verify device connection
adb devices

# 2. Install APK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 3. Clear logs and start fresh capture
adb logcat -c && adb logcat -v threadtime | tee logcat_$(date +%Y%m%d_%H%M%S).txt

# 4. In another terminal, filter for errors only
adb logcat *:E

# 5. Launch app and reproduce issue
adb shell am start -n com.example.motorbike_parking/.MainActivity

# 6. When done, analyze the saved log file
grep -i "error\|exception\|fatal" logcat_*.txt
```

### Performance Considerations

- Logcat buffer size is limited (typically 256KB per buffer)
- Verbose logging can fill buffer quickly
- Use appropriate log levels to avoid missing critical errors
- Consider using `adb logcat -G <size>` to increase buffer size if needed
- For long sessions, periodically save and clear logs

### Security Considerations

- Never log sensitive user data (passwords, tokens, personal info)
- Sanitize API responses before logging
- Use conditional logging based on build type
- Remove or obfuscate logs in release builds
- Be cautious when sharing log files (may contain device/user info)

```dart
// Safe logging example
LoggerService.info('User logged in: ${user.id}', component: 'Auth'); // OK - just ID
// LoggerService.info('User logged in: ${user.email}'); // BAD - PII
```
