# Requirements Document

## Introduction

This document outlines the requirements for migrating the Flutter mobile application from Firebase (Firestore, Firebase Auth, Firebase Storage) to a custom REST API backend connected to a MariaDB database running on a Raspberry Pi. The migration aims to reduce operational costs, increase data ownership, and maintain feature parity with the existing Firebase-based implementation.

## Glossary

- **Flutter App**: The mobile application built with Flutter framework for iOS and Android
- **API Service**: The REST API backend running on Raspberry Pi that replaces Firebase services
- **JWT**: JSON Web Token used for authentication
- **API Client**: The Dart class in the Flutter app that handles HTTP communication with the API Service
- **SQL Service**: The Flutter service layer that replaces FirestoreService with API calls
- **Parking Zone**: A designated motorcycle parking area with location and capacity information
- **User Report**: User-submitted data about parking spot occupancy
- **Anonymous User**: A user who uses the app without creating an account
- **MapScreen**: The main screen displaying the map with parking zone markers
- **ReportingDialog**: The UI component for submitting parking occupancy reports
- **AuthScreen**: The authentication screen for user login and registration

## Requirements

### Requirement 1: API Client Class

**User Story:** As a developer, I want to create an API Client class in the Flutter app, so that all HTTP communication with the backend is centralized and consistent.

#### Acceptance Criteria

1. THE Flutter App SHALL provide an API Client class at lib/services/api_service.dart
2. THE API Client SHALL use the http or dio package for HTTP requests
3. WHEN the Flutter App initializes, THE API Client SHALL load the base URL from environment configuration
4. THE API Client SHALL implement request interceptors for adding headers and logging
5. THE API Client SHALL implement response interceptors for error handling and logging

### Requirement 2: Authentication Methods

**User Story:** As a user, I want to authenticate using email/password or anonymously through the new API, so that I can access the app features without Firebase.

#### Acceptance Criteria

1. THE API Client SHALL provide a signUp method that accepts email and password parameters
2. THE API Client SHALL provide a signIn method that accepts email and password parameters
3. THE API Client SHALL provide a signInAnonymously method for anonymous authentication
4. WHEN authentication succeeds, THE API Client SHALL store the JWT token using flutter_secure_storage package
5. THE API Client SHALL retrieve stored JWT tokens for authenticated requests

### Requirement 3: Token Management

**User Story:** As a developer, I want automatic token management in the API Client, so that authentication is handled seamlessly throughout the app.

#### Acceptance Criteria

1. THE API Client SHALL automatically attach JWT tokens to all authenticated requests
2. WHEN a JWT token expires, THE API Client SHALL handle token expiration errors
3. IF refresh token logic is implemented, THE API Client SHALL automatically refresh expired tokens
4. WHEN a user logs out, THE API Client SHALL clear the JWT token from secure storage
5. THE API Client SHALL handle missing or invalid token scenarios gracefully

### Requirement 4: SQL Service Class

**User Story:** As a developer, I want to create an SQL Service class that replaces FirestoreService, so that UI components require minimal changes during migration.

#### Acceptance Criteria

1. THE Flutter App SHALL provide an SQL Service class at lib/services/sql_service.dart
2. THE SQL Service SHALL replace all FirestoreService methods with API-based implementations
3. THE SQL Service SHALL maintain the same method signatures as FirestoreService
4. THE SQL Service SHALL use the API Client for all backend communication
5. THE FirestoreService SHALL be commented out but preserved in the codebase for future scaling needs

### Requirement 5: Parking Zone Methods

**User Story:** As a user, I want to view nearby parking zones on the map using data from the new API, so that I can find available parking spots.

#### Acceptance Criteria

1. THE SQL Service SHALL provide a getParkingZones method that accepts latitude, longitude, and radius parameters
2. THE getParkingZones method SHALL call the API Service endpoint for nearby parking zones
3. THE SQL Service SHALL provide a getParkingZone method that accepts a zone ID parameter
4. THE getParkingZone method SHALL call the API Service endpoint for specific zone details
5. THE SQL Service SHALL parse API responses and return ParkingZone model objects

### Requirement 6: User Report Methods

**User Story:** As a user, I want to submit parking occupancy reports through the new API, so that I can contribute to real-time parking availability data.

#### Acceptance Criteria

1. THE SQL Service SHALL provide an addUserReport method that accepts a UserReport model parameter
2. THE addUserReport method SHALL call the API Service endpoint for creating reports
3. THE SQL Service SHALL provide a getRecentReports method that accepts a spot ID parameter
4. THE getRecentReports method SHALL call the API Service endpoint for fetching reports
5. THE SQL Service SHALL remove direct database access methods from the implementation

### Requirement 7: Image Upload Implementation

**User Story:** As a user, I want to upload photos with my parking reports through the new API, so that I can provide visual evidence of parking conditions.

#### Acceptance Criteria

1. THE SQL Service SHALL provide an uploadImage method that accepts a file and report ID parameters
2. THE uploadImage method SHALL use multipart request format for file upload
3. WHEN an image upload is in progress, THE SQL Service SHALL provide upload progress information
4. WHEN an image upload fails, THE SQL Service SHALL return appropriate error information
5. THE uploadImage method SHALL call the API Service endpoint for image uploads

### Requirement 8: MapScreen Updates

**User Story:** As a user, I want the map screen to display parking zones from the new API, so that I can see real-time parking availability.

#### Acceptance Criteria

1. THE MapScreen SHALL replace Firestore stream listeners with polling-based data fetching
2. THE MapScreen SHALL update parking zone markers using data from the SQL Service
3. THE MapScreen SHALL handle loading states while fetching parking zone data
4. THE MapScreen SHALL handle error states when API requests fail
5. THE MapScreen SHALL display user-friendly error messages for failed data fetches

### Requirement 9: ReportingDialog Updates

**User Story:** As a user, I want the reporting dialog to submit reports through the new API, so that my parking reports are saved correctly.

#### Acceptance Criteria

1. THE ReportingDialog SHALL fix the duplicate code bug in the current implementation
2. THE ReportingDialog SHALL use the SQL Service for submitting reports
3. THE ReportingDialog SHALL add proper error handling for failed submissions
4. THE ReportingDialog SHALL display loading indicators during report submission
5. THE ReportingDialog SHALL display success or error messages after submission attempts

### Requirement 10: AuthScreen Updates

**User Story:** As a user, I want the authentication screen to work with the new API, so that I can log in without Firebase.

#### Acceptance Criteria

1. THE AuthScreen SHALL use the API Client for authentication operations
2. THE AuthScreen SHALL handle API error responses appropriately
3. THE AuthScreen SHALL update success messages to reflect API-based authentication
4. THE AuthScreen SHALL update error messages to reflect API-based authentication
5. THE AuthScreen SHALL maintain the same user experience as the Firebase implementation

### Requirement 11: Firebase Package Configuration

**User Story:** As a developer, I want to comment out Firebase packages in pubspec.yaml, so that the app uses the new API but can scale back to Firebase if needed.

#### Acceptance Criteria

1. THE pubspec.yaml file SHALL comment out firebase_core package
2. THE pubspec.yaml file SHALL comment out firebase_auth package
3. THE pubspec.yaml file SHALL comment out cloud_firestore package
4. THE pubspec.yaml file SHALL comment out firebase_storage package
5. WHEN packages are commented out, THE Flutter App SHALL run flutter pub get successfully

### Requirement 12: Firebase Configuration File Preservation

**User Story:** As a developer, I want to keep Firebase configuration files in the project but not use them, so that we can scale back to Firebase if the local backend reaches its limit.

#### Acceptance Criteria

1. THE Flutter App SHALL keep lib/firebase_options.dart file but not import it in active code
2. THE Flutter App SHALL keep google-services.json file in Android configuration
3. THE Flutter App SHALL keep GoogleService-Info.plist file in iOS configuration
4. WHEN Firebase is not active, THE Flutter App SHALL build successfully
5. THE Flutter App SHALL comment out Firebase initialization code in main.dart

### Requirement 13: Android Configuration Updates

**User Story:** As a developer, I want to comment out Firebase plugins from Android configuration, so that Android builds work without Firebase but can be re-enabled.

#### Acceptance Criteria

1. THE android/build.gradle file SHALL comment out Firebase plugin references
2. THE android/app/build.gradle file SHALL comment out google-services plugin
3. WHEN Firebase plugins are commented out, THE Flutter App SHALL run flutter clean successfully
4. WHEN Firebase plugins are commented out, THE Flutter App SHALL build Android APK successfully
5. THE Android configuration SHALL preserve commented Firebase dependencies for future use

### Requirement 14: iOS Configuration Updates

**User Story:** As a developer, I want to comment out Firebase pods from iOS configuration, so that iOS builds work without Firebase but can be re-enabled.

#### Acceptance Criteria

1. THE ios/Podfile SHALL comment out Firebase pod references
2. WHEN Firebase pods are commented out, THE Flutter App SHALL run pod install successfully in ios directory
3. WHEN Firebase pods are commented out, THE Flutter App SHALL build iOS app successfully
4. THE iOS configuration SHALL preserve commented Firebase dependencies for future use
5. THE ios/Pods directory SHALL not contain Firebase-related pods after pod install

### Requirement 15: Real-time Update Strategy

**User Story:** As a developer, I want to choose a real-time update strategy for parking zone data, so that users see current parking availability.

#### Acceptance Criteria

1. THE Flutter App SHALL support polling as a real-time update strategy
2. THE Flutter App SHALL support WebSocket as an alternative real-time update strategy
3. THE Flutter App SHALL document the chosen strategy and rationale
4. THE chosen strategy SHALL provide updates at least every 30 seconds
5. THE chosen strategy SHALL be configurable for different deployment scenarios

### Requirement 16: Polling Implementation

**User Story:** As a user, I want the app to automatically refresh parking data, so that I see current availability without manual refresh.

#### Acceptance Criteria

1. WHEN the map screen is visible, THE Flutter App SHALL poll the API Service every 30 seconds
2. WHEN the app is backgrounded, THE Flutter App SHALL stop polling for updates
3. WHEN the app returns to foreground, THE Flutter App SHALL resume polling for updates
4. THE polling mechanism SHALL handle network errors gracefully
5. THE polling mechanism SHALL not create memory leaks or resource issues

### Requirement 17: Connection State Handling

**User Story:** As a user, I want to know when the app is online or offline, so that I understand why data may not be updating.

#### Acceptance Criteria

1. THE Flutter App SHALL detect online and offline connection states
2. WHEN the connection is lost, THE Flutter App SHALL display an offline indicator
3. WHEN the connection is restored, THE Flutter App SHALL remove the offline indicator
4. WHEN offline, THE Flutter App SHALL queue operations for retry when online
5. THE Flutter App SHALL handle connection state changes gracefully

### Requirement 18: Environment Configuration

**User Story:** As a developer, I want to create environment configuration for API settings, so that I can easily switch between development and production.

#### Acceptance Criteria

1. THE Flutter App SHALL provide an environment configuration file at lib/config/environment.dart
2. THE environment configuration SHALL include API base URL setting
3. THE environment configuration SHALL support development, staging, and production environments
4. THE environment configuration SHALL be loaded during app initialization
5. THE environment configuration SHALL not hardcode sensitive credentials

### Requirement 19: Environment File Updates

**User Story:** As a developer, I want to update the .env file with API configuration, so that environment-specific settings are externalized.

#### Acceptance Criteria

1. THE .env file SHALL include API_BASE_URL configuration
2. THE .env file SHALL include API_TIMEOUT configuration
3. THE .env file SHALL be loaded by the environment configuration module
4. THE .env file SHALL not be committed to version control
5. THE Flutter App SHALL provide a .env.example file with sample values

### Requirement 20: Testing Updates

**User Story:** As a developer, I want to update all tests to work with the new API service layer, so that the test suite validates the migrated implementation.

#### Acceptance Criteria

1. THE test suite SHALL mock the API Service instead of FirestoreService
2. THE test suite SHALL mock API responses for all service methods
3. THE test suite SHALL verify loading states in UI components
4. THE test suite SHALL verify error states in UI components
5. WHEN flutter test runs, THE test suite SHALL have all tests passing
