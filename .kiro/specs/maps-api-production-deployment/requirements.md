# Requirements Document

## Introduction

This specification addresses the Maps API response format inconsistency between the backend API and Flutter frontend. The backend code has been updated locally to return a consistent `{ data: [...] }` format, but these changes have not been deployed to the production server (192.168.1.67:3000). The Flutter app is currently unable to load parking zones because the production API still returns the old format with inconsistent keys (`zones`, `reports`, `report`, `zone`).

## Glossary

- **Backend API**: Node.js/Express server running on Raspberry Pi at 192.168.1.67:3000
- **Flutter Frontend**: Mobile application that consumes the Backend API
- **Production Server**: Raspberry Pi server at 192.168.1.67 hosting the Backend API
- **Local Backend**: Development instance of Backend API running on localhost:3000
- **Response Format**: JSON structure returned by API endpoints
- **Parking Zones**: Geographic locations where motorbike parking is available
- **API Endpoint**: HTTP route that handles specific requests (e.g., `/api/parking/nearby`)
- **Deployment**: Process of transferring code changes from development to production environment

## Requirements

### Requirement 1: Backend API Response Format Consistency

**User Story:** As a Flutter app developer, I want all API endpoints to return data in a consistent format, so that I can reliably parse responses without handling multiple formats.

#### Acceptance Criteria

1. WHEN the Flutter Frontend requests parking zones from `/api/parking/nearby`, THE Backend API SHALL return a response with a `data` key containing an array of parking zones
2. WHEN the Flutter Frontend requests a specific parking zone from `/api/parking/:id`, THE Backend API SHALL return a response with a `data` key containing a single parking zone object
3. WHEN the Flutter Frontend creates a report via `/api/reports`, THE Backend API SHALL return a response with a `data` key containing the created report object
4. WHEN the Flutter Frontend requests zone reports from `/api/reports`, THE Backend API SHALL return a response with a `data` key containing an array of reports
5. WHEN the Flutter Frontend uploads an image via `/api/reports/:reportId/images`, THE Backend API SHALL return a response with a `data` key containing the image metadata

### Requirement 2: Production Deployment Verification

**User Story:** As a system administrator, I want to verify that code changes are successfully deployed to production, so that I can ensure the application functions correctly in the live environment.

#### Acceptance Criteria

1. WHEN deployment completes, THE Production Server SHALL serve the updated Backend API code with standardized response format
2. WHEN a test request is made to the Production Server endpoint `/api/parking/nearby`, THE Backend API SHALL return a response containing the `data` key
3. WHEN the deployment verification script runs, THE Backend API SHALL respond with HTTP status 200 and valid JSON containing the `data` key
4. WHEN the Backend API process restarts on Production Server, THE Backend API SHALL load the latest code from the git repository
5. WHEN the Flutter Frontend connects to Production Server, THE Flutter Frontend SHALL successfully parse parking zone data without format errors

### Requirement 3: Database Schema Validation

**User Story:** As a backend developer, I want to ensure the database schema matches the API expectations, so that queries return data in the correct structure for the standardized response format.

#### Acceptance Criteria

1. WHEN the Backend API queries the `parking_zones` table, THE Database SHALL return records with fields: `id`, `latitude`, `longitude`, `total_capacity`, `current_occupancy`, `confidence_score`, `last_updated`
2. WHEN the Backend API calls the `GetNearbyParkingZones` stored procedure, THE Database SHALL return a result set with parking zone records including calculated `distance_km` field
3. WHEN the Backend API queries the `parking_zone_availability` view, THE Database SHALL return records with computed `available_slots` field
4. WHEN the Backend API inserts a user report, THE Database triggers SHALL update the corresponding parking zone's `current_occupancy` and `confidence_score` fields
5. WHEN the Backend API queries user reports, THE Database SHALL return records with fields: `id`, `spot_id`, `user_id`, `reported_count`, `timestamp`, `user_latitude`, `user_longitude`

### Requirement 4: Frontend Error Handling

**User Story:** As a mobile app user, I want clear error messages when the app cannot load parking data, so that I understand what went wrong and how to resolve it.

#### Acceptance Criteria

1. WHEN the Flutter Frontend receives a response without the `data` key, THE Flutter Frontend SHALL display an error message indicating "Invalid response format"
2. WHEN the Flutter Frontend encounters a network timeout, THE Flutter Frontend SHALL display an error message with prefix "TIMEOUT:" and provide a retry button
3. WHEN the Flutter Frontend receives a 401 or 403 status code, THE Flutter Frontend SHALL display an error message with prefix "AUTH:" and prompt the user to log in again
4. WHEN the Flutter Frontend cannot connect to the Backend API, THE Flutter Frontend SHALL display an error message with prefix "NETWORK:" and suggest checking internet connection
5. WHEN the Flutter Frontend encounters a parsing error, THE Flutter Frontend SHALL display an error message with prefix "PARSING:" and log detailed error information for debugging

### Requirement 5: Deployment Automation

**User Story:** As a DevOps engineer, I want an automated deployment script, so that I can deploy backend changes to production quickly and reliably without manual steps.

#### Acceptance Criteria

1. WHEN the deployment script executes, THE Deployment Script SHALL test SSH connectivity to the Production Server before proceeding
2. WHEN the deployment script runs, THE Deployment Script SHALL pull the latest code from the git repository on the Production Server
3. WHEN the deployment script updates code, THE Deployment Script SHALL restart the Backend API process on the Production Server
4. WHEN the deployment script completes, THE Deployment Script SHALL verify the Backend API is responding with the correct response format
5. WHEN the deployment script encounters an error, THE Deployment Script SHALL display a clear error message and exit with a non-zero status code
