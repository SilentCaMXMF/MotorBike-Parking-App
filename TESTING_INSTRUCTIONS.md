# Testing Instructions - Task 7: Debug Logging Verification

## Overview

This document provides complete instructions for testing the debug logging implementation on a physical Android device.

## What Has Been Prepared

✅ Debug APK built: `build/app/outputs/flutter-apk/app-debug.apk`  
✅ APK installed on device (ID: 21da46c9)  
✅ Testing scripts created  
✅ Documentation prepared  
✅ Debug sessions directory created

## Quick Start (Recommended)

### Option 1: Automated Script

```bash
./scripts/capture_debug_session.sh
```

Then on your device:
1. Launch the Motorbike Parking app
2. Login with your credentials
3. Wait for the map to load
4. Observe parking zones appearing
5. Wait at least 30 seconds to see polling in action

Press `Ctrl+C` when done to stop logging.

### Option 2: Manual Commands

```bash
# Clear previous logs
adb logcat -c

# Start capturing (save to file)
adb logcat -v time | grep -E "MotorbikeParking|flutter" | tee debug_sessions/session_$(date +%Y%m%d_%H%M%S).log
```

Then perform the same device actions as above.

## What to Look For

### Expected Log Sequence

Your logs should show this flow:

```
1. App Launch
   ✓ MapScreen: initState called
   ✓ MapScreen: Starting location and parking zones initialization

2. Location Setup
   ✓ MapScreen: Requesting location permission
   ✓ MapScreen: Location permission granted
   ✓ MapScreen: Getting current location
   ✓ MapScreen: Current location obtained: lat=X, lng=Y

3. Initial Data Fetch
   ✓ MapScreen: Starting initial parking zones fetch
   ✓ ApiService: fetchParkingZones called
   ✓ ApiService: Making GET request to /parking-zones
   ✓ ApiService: Response status: 200
   ✓ ApiService: Parsed X parking zones
   ✓ MapScreen: Received X parking zones
   ✓ MapScreen: Creating markers for X zones

4. Polling Setup
   ✓ MapScreen: Setting up parking zones polling timer (30s interval)

5. Periodic Updates (every 30 seconds)
   ✓ MapScreen: Polling parking zones (periodic update)
   ✓ [API call sequence repeats]
```

### Success Criteria

- [ ] All log points appear in correct order
- [ ] No error messages or exceptions
- [ ] Parking zones successfully fetched (count > 0)
- [ ] Markers appear on the map visually
- [ ] Polling occurs every 30 seconds
- [ ] Location coordinates are obtained

## Documenting Results

After testing, document your findings:

1. Copy `DEBUG_SESSION_TEMPLATE.md` to a new file:
   ```bash
   cp DEBUG_SESSION_TEMPLATE.md debug_sessions/results_$(date +%Y%m%d_%H%M%S).md
   ```

2. Fill in the template with your test results

3. Check off each requirement:
   - Requirement 1.1: MapScreen initialization logging
   - Requirement 1.2: Location service logging
   - Requirement 1.3: Parking zones fetch logging
   - Requirement 1.4: API service detailed logging
   - Requirement 1.5: Polling mechanism logging

## Helpful Resources

- **Detailed Guide**: `docs/DEBUG_SESSION_GUIDE.md`
- **Quick Reference**: `docs/QUICK_TEST_REFERENCE.md`
- **Results Template**: `DEBUG_SESSION_TEMPLATE.md`
- **Session Archive**: `debug_sessions/`

## Troubleshooting

### No Logs Appearing

```bash
# Try broader filter
adb logcat | grep -i parking

# Or check all Flutter logs
adb logcat | grep flutter
```

### Device Connection Issues

```bash
# Restart ADB
adb kill-server
adb start-server
adb devices
```

### App Not Responding

```bash
# Check if app is running
adb shell ps | grep motorbike

# View crash logs
adb logcat | grep -A 20 "FATAL EXCEPTION"
```

## Next Steps After Testing

1. ✅ Verify all log points are present
2. ✅ Confirm requirements are met
3. ✅ Save successful session logs
4. ✅ Document any issues found
5. ✅ Mark task as complete

## Requirements Validation

This test validates all requirements from the spec:

- **1.1**: Comprehensive logging in MapScreen initialization
- **1.2**: Location service operations logging
- **1.3**: Parking zones fetch operations logging
- **1.4**: Detailed API service logging
- **1.5**: Polling mechanism logging

## Contact

If you encounter issues or need clarification, refer to:
- `docs/DEBUGGING.md` - General debugging guide
- `TROUBLESHOOTING_PLAN.md` - Known issues and solutions

---

**Ready to test?** Run the script or manual commands above and follow the device actions!
