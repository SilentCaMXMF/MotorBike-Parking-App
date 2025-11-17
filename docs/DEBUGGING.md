# APK Debugging Guide

## Quick Start

This guide helps you debug the Motorbike Parking App APK using Android logcat. Follow these steps to quickly capture and analyze logs from your installed APK.

### Prerequisites

- ADB (Android Debug Bridge) installed and in PATH
- Android device with USB debugging enabled
- APK installed on the device
- USB cable or WiFi debugging configured

### 5-Minute Quick Start

```bash
# 1. Verify device connection

# 2. Clear old logs
adb logcat -c

# 3. Start capturing logs (saves to file)
adb logcat -v threadtime > logcat_$(date +%Y%m%d_%H%M%S).txt

# 4. In another terminal, watch errors in real-time
adb logcat *:E

# 5. Launch the app and reproduce your issue
adb shell am start -n com.pedroocalado.motorbikeparking/.MainActivity

# 6. Stop log capture (Ctrl+C) and analyze
grep -i "error\|exception\|fatal" logcat_*.txt
```

## ADB Commands Reference

### Device Connection

```bash
# List all connected devices
adb devices

# Connect via WiFi (device must be on same network)
adb tcpip 5555
adb connect <device-ip>:5555

# Verify connection
adb shell getprop ro.product.model
```

### Log Capture Commands

#### Basic Capture

```bash
# Stream all logs to console
adb logcat

# Clear log buffer
adb logcat -c

# Dump current logs to file
adb logcat -d > logs.txt

# Stream logs to file
adb logcat > logs.txt

# Stream with timestamp
adb logcat -v threadtime > logs.txt
```

#### Filtering by Log Level

```bash
# Show only errors and fatal
adb logcat *:E

# Show warnings and above
adb logcat *:W

# Show info and above
adb logcat *:I

# Show debug and above
adb logcat *:D

# Show everything (verbose)
adb logcat *:V
```

#### Filtering by Tag

```bash
# Show only Flutter logs
adb logcat flutter:V *:S

# Show Flutter and DartVM logs
adb logcat flutter:V DartVM:V *:S

# Show only Flutter errors
adb logcat flutter:E *:S

# Show app-specific logs (replace with your package)
adb logcat | grep "com.pedroocalado.motorbikeparking"
```

#### Advanced Filtering

```bash
# Filter by process ID
adb logcat --pid=$(adb shell pidof -s com.pedroocalado.motorbikeparking)

# Show last 500 lines
adb logcat -t 500

# Show logs since specific time
adb logcat -T "11-17 12:00:00.000"

# Combine filters with grep
adb logcat | grep -i "exception"
adb logcat | grep -E "error|exception|fatal"
adb logcat | grep -i "network" | grep -i "error"
```

#### Format Options

```bash
# Brief format (default)
adb logcat -v brief

# Include timestamps
adb logcat -v time

# Include thread info
adb logcat -v threadtime

# Detailed format
adb logcat -v long

# Process format
adb logcat -v process
```

### Application Management

```bash
# Install APK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Uninstall app
adb uninstall com.pedroocalado.motorbikeparking

# Launch app
adb shell am start -n com.pedroocalado.motorbikeparking/.MainActivity

# Force stop app
adb shell am force-stop com.pedroocalado.motorbikeparking

# Get app version
adb shell dumpsys package com.pedroocalado.motorbikeparking | grep versionName
```

### Device Information

```bash
# Get device model
adb shell getprop ro.product.model

# Get Android version
adb shell getprop ro.build.version.release

# Get device properties
adb shell getprop > device_info.txt

# Check available storage
adb shell df

# Get battery status
adb shell dumpsys battery
```

## IDE Extension Setup

### VS Code Extensions

#### Recommended Extensions

1. **Flutter** (by Dart Code) - **REQUIRED**

   - Integrated Flutter debugging
   - Built-in log output
   - Hot reload support
   - Widget inspector
   - Code completion and analysis

2. **Dart** (by Dart Code) - **REQUIRED**

   - Dart language support
   - Syntax highlighting
   - Code formatting
   - Linting

3. **Android iOS Emulator** (by DiemasMichiels) - **RECOMMENDED**

   - Device management
   - Logcat viewer
   - APK installation
   - Emulator control

4. **Logcat** (by abhiagr) - **OPTIONAL**
   - Dedicated logcat viewer
   - Advanced filtering
   - Color-coded output
   - Regex support

#### Installation Steps

1. Open VS Code
2. Press `Ctrl+Shift+X` (or `Cmd+Shift+X` on Mac)
3. Search for extension name
4. Click "Install"
5. Reload VS Code if prompted

**Quick Install via Command Line:**

```bash
# Install Flutter and Dart extensions
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code

# Install optional extensions
code --install-extension DiemasMichiels.emulate
code --install-extension abhiagr.logcat
```

#### VS Code Configuration

The project includes pre-configured VS Code settings in `.vscode/settings.json`:

```json
{
  "kiroAgent.configureMCP": "Enabled",
  // Flutter and Dart settings
  "dart.flutterSdkPath": null,
  "dart.debugExternalPackageLibraries": true,
  "dart.debugSdkLibraries": false,
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  // Logcat settings
  "logcat.autoStart": false,
  "logcat.filterSpecs": ["*:W"],
  "logcat.format": "threadtime",
  // Editor settings for Flutter
  "editor.formatOnSave": true,
  "editor.rulers": [80],
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit"
  },
  // File associations
  "files.associations": {
    "*.dart": "dart"
  },
  // Search exclusions
  "search.exclude": {
    "**/.dart_tool": true,
    "**/build": true,
    "**/.gradle": true,
    "**/android/.gradle": true
  }
}
```

**Key Settings Explained:**

- `dart.debugExternalPackageLibraries`: Enable debugging into package code
- `dart.debugSdkLibraries`: Disable debugging into Flutter SDK (reduces noise)
- `logcat.autoStart`: Manual logcat start (prevents auto-connection issues)
- `logcat.filterSpecs`: Default to warnings and above
- `editor.formatOnSave`: Auto-format Dart code on save

#### Launch Configurations

The project includes pre-configured launch configurations in `.vscode/launch.json`:

##### 1. Flutter: Debug (Default)

Standard debug mode with full logging and hot reload.

```json
{
  "name": "Flutter: Debug",
  "type": "dart",
  "request": "launch",
  "program": "lib/main.dart",
  "flutterMode": "debug"
}
```

**Usage:**

- Press `F5` or click "Run and Debug" → "Flutter: Debug"
- Supports hot reload (`r` in terminal) and hot restart (`R`)
- Full logging enabled
- Slower performance but easier debugging

##### 2. Flutter: Profile

Profile mode for performance testing.

```json
{
  "name": "Flutter: Profile",
  "type": "dart",
  "request": "launch",
  "program": "lib/main.dart",
  "flutterMode": "profile"
}
```

**Usage:**

- Select "Flutter: Profile" from debug dropdown
- Press `F5` to launch
- Reduced logging, better performance
- Use for performance profiling

##### 3. Flutter: Release

Release mode for production testing.

```json
{
  "name": "Flutter: Release",
  "type": "dart",
  "request": "launch",
  "program": "lib/main.dart",
  "flutterMode": "release"
}
```

**Usage:**

- Select "Flutter: Release" from debug dropdown
- Press `F5` to launch
- Minimal logging, best performance
- Test production behavior

##### 4. Flutter: Debug (Android)

Debug mode specifically for Android devices.

```json
{
  "name": "Flutter: Debug (Android)",
  "type": "dart",
  "request": "launch",
  "program": "lib/main.dart",
  "flutterMode": "debug",
  "deviceId": "android"
}
```

**Usage:**

- Automatically selects Android device
- Useful when multiple devices connected
- Same as standard debug mode

##### 5. Flutter: Debug (iOS)

Debug mode specifically for iOS devices/simulators.

```json
{
  "name": "Flutter: Debug (iOS)",
  "type": "dart",
  "request": "launch",
  "program": "lib/main.dart",
  "flutterMode": "debug",
  "deviceId": "ios"
}
```

**Usage:**

- Automatically selects iOS device/simulator
- Requires macOS and Xcode
- Same as standard debug mode

##### 6. Flutter: Attach to Device

Attach debugger to already running app.

```json
{
  "name": "Flutter: Attach to Device",
  "type": "dart",
  "request": "attach",
  "vmServiceUri": "${command:dart.promptForVmServiceUri}"
}
```

**Usage:**

- Launch app separately (e.g., from command line)
- Select "Flutter: Attach to Device"
- Enter VM service URI when prompted
- Useful for debugging already running apps

#### Using VS Code Debugging

##### Starting a Debug Session

1. **Select Device:**

   - Open Command Palette (`Ctrl+Shift+P`)
   - Type "Flutter: Select Device"
   - Choose your connected device or emulator

2. **Choose Configuration:**

   - Click debug dropdown (top of sidebar)
   - Select desired configuration (e.g., "Flutter: Debug")

3. **Start Debugging:**
   - Press `F5` or click green play button
   - App will build and launch on selected device

##### Debug Console

View logs and interact with the running app:

- **Location:** Bottom panel → "Debug Console" tab
- **Features:**
  - Real-time log output
  - Error messages with stack traces
  - Hot reload notifications
  - Performance metrics

**Useful Commands in Debug Console:**

```
r - Hot reload
R - Hot restart
q - Quit
h - Help
```

##### Breakpoints

Set breakpoints to pause execution:

1. Click left margin next to line number (red dot appears)
2. Run app in debug mode
3. Execution pauses when breakpoint hit
4. Inspect variables in "Variables" panel
5. Step through code with toolbar buttons

**Breakpoint Controls:**

- `F10` - Step over
- `F11` - Step into
- `Shift+F11` - Step out
- `F5` - Continue

##### Variables and Watch

Inspect variable values during debugging:

- **Variables Panel:** Shows all variables in current scope
- **Watch Panel:** Add expressions to monitor
- **Call Stack:** View function call hierarchy

##### Using the Flutter Extension

1. **Device Selection:**

   ```
   Ctrl+Shift+P → Flutter: Select Device
   ```

2. **Hot Reload:**

   ```
   Ctrl+Shift+P → Flutter: Hot Reload
   or press 'r' in Debug Console
   ```

3. **Hot Restart:**

   ```
   Ctrl+Shift+P → Flutter: Hot Restart
   or press 'R' in Debug Console
   ```

4. **Open DevTools:**

   ```
   Ctrl+Shift+P → Flutter: Open DevTools
   ```

5. **Clean Build:**
   ```
   Ctrl+Shift+P → Flutter: Clean Project
   ```

##### Using the Logcat Extension

1. **Start Logcat:**

   ```
   Ctrl+Shift+P → Logcat: Start
   ```

2. **View Logs:**

   - Open "Output" panel (bottom)
   - Select "Logcat" from dropdown

3. **Filter Logs:**

   - Use filter buttons in Output panel
   - Or modify `logcat.filterSpecs` in settings

4. **Stop Logcat:**
   ```
   Ctrl+Shift+P → Logcat: Stop
   ```

#### Debugging Workflow in VS Code

##### Standard Workflow

1. **Setup:**

   ```bash
   # Ensure device connected
   adb devices
   ```

2. **In VS Code:**

   - Open project folder
   - Select device (`Ctrl+Shift+P` → "Flutter: Select Device")
   - Choose debug configuration
   - Press `F5`

3. **During Debugging:**

   - View logs in Debug Console
   - Set breakpoints as needed
   - Use hot reload for quick changes
   - Monitor variables and call stack

4. **After Session:**
   - Review logs in Debug Console
   - Export logs if needed (copy from console)

##### APK Debugging Workflow

For debugging installed APKs (not launched from VS Code):

1. **Install APK:**

   ```bash
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

2. **Start Logcat in VS Code:**

   ```
   Ctrl+Shift+P → Logcat: Start
   ```

3. **Launch App on Device:**

   ```bash
   adb shell am start -n com.pedroocalado.motorbikeparking/.MainActivity
   ```

4. **View Logs:**

   - Check "Output" panel → "Logcat"
   - Or use Debug Console if attached

5. **Attach Debugger (Optional):**
   - Select "Flutter: Attach to Device" configuration
   - Enter VM service URI when prompted

##### Troubleshooting VS Code Issues

**Issue: Device Not Detected**

```bash
# Check ADB connection
adb devices

# Restart ADB server
adb kill-server
adb start-server

# In VS Code, reload window
Ctrl+Shift+P → Developer: Reload Window
```

**Issue: Logs Not Showing**

- Check Debug Console is open (View → Debug Console)
- Verify device is selected
- Try restarting debug session
- Check logcat extension is running

**Issue: Breakpoints Not Working**

- Ensure running in debug mode (not release)
- Verify breakpoint is on executable line
- Try hot restart (`R` in console)
- Check `dart.debugExternalPackageLibraries` setting

**Issue: Hot Reload Not Working**

- Check for compilation errors
- Try hot restart instead (`R`)
- Verify file is saved
- Check Debug Console for error messages

### Android Studio

#### Built-in Logcat

Android Studio has native logcat support with advanced filtering UI.

**Access**: View → Tool Windows → Logcat

**Features**:

- Visual filter builder
- Regex support
- Color-coded log levels
- Clickable stack traces
- Process filtering
- Tag filtering

#### Setup Steps

1. Open Android Studio
2. Go to View → Tool Windows → Logcat
3. Select your device from dropdown
4. Select your app process
5. Use filter bar to refine logs

#### Filter Examples

- Show only errors: Select "Error" from level dropdown
- Filter by tag: Enter tag name in filter bar
- Regex filter: Use regex: prefix (e.g., `regex:.*Exception.*`)
- Package filter: Select app package from process dropdown

## Troubleshooting Common Issues

### Network Connection Failures

#### Symptoms

- API calls timeout
- "Failed host lookup" errors
- Connection refused messages

#### Log Patterns

```
E/flutter: [Network] Network error for http://...
E/flutter: SocketException: Failed host lookup: 'your-api-domain.com'
E/flutter: Connection refused
```

#### Debug Steps

1. **Check Internet Permission**

   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <uses-permission android:name="android.permission.INTERNET" />
   ```

2. **Verify Network Security Config** (for HTTP)

   ```xml
   <!-- android/app/src/main/res/xml/network_security_config.xml -->
   <network-security-config>
     <domain-config cleartextTrafficPermitted="true">
       <domain includeSubdomains="true">your-api-domain.com</domain>
     </domain-config>
   </network-security-config>
   ```

3. **Test API Accessibility**

   ```bash
   # From your computer
   curl http://your-api-domain.com/api/health

   # From the device
   adb shell curl http://your-api-domain.com/api/health
   ```

4. **Check Logs for Details**
   ```bash
   adb logcat | grep -i "network\|http\|socket"
   ```

### Permission Errors

#### Symptoms

- Features fail silently
- "Permission denied" errors
- Camera/location not working

#### Log Patterns

```
E/PermissionManager: Permission denied for android.permission.CAMERA
E/flutter: PlatformException(PERMISSION_DENIED, ...)
```

#### Debug Steps

1. **Verify Manifest Permissions**

   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   ```

2. **Check Runtime Permission Requests**

   ```dart
   // Ensure permissions are requested at runtime
   final status = await Permission.camera.request();
   if (!status.isGranted) {
     LoggerService.error('Camera permission denied');
   }
   ```

3. **Test on Different Android Versions**

   - Android 6+ requires runtime permissions
   - Android 10+ has scoped storage
   - Android 11+ has additional restrictions

4. **Check Logs**
   ```bash
   adb logcat | grep -i "permission"
   ```

### Build Configuration Issues

#### Symptoms

- App crashes on startup
- Missing resources
- "Unable to load asset" errors

#### Log Patterns

```
E/AndroidRuntime: FATAL EXCEPTION: main
E/flutter: Unable to load asset: assets/images/logo.png
E/flutter: MissingPluginException
```

#### Debug Steps

1. **Verify Asset Declarations**

   ```yaml
   # pubspec.yaml
   flutter:
     assets:
       - assets/images/
   ```

2. **Check ProGuard Rules** (release builds)

   ```
   # android/app/proguard-rules.pro
   -keep class io.flutter.app.** { *; }
   -keep class io.flutter.plugin.**  { *; }
   -keep class io.flutter.util.**  { *; }
   -keep class io.flutter.view.**  { *; }
   ```

3. **Verify Native Dependencies**

   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean
   flutter build apk
   ```

4. **Check Logs**
   ```bash
   adb logcat AndroidRuntime:E *:S
   ```

### State Management Errors

#### Symptoms

- UI doesn't update
- "setState() called after dispose()" errors
- Null pointer exceptions

#### Log Patterns

```
E/flutter: setState() called after dispose()
E/flutter: Null check operator used on a null value
E/flutter: Bad state: Cannot add new events after calling close
```

#### Debug Steps

1. **Add Lifecycle Logging**

   ```dart
   @override
   void initState() {
     super.initState();
     LoggerService.debug('Widget initialized', component: 'MapScreen');
   }

   @override
   void dispose() {
     LoggerService.debug('Widget disposing', component: 'MapScreen');
     super.dispose();
   }
   ```

2. **Check Async Operations**

   ```dart
   Future<void> loadData() async {
     try {
       final data = await apiService.fetchData();
       if (mounted) {  // Check if widget is still mounted
         setState(() {
           _data = data;
         });
       }
     } catch (e) {
       LoggerService.error('Failed to load data', error: e);
     }
   }
   ```

3. **Check Logs**
   ```bash
   adb logcat | grep -i "setState\|dispose\|null"
   ```

### Crash Analysis

#### Symptoms

- App closes unexpectedly
- "Unfortunately, app has stopped"
- Immediate crash on launch

#### Log Patterns

```
E/AndroidRuntime: FATAL EXCEPTION: main
E/AndroidRuntime: Process: com.pedroocalado.motorbikeparking, PID: 12345
E/AndroidRuntime: java.lang.RuntimeException: ...
```

#### Debug Steps

1. **Capture Full Stack Trace**

   ```bash
   adb logcat -v threadtime > crash_log.txt
   # Reproduce crash
   # Stop capture (Ctrl+C)
   grep -A 50 "FATAL EXCEPTION" crash_log.txt
   ```

2. **Analyze Stack Trace**

   - Look for your package name in the trace
   - Identify the last method call from your code
   - Check line numbers (if available)

3. **For Release Builds**

   ```bash
   # Capture obfuscated logs
   adb logcat > release_crash.txt

   # Deobfuscate (if symbols available)
   flutter symbolize -i release_crash.txt -d build/app/outputs/mapping/release/
   ```

4. **Common Crash Causes**
   - Null pointer exceptions
   - Missing native libraries
   - Memory issues
   - Threading violations

## Debug vs Release Build Comparison

### Debug Build

#### Characteristics

- Full logging enabled
- No code obfuscation
- Debug symbols included
- Larger APK size (~50-100MB)
- Slower performance
- Easy to debug

#### Build Command

```bash
flutter build apk --debug
```

#### Log Capture

```bash
# Verbose logging available
adb logcat flutter:V *:S

# All app logs visible
adb logcat | grep "MotorbikeParking"
```

#### When to Use

- Development and testing
- Reproducing user-reported issues
- Performance profiling
- Feature development

### Release Build

#### Characteristics

- Minimal logging
- Code obfuscation enabled
- Optimized APK size (~20-40MB)
- Better performance
- Harder to debug
- Production-ready

#### Build Command

```bash
flutter build apk --release
```

#### Log Capture

```bash
# Only errors visible
adb logcat *:E

# Limited app logs
adb logcat | grep -i "error\|exception"
```

#### When to Use

- Production deployment
- Performance testing
- Final QA testing
- App store submission

### Comparison Table

| Feature      | Debug Build | Release Build |
| ------------ | ----------- | ------------- |
| Logging      | Verbose     | Minimal       |
| Obfuscation  | No          | Yes           |
| APK Size     | Large       | Small         |
| Performance  | Slower      | Faster        |
| Debugging    | Easy        | Difficult     |
| Stack Traces | Clear       | Obfuscated    |
| Hot Reload   | Yes         | No            |
| Use Case     | Development | Production    |

### Testing Both Builds

```bash
# Build both versions
flutter build apk --debug
flutter build apk --release

# Install debug build
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Test and capture logs
adb logcat -c
adb logcat -v threadtime > debug_logs.txt
# Test app features
# Stop capture

# Install release build
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Test and capture logs
adb logcat -c
adb logcat -v threadtime > release_logs.txt
# Test same features
# Stop capture

# Compare logs
diff debug_logs.txt release_logs.txt
```

### Enabling Additional Logging in Release

If you need more logs in release builds, modify your logger:

```dart
// lib/services/logger_service.dart
static void debug(String message, {String? component}) {
  // Enable in release for critical debugging
  if (kDebugMode || kProfileMode || kReleaseMode) {  // Add kReleaseMode
    final prefix = component != null ? '[$component]' : '';
    developer.log(
      '$prefix $message',
      name: _tag,
      level: 500,
    );
  }
}
```

**Warning**: Remove this before production deployment to avoid performance impact and log spam.

## Advanced Debugging Techniques

### Automated Log Collection Script

Save as `scripts/start_debug_session.sh`:

```bash
#!/bin/bash

# Configuration
SESSION_NAME="debug_$(date +%Y%m%d_%H%M%S)"
LOG_DIR="logs/$SESSION_NAME"
PACKAGE_NAME="com.pedroocalado.motorbikeparking"

# Create log directory
mkdir -p "$LOG_DIR"

echo "=== Starting Debug Session: $SESSION_NAME ==="

# Capture device info
echo "Capturing device information..."
adb shell getprop > "$LOG_DIR/device_info.txt"
adb shell dumpsys battery > "$LOG_DIR/battery_info.txt"
adb shell df > "$LOG_DIR/storage_info.txt"

# Get app info
echo "Capturing app information..."
adb shell dumpsys package $PACKAGE_NAME > "$LOG_DIR/app_info.txt"

# Clear old logs
echo "Clearing old logs..."
adb logcat -c

# Start log capture
echo "Starting log capture..."
adb logcat -v threadtime > "$LOG_DIR/logcat_full.txt" &
LOGCAT_PID=$!

echo ""
echo "Debug session started!"
echo "Logs saving to: $LOG_DIR"
echo ""
echo "Now:"
echo "1. Launch the app"
echo "2. Reproduce your issue"
echo "3. Press Enter when done"
echo ""
read -p "Press Enter to stop logging..."

# Stop log capture
echo "Stopping log capture..."
kill $LOGCAT_PID

# Analyze logs
echo "Analyzing logs..."
./scripts/analyze_logs.sh "$LOG_DIR/logcat_full.txt" > "$LOG_DIR/analysis.txt"

# Create summary
echo "Creating session summary..."
cat > "$LOG_DIR/README.txt" << EOF
Debug Session: $SESSION_NAME
Date: $(date)
Device: $(adb shell getprop ro.product.model)
Android: $(adb shell getprop ro.build.version.release)

Files:
- logcat_full.txt: Complete log capture
- analysis.txt: Automated log analysis
- device_info.txt: Device properties
- battery_info.txt: Battery status
- storage_info.txt: Storage information
- app_info.txt: App package information

To view errors:
grep -i "error" logcat_full.txt

To view exceptions:
grep -i "exception" logcat_full.txt

To view network issues:
grep -i "network" logcat_full.txt | grep -i "error"
EOF

echo ""
echo "=== Debug Session Complete ==="
echo "Session saved to: $LOG_DIR"
echo "View analysis: cat $LOG_DIR/analysis.txt"
echo ""
```

Make it executable:

```bash
chmod +x scripts/start_debug_session.sh
```

### Log Analysis Script

Already created at `scripts/analyze_logs.sh` - use it to quickly find issues:

```bash
./scripts/analyze_logs.sh logcat.txt
```

### Continuous Log Monitoring

Monitor logs in real-time with automatic filtering:

```bash
# Watch for errors
watch -n 1 'adb logcat -d -t 50 *:E'

# Watch for specific component
adb logcat | grep --line-buffered "Network" | while read line; do
  echo "$(date '+%H:%M:%S') $line"
done
```

### Remote Debugging

Debug devices not physically connected:

```bash
# On device, enable WiFi debugging
adb tcpip 5555

# From computer on same network
adb connect <device-ip>:5555

# Verify connection
adb devices

# Now use normal adb commands
adb logcat
```

## Best Practices

### Do's

✅ Clear logs before starting a new debug session
✅ Use appropriate log levels (don't capture verbose in production)
✅ Save logs to files for later analysis
✅ Include device and app version info with logs
✅ Use component tags to organize logs
✅ Test on multiple Android versions
✅ Compare debug and release build behavior
✅ Use automated scripts for consistent log collection

### Don'ts

❌ Don't log sensitive user data (passwords, tokens, emails)
❌ Don't leave verbose logging enabled in release builds
❌ Don't ignore warnings (they often lead to errors)
❌ Don't test only on debug builds
❌ Don't share raw logs without sanitizing PII
❌ Don't rely solely on IDE debugging (test real APKs)
❌ Don't forget to check ProGuard rules for release builds

### Security Considerations

When logging:

```dart
// ✅ Good - log IDs only
LoggerService.info('User logged in: ${user.id}');

// ❌ Bad - logs PII
LoggerService.info('User logged in: ${user.email}');

// ✅ Good - sanitize API responses
LoggerService.logNetworkResponse(200, url);

// ❌ Bad - logs full response with potential PII
LoggerService.info('Response: ${response.body}');
```

## Quick Reference Card

```bash
# Essential Commands
adb devices                    # Check connection
adb logcat -c                  # Clear logs
adb logcat *:E                 # Show errors only
adb logcat flutter:V *:S       # Show Flutter logs only
adb install -r app.apk         # Install APK
adb shell am start -n PKG/.MainActivity  # Launch app

# Common Filters
adb logcat | grep -i "error"           # Find errors
adb logcat | grep -i "exception"       # Find exceptions
adb logcat | grep -i "network"         # Find network logs
adb logcat | grep "MotorbikeParking"   # Find app logs

# Save Logs
adb logcat > logs.txt                  # Save all logs
adb logcat -d > logs.txt               # Dump and save
adb logcat -v threadtime > logs.txt    # Save with timestamps

# Analysis
grep -i "error" logs.txt               # Find errors in file
grep -A 10 "FATAL" logs.txt            # Show 10 lines after fatal
./scripts/analyze_logs.sh logs.txt     # Automated analysis
```

## Getting Help

If you're still stuck after following this guide:

1. Check the [Flutter documentation](https://flutter.dev/docs/testing/debugging)
2. Review the [Android logcat documentation](https://developer.android.com/studio/command-line/logcat)
3. Search for your specific error message
4. Share sanitized logs with the team (remove PII first)

## Additional Resources

- [Flutter Debugging Guide](https://flutter.dev/docs/testing/debugging)
- [Android Logcat Documentation](https://developer.android.com/studio/command-line/logcat)
- [ADB Command Reference](https://developer.android.com/studio/command-line/adb)
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools/overview)
