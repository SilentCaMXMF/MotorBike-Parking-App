# Error Scenario Test Execution Log

**Test Date:** November 17, 2024  
**Device ID:** 21da46c9  
**App Package:** com.pedroocalado.motorbikeparking  
**Tester:** [Your name]

---

## Test Environment

- Device connected: ✅
- App installed: ✅
- Logcat running: ✅
- Backend URL: http://192.168.1.67:3000

---

## Baseline Observation

Before testing error scenarios, observed normal operation:

- App is polling every 30 seconds
- Getting 200 responses from backend
- However, there's a parsing error: "Invalid response format: expected list, got Null"
- This indicates the backend response format may need investigation

---

## Scenario 1: Airplane Mode (Offline) - READY TO TEST

**Instructions:**

1. Enable airplane mode on your device (swipe down, tap airplane icon)
2. Wait 10-15 seconds
3. Observe the app behavior
4. Check for error messages
5. Disable airplane mode
6. Document results below

**What to look for:**

- Does the app show an offline indicator?
- Is there an error message about no internet?
- Does a retry button appear?
- Check logs for "connectivity" or "offline" messages

**Results:**

- [ ] Test completed
- [ ] Offline detected
- [ ] Error message shown
- [ ] Retry button visible
- [ ] Logs captured

**Notes:**
[Add your observations here]

---

## Scenario 2: Invalid Token - READY TO TEST

**Instructions:**

1. Stop the app completely
2. Run: `adb shell pm clear com.pedroocalado.motorbikeparking`
3. Launch the app
4. Try to navigate to the map without logging in
5. Document results below

**What to look for:**

- Does the app detect missing authentication?
- Is there a prompt to log in?
- Check logs for "No authentication token" message

**Results:**

- [ ] Test completed
- [ ] Missing token detected
- [ ] Auth prompt shown
- [ ] Logs captured

**Notes:**
[Add your observations here]

---

## Scenario 3: Backend 404 Error - REQUIRES CODE CHANGE

**Instructions:**
This test requires temporarily modifying the code.

**Option A: Modify endpoint (recommended)**

1. Edit `lib/services/sql_service.dart`
2. Change line ~60: `final response = await _dio.get('/api/parking/nearby');`
   To: `final response = await _dio.get('/api/parking/nonexistent');`
3. Save and rebuild: `flutter build apk --debug`
4. Install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
5. Launch app and observe
6. Revert changes after test

**Option B: Modify backend**

1. Temporarily disable the `/api/parking/nearby` endpoint
2. Test the app
3. Re-enable endpoint

**What to look for:**

- 404 error in logs
- Error message to user
- Retry button

**Results:**

- [ ] Test completed
- [ ] 404 error received
- [ ] Error message shown
- [ ] Retry button visible
- [ ] Logs captured

**Notes:**
[Add your observations here]

---

## Scenario 4: Backend 500 Error - REQUIRES BACKEND CHANGE

**Instructions:**

1. Modify backend to return 500 for `/api/parking/nearby`
2. Restart backend
3. Launch app and observe
4. Revert backend changes

**What to look for:**

- 500 error in logs
- Server error message to user
- Retry button

**Results:**

- [ ] Test completed
- [ ] 500 error received
- [ ] Error message shown
- [ ] Retry button visible
- [ ] Logs captured

**Notes:**
[Add your observations here]

---

## Scenario 5: Network Timeout - REQUIRES CODE CHANGE

**Instructions:**

1. Edit `lib/services/api_service.dart`
2. Find the Dio configuration (around line 20-30)
3. Change timeout values to very short:
   ```dart
   connectTimeout: const Duration(milliseconds: 100),
   receiveTimeout: const Duration(milliseconds: 100),
   ```
4. Rebuild: `flutter build apk --debug`
5. Install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
6. Launch app and observe
7. Revert changes after test

**What to look for:**

- Timeout error in logs
- "Request timed out" message
- Retry button

**Results:**

- [ ] Test completed
- [ ] Timeout occurred
- [ ] Error message shown
- [ ] Retry button visible
- [ ] Logs captured

**Notes:**
[Add your observations here]

---

## Scenario 6: Retry Button - READY TO TEST

**Instructions:**

1. Trigger any error (easiest: enable airplane mode)
2. Verify error message and retry button appear
3. Fix the issue (disable airplane mode)
4. Tap the retry button
5. Verify zones load successfully

**What to look for:**

- Retry button is visible and tappable
- Tapping retry shows loading indicator
- Zones load after retry
- Logs show new polling attempt

**Results:**

- [ ] Test completed
- [ ] Retry button visible
- [ ] Retry button works
- [ ] Zones load after retry
- [ ] Logs captured

**Notes:**
[Add your observations here]

---

## Summary

**Scenarios Completed:** 0/6  
**Scenarios Passed:** 0/6  
**Scenarios Failed:** 0/6  
**Scenarios Skipped:** 0/6

### Key Findings

1. [Finding 1]
2. [Finding 2]
3. [Finding 3]

### Issues Discovered

1. Baseline parsing error: "Invalid response format: expected list, got Null"
2. [Issue 2]
3. [Issue 3]

### Recommendations

1. Investigate the parsing error before proceeding with other tests
2. [Recommendation 2]
3. [Recommendation 3]

---

## Log Files Generated

- Baseline: `debug_sessions/baseline_logs_[timestamp].log`
- Scenario 1: `debug_sessions/scenario1_offline_[timestamp].log`
- Scenario 2: `debug_sessions/scenario2_token_[timestamp].log`
- Scenario 3: `debug_sessions/scenario3_404_[timestamp].log`
- Scenario 4: `debug_sessions/scenario4_500_[timestamp].log`
- Scenario 5: `debug_sessions/scenario5_timeout_[timestamp].log`
- Scenario 6: `debug_sessions/scenario6_retry_[timestamp].log`

---

## Next Steps

1. [ ] Complete all 6 scenarios
2. [ ] Analyze all log files
3. [ ] Fill out detailed results in ERROR_SCENARIO_TEST_RESULTS.md
4. [ ] Address any critical issues found
5. [ ] Update main DEBUG_SESSION document
6. [ ] Mark task 8 as complete
