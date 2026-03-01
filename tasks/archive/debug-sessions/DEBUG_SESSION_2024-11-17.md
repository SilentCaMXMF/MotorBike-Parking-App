# Debug Session - November 17, 2024

## Session Summary
Successfully debugged and fixed authentication issues in the Motorbike Parking App using logcat analysis.

## Issues Identified & Fixed

### 1. ✅ FIXED: Logging Not Visible in Logcat
**Problem:** LoggerService uses `dart:developer` logging which doesn't output to Android logcat
- All application logs were invisible when debugging APKs on physical devices
- Only `print()` statements were visible in logcat

**Root Cause:** `developer.log()` outputs to Flutter DevTools only, not to Android's logcat system

**Temporary Solution:** Added strategic `print()` statements to auth and API flows for debugging
- Added prints in `lib/screens/auth_screen.dart` for authentication flow
- Added prints in `lib/services/api_service.dart` for network requests/responses

**Permanent Solution (Spec Created):** 
- Created spec at `.kiro/specs/fix-flutter-logging/`
- Replace `developer.log()` with `debugPrint()` and `print()` in LoggerService
- This will make all logs visible in logcat for production debugging

### 2. ✅ FIXED: Authentication Response Parsing Error
**Problem:** Login/signup failing with error: `type 'Null' is not a subtype of type 'Map<String, dynamic>'`

**Root Cause:** Backend API response structure mismatch
- **Backend returns:**
  ```json
  {
    "message": "Login successful",
    "user": {
      "id": "de8dd7b3-c35b-11f0-93d3-b827ebb20cfc",
      "email": "pedro.calado@insa.min-saude.pt",
      "isAnonymous": 0,
      "isAdmin": false
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```

- **App expected:**
  ```json
  {
    "data": {
      "token": "...",
      "userId": "...",
      "email": "..."
    }
  }
  ```

**Fix Applied:**
- Updated `AuthResponse.fromJson()` in `lib/services/api_service.dart` to parse backend's actual structure
- Changed from `response.data['data']` to `response.data` (root level)
- Extract user ID from nested `user` object: `user['id']`

**Files Modified:**
- `lib/services/api_service.dart` - Updated AuthResponse parsing logic
- `lib/screens/auth_screen.dart` - Added debug logging

**Test Results:**
- ✅ Login successful with email: `pedro.calado@insa.min-saude.pt`
- ✅ JWT token received and stored
- ✅ Navigation to MapScreen works

## 3. ⚠️ OUTSTANDING ISSUE: Parking Zones Not Fetching

**Problem:** After successful login, parking zones are not being fetched from the API

**Evidence:**
- No API calls to `/api/spots` endpoint visible in logcat
- No network requests from PollingService
- MapScreen loads but shows loading state indefinitely

**Likely Causes:**
1. PollingService not starting after login
2. SqlService not making GET request to fetch parking zones
3. Silent failure in polling/fetching logic

**Next Steps for Investigation:**
- Add debug prints to `lib/services/polling_service.dart`
- Add debug prints to `lib/services/sql_service.dart` 
- Check if `_startPolling()` is being called in MapScreen
- Verify network connectivity check isn't blocking requests
- Check if API endpoint `/api/spots` exists and returns correct format

## Debugging Commands Used

```bash
# Clear logcat
adb logcat -c

# View app logs with filters
adb logcat -d | grep -E "\[AUTH\]|\[API\]|flutter" | tail -200

# View specific process logs
adb logcat -d | grep "18275" | tail -300

# Install debug APK
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Build debug APK
flutter build apk --debug
```

## Backend API Details

**Base URL:** `http://192.168.1.67:3000`

**Endpoints:**
- `POST /api/auth/login` - ✅ Working
- `POST /api/auth/register` - ✅ Working  
- `GET /api/spots` - ⚠️ Not being called

## Configuration

**Environment:** Production (EnvironmentType.production)
**Timeout:** 30000ms
**Device:** Physical Android device (Xiaomi MIUI)

## Recommendations

1. **Immediate:** Add debug logging to parking zone fetch logic
2. **Short-term:** Implement the logging spec to make all logs visible
3. **Long-term:** Add comprehensive error handling for API response mismatches
4. **Testing:** Create integration tests for auth flow with actual backend responses

## Files to Review Next Session

- `lib/services/polling_service.dart` - Check polling logic
- `lib/services/sql_service.dart` - Check spots fetching
- `lib/screens/map_screen.dart` - Verify polling starts after login
- Backend: `backend/src/routes/spots.js` - Verify endpoint exists and format
