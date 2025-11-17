# APK Troubleshooting Plan - Guest Login "null" Error

## Issue

Guest account login returns "null" error after installing new APK build.

## Troubleshooting Steps

### Step 1: Capture Logs (2 minutes)

Run logcat with filters to see the error:

```bash
# Option A: Focused on Flutter and API
adb logcat -c && adb logcat | grep -E "flutter|DioException|API SERVICE|ERROR"

# Option B: Full Flutter logs
adb logcat -c && adb logcat *:E flutter:V

# Option C: Save to file for analysis
adb logcat -c && adb logcat > app_logs.txt
```

**What to look for:**

- API SERVICE INITIALIZATION lines (should show production URL)
- REQUEST/RESPONSE logs for /api/auth/anonymous
- Any DioException or error messages
- Stack traces

### Step 2: Verify Server is Running (1 minute)

```bash
# Check if server is accessible
curl http://192.168.1.67:3000/health

# Test anonymous endpoint directly
curl -X POST http://192.168.1.67:3000/api/auth/anonymous
```

**Expected**: Should return token and user object

### Step 3: Check API Response Parsing (if server works)

The issue might be in how the app parses the response. Check:

**File**: `lib/services/api_service.dart` - `signInAnonymously()` method

Look for:

- Response structure mismatch
- Missing null checks
- JSON parsing errors

### Step 4: Add Debug Logging

If logs aren't clear, add more logging to `lib/services/api_service.dart`:

```dart
Future<AuthResponse> signInAnonymously() async {
  try {
    print('=== ANONYMOUS LOGIN START ===');
    final response = await post('/api/auth/anonymous');
    print('Response status: ${response.statusCode}');
    print('Response data: ${response.data}');

    final authResponse = AuthResponse.fromJson(response.data['data']);
    print('Parsed auth response: ${authResponse.token}');

    await saveToken(authResponse.token);
    print('Token saved successfully');

    return authResponse;
  } catch (e) {
    print('=== ANONYMOUS LOGIN ERROR ===');
    print('Error type: ${e.runtimeType}');
    print('Error message: $e');
    rethrow;
  }
}
```

### Step 5: Check Response Structure

The API returns:

```json
{
  "message": "Anonymous user created",
  "user": {...},
  "token": "..."
}
```

But the code expects:

```dart
AuthResponse.fromJson(response.data['data'])
```

**Potential Issue**: Response might not have a 'data' wrapper!

### Step 6: Quick Fix (if response structure is wrong)

Update `lib/services/api_service.dart`:

```dart
// BEFORE:
final authResponse = AuthResponse.fromJson(response.data['data']);

// AFTER (if no 'data' wrapper):
final authResponse = AuthResponse.fromJson(response.data);
```

---

## Diagnostic Commands

### Check App is Installed

```bash
adb shell pm list packages | grep motorbike
```

### Check App Permissions

```bash
adb shell dumpsys package com.example.motorbike_parking_app | grep permission
```

### Clear App Data (fresh start)

```bash
adb shell pm clear com.example.motorbike_parking_app
```

### Reinstall APK

```bash
adb uninstall com.example.motorbike_parking_app
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Most Likely Issues

### 1. Response Structure Mismatch (80% probability)

**Symptom**: "null" error  
**Cause**: API response doesn't have 'data' wrapper  
**Fix**: Remove `['data']` from response parsing

### 2. Network Issue (10% probability)

**Symptom**: Connection error  
**Cause**: Phone not on same network  
**Fix**: Ensure phone on WiFi 192.168.1.x

### 3. Server Not Running (5% probability)

**Symptom**: Timeout or connection refused  
**Cause**: Server crashed or stopped  
**Fix**: Restart server on Pi

### 4. Token Parsing Error (5% probability)

**Symptom**: Null token  
**Cause**: AuthResponse.fromJson fails  
**Fix**: Add null checks and better error handling

---

## Quick Test Script

```bash
#!/bin/bash
echo "=== APK Troubleshooting ==="
echo ""
echo "1. Checking server..."
curl -s http://192.168.1.67:3000/health && echo "✅ Server OK" || echo "❌ Server DOWN"
echo ""
echo "2. Testing anonymous login..."
curl -s -X POST http://192.168.1.67:3000/api/auth/anonymous | jq .
echo ""
echo "3. Checking phone connection..."
adb devices
echo ""
echo "4. Starting logcat (Ctrl+C to stop)..."
adb logcat -c
adb logcat | grep -E "flutter|DioException|API SERVICE"
```

---

## Next Steps

1. **Run logcat** and paste the output
2. **Test server** with curl
3. **Identify the issue** from logs
4. **Apply fix** based on findings
5. **Rebuild and test**

---

_Start with Step 1 - capture the logs and we'll diagnose from there!_
