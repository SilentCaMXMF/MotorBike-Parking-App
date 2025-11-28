# Implementation Plan

- [x] 1. Enhance PollingService with lifecycle logging

  - Add logging when `startPolling()` is called with all parameters (latitude, longitude, radius, limit, interval)
  - Add logging when `stopPolling()` is called
  - Add logging in `_fetchParkingZones()` before calling SqlService
  - Add logging when `onUpdate` callback is invoked with zone count
  - Add logging when `onError` callback is invoked with error message
  - Add `_logPollingState()` method to log current polling status (active/inactive)
  - _Requirements: 1.1, 1.2, 3.1, 3.4_

- [x] 2. Enhance SqlService with detailed API logging

  - Add logging at start of `getParkingZones()` with all parameters (lat, lng, radius, limit)
  - Add logging of the API endpoint path being called (`/api/parking/nearby`)
  - Add logging of query parameters being sent to the API
  - Add logging after receiving response with status code and data type
  - Add logging of the number of zones being parsed from response
  - Add enhanced error logging in catch blocks with specific error types (DioException types)
  - Add separate error handling for connection timeout, connection error, 401, 404, and 500 errors
  - _Requirements: 1.3, 1.4, 2.3, 4.2, 4.3, 4.4_

- [x] 3. Enhance ApiService with request/response logging

  - Add logging in `get()` method with complete URL (baseUrl + endpoint)
  - Add logging to verify authentication header presence (without exposing token value)
  - Add logging of request timeout configuration
  - Add logging of response status code before returning
  - Add logging of response data structure type
  - _Requirements: 1.3, 4.1, 4.2_

- [x] 4. Add authentication verification to MapScreen

  - Add method to check if authentication token exists before starting polling
  - Add logging when authentication token is verified
  - Add warning log when authentication token is missing
  - Add error state handling when token is missing (display error message to user)
  - Update `_startPolling()` to call authentication check first
  - _Requirements: 2.4, 3.2, 3.5, 5.5_

- [x] 5. Enhance MapScreen state transition logging

  - Add logging when `_startPolling()` is called with location coordinates
  - Add logging when polling is stopped due to offline status
  - Add logging when zones are received in `onUpdate` callback
  - Add logging when `_updateMarkers()` is called with marker count
  - Add logging when error occurs in `onError` callback
  - Add logging for connectivity state changes (online/offline transitions)
  - _Requirements: 1.1, 1.2, 1.5, 2.1, 2.2, 3.1_

- [x] 6. Improve error handling and user feedback

  - Update error messages in SqlService to be more specific (network vs API vs parsing errors)
  - Add distinct error messages for different failure scenarios (auth, network, API, timeout)
  - Ensure error state in MapScreen exits loading state and displays error UI
  - Verify retry button functionality triggers new polling attempt
  - Add authentication-specific error handling that prompts re-login
  - _Requirements: 2.5, 4.4, 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 7. Test debug logging with APK on physical device

  - Build debug APK with `flutter build apk --debug`
  - Install APK on physical device
  - Clear logcat and start log capture with `adb logcat | grep -E "MotorbikeParking|flutter"`
  - Test normal flow: login → map loads → zones appear
  - Verify all log points appear in sequence (MapScreen init → location → polling → API call → response → markers)
  - Save successful flow logs to debug session file
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 8. Test error scenarios and verify logging

  - Test with airplane mode enabled (offline scenario)
  - Test with invalid/expired authentication token
  - Test with backend endpoint returning 404
  - Test with backend endpoint returning 500
  - Test with network timeout (slow connection)
  - Verify each error scenario produces appropriate logs and user-facing error messages
  - Verify retry button works for each error scenario
  - _Requirements: 2.5, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4_

- [ ] 9. Update DEBUG_SESSION document with findings
  - Document the root cause identified through enhanced logging
  - Add log examples showing the failure point
  - Document the fix applied (if root cause is found)
  - Update recommendations section with next steps
  - Add new debugging commands used during investigation
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
