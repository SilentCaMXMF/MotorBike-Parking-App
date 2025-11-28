# Debug Session Testing Guide

## Overview

This guide walks through testing the parking zones fetch debug logging on a physical device.

## Prerequisites

- Physical Android device connected via USB
- USB debugging enabled on device
- ADB installed and device recognized (`adb devices`)
- Debug APK built and installed

## Testing Procedure

### 1. Prepare the Environment

```bash
# Verify device connection
adb devices

# Install debug APK (if not already installed)
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### 2. Start Log Capture

Option A - Using the capture script:

```bash
./scripts/capture_debug_session.sh
```

Option B - Manual capture:

```bash
# Clear existing logs
adb logcat -c

# Start capturing logs
adb logcat -v time | grep -E "MotorbikeParking|flutter" | tee DEBUG_SESSION_$(date +%Y-%m-%d_%H-%M-%S).log
```

### 3. Execute Test Flow

With log capture running, perform the following on the device:

1. **Launch the app** from the device home screen
2. **Login** with valid credentials
3. **Wait for map to load** completely
4. **Observe parking zones** appearing on the map
5. **Wait 30+ seconds** to observe polling behavior

### 4. Expected Log Sequence

You should see logs in this order:

```
1. MapScreen Initialization
   - "MapScreen: initState called"
   - "MapScreen: Starting location and parking zones initialization"

2. Location Services
   - "MapScreen: Requesting location permission"
   - "MapScreen: Location permission granted"
   - "MapScreen: Getting current location"
   - "MapScreen: Current location obtained: lat=X, lng=Y"

3. Initial Parking Zones Fetch
   - "MapScreen: Starting initial parking zones fetch"
   - "ApiService: fetchParkingZones called"
   - "ApiService: Making GET request to /parking-zones"
   - "ApiService: Response status: 200"
   - "ApiService: Parsed X parking zones"
   - "MapScreen: Received X parking zones"
   - "MapScreen: Creating markers for X zones"

4. Polling Setup
   - "MapScreen: Setting up parking zones polling timer (30s interval)"

5. Subsequent Polls (every 30 seconds)
   - "MapScreen: Polling parking zones (periodic update)"
   - "ApiService: fetchParkingZones called"
   - [Same API sequence as above]
```

### 5. Verify Success Criteria

✅ All log points appear in the correct sequence
✅ No error messages or exceptions
✅ Parking zones data is successfully fetched
✅ Markers appear on the map
✅ Polling occurs every 30 seconds
✅ Location is obtained successfully

### 6. Save Debug Session

After completing the test flow:

1. Stop the log capture (Ctrl+C)
2. Review the captured log file
3. Verify all expected log points are present
4. Save the file with a descriptive name

Example:

```bash
mv DEBUG_SESSION_2024-11-17_14-30-00.log debug_sessions/successful_flow_2024-11-17.log
```

## Troubleshooting

### No Logs Appearing

```bash
# Check if app is running
adb shell ps | grep motorbike

# Try broader filter
adb logcat | grep -i parking

# Check Flutter logs specifically
adb logcat | grep flutter
```

### Device Not Detected

```bash
# Restart ADB server
adb kill-server
adb start-server
adb devices
```

### App Crashes

```bash
# Capture crash logs
adb logcat -v time > crash_log.txt

# Look for stack traces
adb logcat | grep -A 20 "FATAL EXCEPTION"
```

## Log Analysis

### Key Indicators of Success

1. **Initialization**: MapScreen logs appear immediately after app launch
2. **Location**: Permission granted and coordinates obtained
3. **API Call**: Successful 200 response with zone count
4. **Markers**: Confirmation of marker creation
5. **Polling**: Regular 30-second updates

### Common Issues to Look For

- Missing log points (indicates code not executing)
- Error messages in API responses
- Permission denied for location
- Empty parking zones array
- Polling not occurring

## Requirements Coverage

This test validates:

- **1.1**: MapScreen initialization logging
- **1.2**: Location service logging
- **1.3**: Parking zones fetch logging
- **1.4**: API service detailed logging
- **1.5**: Polling mechanism logging

## Next Steps

After successful testing:

1. Document any issues found
2. Compare logs with expected sequence
3. Verify all requirements are met
4. Archive successful debug session logs
5. Update troubleshooting documentation if needed
