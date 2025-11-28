# Implementation Plan

- [x] 1. Create database schema validation script

  - Create `scripts/schema-validator.sh` that connects to production database via SSH
  - Implement checks for table existence (users, parking_zones, user_reports, report_images)
  - Implement checks for view existence (parking_zone_availability, recent_user_reports)
  - Implement checks for stored procedure existence (GetNearbyParkingZones, CreateUserReport)
  - Implement checks for trigger existence (update_occupancy_on_report_insert, update_occupancy_on_report_delete)
  - Add colored output for pass/fail status (✅/❌)
  - Make script executable with `chmod +x`
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 2. Enhance deployment script with validation and rollback

  - [ ] 2.1 Add database schema validation step to `deploy-to-production.sh`

    - Call schema-validator.sh before deployment
    - Exit if schema validation fails
    - _Requirements: 2.1, 3.1_

  - [ ] 2.2 Add code backup functionality

    - Create backup directory with timestamp before deployment
    - Copy current backend code to backup location via SSH
    - Store backup path for potential rollback
    - _Requirements: 2.1_

  - [ ] 2.3 Add rollback capability

    - Implement rollback function that restores backed up code
    - Trigger rollback if deployment verification fails
    - Restart server with old code after rollback
    - Log rollback actions
    - _Requirements: 2.1, 2.4_

  - [ ] 2.4 Add comprehensive endpoint testing

    - Test GET /api/parking/nearby endpoint
    - Test GET /api/parking/:id endpoint (if zone ID available)
    - Test POST /api/reports endpoint (with test credentials)
    - Verify all responses contain 'data' key
    - _Requirements: 2.2, 2.3_

  - [ ] 2.5 Add deployment logging
    - Create logs directory if not exists
    - Log all deployment steps with timestamps
    - Save deployment log to file with timestamp
    - Display log file path at end of deployment
    - _Requirements: 2.1, 2.4_

- [ ] 3. Verify production database schema

  - SSH into production server at 192.168.1.67
  - Run schema-validator.sh script against production database
  - Document any schema discrepancies found
  - Apply schema.sql updates if needed (coordinate with user)
  - Verify all tables, views, procedures, and triggers exist
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 4. Execute production deployment

  - [ ] 4.1 Run pre-deployment checks

    - Verify local backend tests pass with `npm test`
    - Verify local backend serves correct response format
    - Commit all local changes to git
    - _Requirements: 2.1_

  - [ ] 4.2 Execute deployment script

    - Run `./deploy-to-production.sh`
    - Monitor output for any errors
    - Verify each step completes successfully
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ] 4.3 Verify deployment success
    - Check that API returns 'data' key in responses
    - Verify server process is running on production
    - Check server logs for any errors
    - Test multiple API endpoints manually
    - _Requirements: 2.2, 2.3, 2.5_

- [ ] 5. Configure Flutter app for production

  - [ ] 5.1 Update environment configuration

    - Change ENVIRONMENT=development to ENVIRONMENT=production in .env file
    - Verify PROD_API_BASE_URL points to http://192.168.1.67:3000
    - _Requirements: 2.5_

  - [ ] 5.2 Rebuild Flutter application

    - Run `flutter clean` to clear build cache
    - Run `flutter build apk --release` to build production APK
    - Verify build completes without errors
    - _Requirements: 2.5_

  - [ ] 5.3 Install and test on device
    - Install APK on test device via `adb install`
    - Launch app and verify it connects to production API
    - Check that parking zones load on map
    - Verify no "Invalid response format" errors appear
    - _Requirements: 2.5, 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 6. Perform integration testing

  - [ ] 6.1 Test parking zone loading

    - Open app and verify map loads
    - Verify parking zone markers appear on map
    - Check marker colors reflect availability
    - Tap markers to verify info windows display correctly
    - _Requirements: 2.5, 4.1_

  - [ ] 6.2 Test report submission

    - Tap on a parking zone marker
    - Open report dialog
    - Submit a parking count report
    - Verify report is created successfully
    - Check that zone occupancy updates
    - _Requirements: 4.2_

  - [ ] 6.3 Test error handling scenarios

    - Enable airplane mode and verify offline indicator appears
    - Disable airplane mode and verify connection restored message
    - Test retry button functionality
    - Verify appropriate error messages for different error types
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [ ]\* 6.4 Monitor logcat during testing
    - Run `adb logcat | grep -E "flutter|SqlService|ApiService|MapScreen"`
    - Verify no PARSING errors appear
    - Verify successful API responses logged
    - Check for any unexpected errors or warnings
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 7. Update documentation
  - Update MAPS_API_FIX_TODO.md with deployment completion status
  - Mark all completed items with ✅
  - Add deployment timestamp and verification results
  - Document any issues encountered and resolutions
  - Create deployment runbook for future reference
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
