# Implementation Plan

- [x] 1. Set up project dependencies and configuration

  - Add dio package (^5.4.0) to pubspec.yaml for HTTP client
  - Add flutter_secure_storage package (^9.0.0) for JWT token storage
  - Create lib/config/environment.dart for environment configuration
  - Create .env file with API_BASE_URL and API_TIMEOUT settings
  - Create .env.example file with sample configuration values
  - _Requirements: 1.1, 1.3, 18.1, 18.2, 19.1, 19.2_

- [x] 2. Implement API Client class

  - [x] 2.1 Create ApiService class with singleton pattern

    - Create lib/services/api_service.dart file
    - Implement singleton pattern with factory constructor
    - Initialize Dio client with base URL from environment configuration
    - Add timeout configuration from environment settings
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 2.2 Implement request and response interceptors

    - Add request interceptor to attach JWT tokens to authenticated requests
    - Add request interceptor for common headers (Content-Type, etc.)
    - Add response interceptor for logging responses
    - Add error interceptor to handle 401 (token expiration) and transform errors
    - Implement \_transformError method for user-friendly error messages
    - _Requirements: 1.4, 1.5, 3.1, 3.2, 3.5_

  - [x] 2.3 Implement token management methods

    - Implement saveToken method using flutter_secure_storage
    - Implement getToken method to retrieve stored JWT
    - Implement clearToken method for logout
    - _Requirements: 2.4, 2.5, 3.1, 3.4_

  - [x] 2.4 Implement authentication methods

    - Implement signUp method that calls POST /api/auth/register
    - Implement signIn method that calls POST /api/auth/login
    - Implement signInAnonymously method that calls POST /api/auth/anonymous
    - Implement signOut method that clears token and calls logout endpoint
    - Store JWT token after successful authentication
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 2.5 Implement generic HTTP methods
    - Implement get method with query parameters support
    - Implement post method with request body support
    - Implement put method with request body support
    - Implement delete method
    - Implement uploadFile method for multipart form data with progress tracking
    - _Requirements: 1.1, 1.4, 1.5_

- [x] 3. Implement SQL Service class

  - [x] 3.1 Create SqlService class structure

    - Create lib/services/sql_service.dart file
    - Implement singleton pattern with factory constructor
    - Inject ApiService dependency
    - _Requirements: 4.1, 4.2, 4.4_

  - [x] 3.2 Implement parking zone methods

    - Implement getParkingZones method that calls GET /api/parking/nearby
    - Accept latitude, longitude, radius, and limit parameters
    - Parse API response and return List<ParkingZone>
    - Implement getParkingZone method that calls GET /api/parking/:id
    - Parse API response and return ParkingZone object
    - Handle errors and throw user-friendly exceptions
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 3.3 Implement user report methods

    - Implement addUserReport method that calls POST /api/reports
    - Accept UserReport model parameter and convert to API request format
    - Return report ID from API response
    - Implement getRecentReports method that calls GET /api/reports
    - Accept spotId and hours parameters
    - Parse API response and return List<UserReport>
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

  - [x] 3.4 Implement image upload method
    - Implement uploadImage method that calls POST /api/reports/:id/images
    - Accept File and reportId parameters
    - Use multipart request format via ApiService.uploadFile
    - Support upload progress callback
    - Return image URL from API response
    - Handle upload errors appropriately
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 4. Implement polling service for real-time updates

  - Create lib/services/polling_service.dart file
  - Implement PollingService class with Timer-based polling
  - Implement startPolling method with latitude, longitude, onUpdate, and onError callbacks
  - Implement stopPolling method to cancel timer
  - Set default poll interval to 30 seconds
  - Ensure proper cleanup to prevent memory leaks
  - _Requirements: 15.1, 15.4, 16.1, 16.4, 16.5_

- [x] 5. Update MapScreen to use API with polling

  - [x] 5.1 Replace Firestore stream with polling implementation

    - Remove StreamBuilder for Firestore getParkingZones stream
    - Add PollingService instance to MapScreen state
    - Implement \_startPolling method that calls PollingService.startPolling
    - Add state variables for \_parkingZones, \_isLoading, and \_error
    - Update UI to use state variables instead of stream snapshot
    - _Requirements: 8.1, 8.2, 16.1_

  - [x] 5.2 Implement app lifecycle handling

    - Add WidgetsBindingObserver mixin to MapScreen state
    - Override didChangeAppLifecycleState method
    - Stop polling when app is paused/backgrounded
    - Resume polling when app returns to foreground
    - Properly dispose observer in dispose method
    - _Requirements: 16.2, 16.3_

  - [x] 5.3 Add loading and error state handling
    - Display CircularProgressIndicator when \_isLoading is true
    - Display error message and retry button when \_error is not null
    - Update markers on map when \_parkingZones updates
    - Clear error state on successful data fetch
    - _Requirements: 8.3, 8.4, 8.5_

- [x] 6. Update ReportingDialog to use API service

  - [x] 6.1 Fix duplicate code bug

    - Review current ReportingDialog implementation for duplicate report submission code
    - Consolidate duplicate code into single \_submitReport method
    - Remove redundant code paths
    - _Requirements: 9.1_

  - [x] 6.2 Replace Firestore calls with SqlService

    - Replace FirestoreService().addUserReport with SqlService().addUserReport
    - Replace FirestoreService().uploadImage with SqlService().uploadImage
    - Update error handling to work with API errors
    - _Requirements: 9.2_

  - [x] 6.3 Add loading indicators and error handling
    - Add \_isSubmitting state variable
    - Display loading indicator during report submission
    - Add \_uploadProgress state variable for image upload progress
    - Display upload progress bar when uploading image
    - Add \_error state variable for error messages
    - Display error message in dialog when submission fails
    - Add retry capability for failed submissions
    - _Requirements: 9.3, 9.4, 9.5_

- [x] 7. Update AuthScreen to use API authentication

  - Replace AuthService().signUp with ApiService().signUp
  - Replace AuthService().signIn with ApiService().signIn
  - Replace AuthService().signInAnonymously with ApiService().signInAnonymously
  - Update error handling to display API error messages
  - Update success flow to navigate to MapScreen after successful authentication
  - Maintain same UI/UX as Firebase implementation
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 8. Comment out Firebase packages in pubspec.yaml

  - Add comment block explaining Firebase is preserved for scaling
  - Comment out firebase_core package dependency
  - Comment out firebase_auth package dependency
  - Comment out cloud_firestore package dependency
  - Comment out firebase_storage package dependency
  - Run flutter pub get to update dependencies
  - Verify app builds successfully without Firebase packages
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 9. Comment out Firebase configuration files

  - Add comment to lib/firebase_options.dart explaining it's preserved for scaling
  - Comment out Firebase initialization in lib/main.dart
  - Keep google-services.json file but document it's not used
  - Keep GoogleService-Info.plist file but document it's not used
  - Verify app builds successfully without Firebase initialization
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [x] 10. Comment out Android Firebase configuration

  - Open android/build.gradle and comment out Firebase plugin classpath
  - Open android/app/build.gradle and comment out google-services plugin
  - Add comment blocks explaining Firebase is preserved for scaling
  - Run flutter clean to clear build cache
  - Build Android APK to verify successful build without Firebase
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [ ] 11. Comment out iOS Firebase configuration

  - Open ios/Podfile and comment out Firebase pod references
  - Add comment block explaining Firebase is preserved for scaling
  - Run pod install in ios directory to update pods
  - Verify ios/Pods directory does not contain Firebase pods
  - Build iOS app to verify successful build without Firebase
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

- [ ] 12. Comment out FirestoreService implementation

  - Add comment block at top of lib/services/firestore_service.dart
  - Comment out entire FirestoreService class implementation
  - Add note explaining how to rollback to Firebase
  - Keep file in project for future scaling needs
  - Update any imports that reference FirestoreService
  - _Requirements: 4.5_

- [ ] 13. Implement connection state handling

  - Add connectivity_plus package to pubspec.yaml
  - Create connection state monitoring in MapScreen
  - Display offline indicator when connection is lost
  - Remove offline indicator when connection is restored
  - Queue failed operations for retry when connection restored
  - Handle connection state changes gracefully in UI
  - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5_

- [ ] 14. Update unit tests to mock API service

  - [ ]\* 14.1 Create mock API service

    - Create mock_api_service.dart in test/mocks directory
    - Update existing tests to use MockApiService instead of MockFirestoreService
    - Update test expectations to match API response format
    - _Requirements: 20.1, 20.2_

  - [ ]\* 14.2 Write unit tests for authentication methods

    - Test signUp method with mocked API responses
    - Test signIn method with mocked API responses
    - Test signInAnonymously method with mocked API responses
    - _Requirements: 20.1, 20.2_

  - [ ]\* 14.3 Write unit tests for parking zone methods

    - Test getParkingZones method with mocked API responses
    - Test getParkingZone method with mocked API responses
    - _Requirements: 20.1, 20.2_

  - [ ]\* 14.4 Write unit tests for report methods
    - Test addUserReport method with mocked API responses
    - Test getRecentReports method with mocked API responses
    - Test uploadImage method with mocked API responses
    - Ensure all unit tests pass
    - _Requirements: 20.1, 20.2_

- [ ] 15. Update widget tests for UI components

  - [ ]\* 15.1 Update MapScreen widget tests

    - Update MapScreen tests to mock SqlService instead of FirestoreService
    - Test loading state displays CircularProgressIndicator
    - Test error state displays error message and retry button
    - _Requirements: 20.3, 20.4_

  - [ ]\* 15.2 Update ReportingDialog widget tests

    - Update ReportingDialog tests to mock SqlService
    - Test loading indicator during report submission
    - Test error message display on failed submission
    - _Requirements: 20.3, 20.4_

  - [ ]\* 15.3 Update AuthScreen widget tests
    - Update AuthScreen tests to mock ApiService
    - Test loading states and error handling
    - Ensure all widget tests pass
    - _Requirements: 20.3, 20.4, 20.5_
