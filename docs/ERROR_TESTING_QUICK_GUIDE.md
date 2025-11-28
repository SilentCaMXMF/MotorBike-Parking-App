# Error Scenario Testing Quick Guide

## Quick Start

Run the automated test script:

```bash
./scripts/test_error_scenarios.sh
```

Or follow manual steps below for each scenario.

---

## Scenario 1: Airplane Mode (Offline)

**Quick Test:**

```bash
# Enable airplane mode on device, then:
adb logcat -c
adb logcat | grep -E "MotorbikeParking|flutter" > debug_sessions/test_offline.log &
# Launch app, try to access map
# Press Ctrl+C when done
```

**What to verify:**

- Offline indicator appears
- Error message: "No internet connection"
- Logs show: "Connectivity status: offline"

---

## Scenario 2: Invalid Token

**Quick Test:**

```bash
# Clear app data
adb shell pm clear com.pedroocalado.motorbikeparking
adb logcat -c
adb logcat | grep -E "MotorbikeParking|flutter" > debug_sessions/test_token.log &
# Launch app, try to access map without logging in
```

**What to verify:**

- Authentication prompt appears
- Logs show: "Cannot start polling: No authentication token"

---

## Scenario 3: 404 Error

**Quick Test:**
Temporarily modify `lib/services/sql_service.dart`:

```dart
// Change endpoint to non-existent path
final response = await _dio.get('/api/parking/nonexistent');
```

**What to verify:**

- Error message shown
- Retry button appears
- Logs show: "404" or "Endpoint not found"

---

## Scenario 4: 500 Error

**Backend modification needed** - modify backend to return 500

**What to verify:**

- Error message shown
- Retry button appears
- Logs show: "500" or "Server error"

---

## Scenario 5: Network Timeout

**Quick Test:**
Modify `lib/services/api_service.dart` timeout:

```dart
connectTimeout: const Duration(milliseconds: 100), // Very short
```

**What to verify:**

- Timeout error shown
- Retry button appears
- Logs show: "Connection timeout"

---

## Scenario 6: Retry Button

**Quick Test:**

1. Enable airplane mode
2. Launch app → see error
3. Disable airplane mode
4. Tap retry button

**What to verify:**

- Retry button visible on error
- Tapping retry restarts polling
- Zones load after retry

---

## Log Analysis Commands

```bash
# View all error logs
grep -i "error" debug_sessions/test_*.log

# View connectivity logs
grep -i "connectivity" debug_sessions/test_*.log

# View API logs
grep -i "api" debug_sessions/test_*.log

# View polling logs
grep -i "polling" debug_sessions/test_*.log
```

---

## Expected Log Patterns

### Offline:

```
Connectivity status: offline
Cannot fetch parking zones: offline
```

### Invalid Token:

```
Cannot start polling: No authentication token
```

### API Errors:

```
API error: [status code]
Failed to fetch parking zones
```

### Timeout:

```
Connection timeout
DioException: Connection timeout
```

### Retry:

```
Starting parking zone polling
Fetching parking zones for location
```
