# Error Scenario Testing Checklist

**Date:** [Fill in when testing]  
**Device:** [Fill in device model]  
**App Build:** [Fill in build version]

---

## Pre-Test Setup

- [ ] Device connected via USB
- [ ] USB debugging enabled
- [ ] ADB working: `adb devices` shows device
- [ ] App installed: `adb shell pm list packages | grep motorbike`
- [ ] Backend running (if testing backend errors)
- [ ] Log directory exists: `debug_sessions/`

---

## Test Execution Checklist

### ✅ Scenario 1: Airplane Mode (Offline)

**Steps:**
1. [ ] Clear logcat: `adb logcat -c`
2. [ ] Start logging: `adb logcat | grep -E "MotorbikeParking|flutter" > debug_sessions/test1_offline.log &`
3. [ ] Enable airplane mode on device
4. [ ] Launch app
5. [ ] Try to access map screen
6. [ ] Observe error message
7. [ ] Stop logging (Ctrl+C or kill process)

**Verification:**
- [ ] Offline indicator visible in UI
- [ ] Error message displayed: "No internet connection" or similar
- [ ] Retry button present
- [ ] Log contains: "Connectivity status: offline"
- [ ] Log contains: "Cannot fetch parking zones" or similar
- [ ] No crash occurred

**Log file:** `debug_sessions/test1_offline.log`

---

### ✅ Scenario 2: Invalid/Expired Token

**Steps:**
1. [ ] Clear app data: `adb shell pm clear com.pedroocalado.motorbikeparking`
2. [ ] Clear logcat: `adb logcat -c`
3. [ ] Start logging: `adb logcat | grep -E "MotorbikeParking|flutter" > debug_sessions/test2_token.log &`
4. [ ] Launch app
5. [ ] Navigate to map screen without logging in
6. [ ] Observe behavior
7. [ ] Stop logging

**Verification:**
- [ ] App detects missing token
- [ ] Authentication prompt shown OR error message displayed
- [ ] Log contains: "Cannot start polling: No authentication token"
- [ ] Log contains: "No auth token available"
- [ ] App doesn't crash
- [ ] User can navigate to login

**Log file:** `debug_sessions/test2_token.log`

---

### ✅ Scenario 3: Backend 404 Error

**Steps:**
1. [ ] Modify `lib/services/sql_service.dart` endpoint to invalid path
2. [ ] Rebuild app: `flutter build apk --debug`
3. [ ] Install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
4. [ ] Clear logcat: `adb logcat -c`
5. [ ] Start logging: `adb logcat | grep -E "MotorbikeParking|flutter" > debug_sessions/test3_404.log &`
6. [ ] Launch app and log in
7. [ ] Navigate to map screen
8. [ ] Observe error
9. [ ] Stop logging
10. [ ] Revert code changes

**Verification:**
- [ ] Error message displayed
- [ ] Retry button visible
- [ ] Log contains: "404" or "Endpoint not found"
- [ ] Log contains: "Failed to fetch parking zones"
- [ ] App handles error gracefully
- [ ] No crash

**Log file:** `debug_sessions/test3_404.log`

---

### ✅ Scenario 4: Backend 500 Error

**Steps:**
1. [ ] Modify backend to return 500 for `/api/parking/nearby`
2. [ ] Restart backend
3. [ ] Clear logcat: `adb logcat -c`
4. [ ] Start logging: `adb logcat | grep -E "MotorbikeParking|flutter" > debug_sessions/test4_500.log &`
5. [ ] Launch app and log in
6. [ ] Navigate to map screen
7. [ ] Observe error
8. [ ] Stop logging
9. [ ] Revert backend changes

**Verification:**
- [ ] Error message displayed: "Server error" or similar
- [ ] Retry button visible
- [ ] Log contains: "500" or "Internal server error"
- [ ] Log contains: "API error"
- [ ] App handles error gracefully
- [ ] No crash

**Log file:** `debug_sessions/test4_500.log`

---

### ✅ Scenario 5: Network Timeout

**Steps:**
1. [ ] Modify `lib/services/api_service.dart` timeout to very short (e.g., 100ms)
2. [ ] Rebuild app: `flutter build apk --debug`
3. [ ] Install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
4. [ ] Clear logcat: `adb logcat -c`
5. [ ] Start logging: `adb logcat | grep -E "MotorbikeParking|flutter" > debug_sessions/test5_timeout.log &`
6. [ ] Launch app and log in
7. [ ] Navigate to map screen
8. [ ] Wait for timeout
9. [ ] Stop logging
10. [ ] Revert code changes

**Verification:**
- [ ] Timeout error displayed: "Request timed out" or similar
- [ ] Retry button visible
- [ ] Log contains: "Connection timeout" or "DioException"
- [ ] Log contains: "timeout"
- [ ] App handles timeout gracefully
- [ ] No crash

**Log file:** `debug_sessions/test5_timeout.log`

---

### ✅ Scenario 6: Retry Button Functionality

**Steps:**
1. [ ] Clear logcat: `adb logcat -c`
2. [ ] Start logging: `adb logcat | grep -E "MotorbikeParking|flutter" > debug_sessions/test6_retry.log &`
3. [ ] Enable airplane mode
4. [ ] Launch app and navigate to map
5. [ ] Verify error message and retry button appear
6. [ ] Disable airplane mode
7. [ ] Tap retry button
8. [ ] Verify zones load successfully
9. [ ] Stop logging

**Verification:**
- [ ] Retry button visible on error
- [ ] Retry button is tappable
- [ ] Tapping retry shows loading indicator
- [ ] Log contains: "Starting parking zone polling" after retry
- [ ] Zones load successfully after retry
- [ ] Map updates with parking zones
- [ ] No crash during retry

**Log file:** `debug_sessions/test6_retry.log`

---

## Post-Test Analysis

### Log Analysis Commands

```bash
# Check for errors in all test logs
grep -i "error" debug_sessions/test*.log

# Check for connectivity logs
grep -i "connectivity" debug_sessions/test*.log

# Check for polling logs
grep -i "polling" debug_sessions/test*.log

# Check for API logs
grep -i "api" debug_sessions/test*.log

# Check for crashes
grep -i "fatal\|crash\|exception" debug_sessions/test*.log
```

### Summary

**Total Scenarios:** 6  
**Completed:** [ ] / 6  
**Passed:** [ ] / 6  
**Failed:** [ ] / 6

### Issues Found

1. [Issue description]
2. [Issue description]
3. [Issue description]

### Recommendations

1. [Recommendation]
2. [Recommendation]
3. [Recommendation]

---

## Next Steps

- [ ] Review all log files
- [ ] Fill out `ERROR_SCENARIO_TEST_RESULTS.md` with detailed findings
- [ ] Address any failed scenarios
- [ ] Update main DEBUG_SESSION document
- [ ] Mark task 8 as complete
- [ ] Proceed to task 9

---

## Quick Commands Reference

```bash
# Check device connection
adb devices

# Clear app data
adb shell pm clear com.pedroocalado.motorbikeparking

# Clear logcat
adb logcat -c

# Start logcat capture
adb logcat | grep -E "MotorbikeParking|flutter" > debug_sessions/test.log &

# Stop logcat (get PID first)
ps aux | grep "adb logcat"
kill [PID]

# Build debug APK
flutter build apk --debug

# Install APK
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# View recent logs
tail -f debug_sessions/test.log

# Search logs
grep -i "error" debug_sessions/test.log
```
