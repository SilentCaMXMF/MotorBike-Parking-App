# Migration Todo List: Firestore → SQL on Raspberry Pi

**Goal:** Migrate from Firebase Firestore to a local MariaDB/MySQL database running on a Raspberry Pi

**Status:** Not Started  
**Estimated Time:** 2-3 weeks  
**Priority:** HIGH

---

## Phase 1: Raspberry Pi Database Setup (Week 1)

### 1.1 Raspberry Pi Preparation

- [ ] **1.1.1** Update Raspberry Pi OS to latest version

  - Run: `sudo apt update && sudo apt upgrade -y`
  - Reboot if kernel updated
  - _Reference: `tasks/subtasks/setup-sql-on-pi/01-update-raspberry-pi-os.md`_

- [ ] **1.1.2** Install MariaDB Server

  - Run: `sudo apt install mariadb-server mariadb-client -y`
  - Verify installation: `mysql --version`
  - _Reference: `tasks/subtasks/setup-sql-on-pi/02-install-mariadb-server.md`_

- [ ] **1.1.3** Start and Enable MariaDB Service

  - Run: `sudo systemctl start mariadb`
  - Run: `sudo systemctl enable mariadb`
  - Check status: `sudo systemctl status mariadb`
  - _Reference: `tasks/subtasks/setup-sql-on-pi/03-start-enable-mariadb-service.md`_

- [ ] **1.1.4** Run MariaDB Secure Installation
  - Run: `sudo mysql_secure_installation`
  - Set root password
  - Remove anonymous users
  - Disallow root login remotely
  - Remove test database
  - _Reference: `tasks/subtasks/setup-sql-on-pi/04-run-mariadb-secure-installation.md`_

### 1.2 Database Creation

- [ ] **1.2.1** Create Database

  - Login: `sudo mysql -u root -p`
  - Run: `CREATE DATABASE motorbike_parking_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
  - Verify: `SHOW DATABASES;`
  - _Reference: `tasks/subtasks/setup-sql-on-pi/05-create-database.md`_

- [ ] **1.2.2** Create Database User

  - Run: `CREATE USER 'motorbike_app'@'%' IDENTIFIED BY 'secure_password_here';`
  - Replace 'secure_password_here' with strong password
  - Store password securely (password manager)
  - _Reference: `tasks/subtasks/setup-sql-on-pi/06-create-database-user.md`_

- [ ] **1.2.3** Grant Privileges
  - Run: `GRANT SELECT, INSERT, UPDATE, DELETE ON motorbike_parking_app.* TO 'motorbike_app'@'%';`
  - Run: `FLUSH PRIVILEGES;`
  - Verify: `SHOW GRANTS FOR 'motorbike_app'@'%';`
  - _Reference: `tasks/subtasks/setup-sql-on-pi/07-grant-privileges.md`_

### 1.3 Schema Import

- [ ] **1.3.1** Transfer schema.sql to Raspberry Pi

  - Use SCP: `scp schema.sql pi@<raspberry-pi-ip>:~/`
  - Or use USB drive if no network

- [ ] **1.3.2** Import Database Schema

  - Run: `mysql -u root -p motorbike_parking_app < schema.sql`
  - Check for errors in output
  - _Reference: `tasks/subtasks/setup-sql-on-pi/08-import-database-schema.md`_

- [ ] **1.3.3** Verify Schema Import

  - Login: `mysql -u motorbike_app -p motorbike_parking_app`
  - Run: `SHOW TABLES;`
  - Expected: users, parking_zones, user_reports, report_images, schema_version
  - Run: `SELECT * FROM schema_version;`
  - Expected: version 1.0.0

- [ ] **1.3.4** Test Triggers

  - Insert test parking zone
  - Insert test user report
  - Verify occupancy auto-updates
  - Clean up test data

- [ ] **1.3.5** Test Stored Procedures
  - Run: `CALL GetNearbyParkingZones(38.7223, -9.1393, 5.0, 10);`
  - Verify procedure executes without errors

### 1.4 Network Configuration

- [ ] **1.4.1** Configure Firewall (if enabled)

  - Allow MySQL port: `sudo ufw allow 3306/tcp`
  - Or configure specific IP ranges
  - _Reference: `tasks/subtasks/setup-sql-on-pi/10-configure-firewall.md`_

- [ ] **1.4.2** Configure MariaDB for Remote Access

  - Edit: `sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf`
  - Change `bind-address = 127.0.0.1` to `bind-address = 0.0.0.0`
  - Restart: `sudo systemctl restart mariadb`

- [ ] **1.4.3** Test Remote Connection

  - From development machine: `mysql -h <raspberry-pi-ip> -u motorbike_app -p`
  - Verify connection successful
  - _Reference: `tasks/subtasks/setup-sql-on-pi/09-test-database-connection.md`_

- [ ] **1.4.4** Set Up Static IP (Recommended)
  - Configure router to assign static IP to Raspberry Pi
  - Or configure static IP on Raspberry Pi
  - Document IP address for API configuration

### 1.5 Backup Configuration

- [ ] **1.5.1** Create Backup Script

  - Create: `~/backup_db.sh`
  - Add: `mysqldump -u motorbike_app -p motorbike_parking_app > backup_$(date +%Y%m%d_%H%M%S).sql`
  - Make executable: `chmod +x ~/backup_db.sh`

- [ ] **1.5.2** Set Up Automated Backups
  - Add to crontab: `crontab -e`
  - Daily backup: `0 2 * * * ~/backup_db.sh`
  - Weekly cleanup of old backups

---

## Phase 2: Backend API Development (Week 1-2)

### 2.1 API Framework Setup

- [ ] **2.1.1** Choose Backend Framework

  - **Option A**: Node.js + Express + mysql2
  - **Option B**: Python + FastAPI + mysql-connector-python
  - **Option C**: Dart + Shelf + mysql1
  - Document decision and rationale

- [ ] **2.1.2** Create API Project Structure

  ```
  backend/
  ├── src/
  │   ├── routes/
  │   ├── controllers/
  │   ├── models/
  │   ├── middleware/
  │   └── utils/
  ├── config/
  ├── tests/
  ├── .env.example
  └── package.json (or requirements.txt)
  ```

- [ ] **2.1.3** Set Up Database Connection Pool

  - Create database connection module
  - Implement connection pooling
  - Add connection error handling
  - Test connection to Raspberry Pi database

- [ ] **2.1.4** Configure Environment Variables
  - Create `.env` file
  - Add: DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
  - Add: JWT_SECRET, API_PORT
  - Add `.env` to `.gitignore`

### 2.2 Authentication Endpoints

- [ ] **2.2.1** Implement User Registration

  - POST `/api/auth/register`
  - Hash passwords with bcrypt
  - Insert into `users` table
  - Return JWT token

- [ ] **2.2.2** Implement User Login

  - POST `/api/auth/login`
  - Verify password hash
  - Generate JWT token
  - Return user data + token

- [ ] **2.2.3** Implement Anonymous Login

  - POST `/api/auth/anonymous`
  - Create anonymous user in database
  - Generate JWT token
  - Return token

- [ ] **2.2.4** Implement JWT Middleware

  - Verify JWT tokens on protected routes
  - Extract user ID from token
  - Handle expired tokens
  - Handle invalid tokens

- [ ] **2.2.5** Implement Password Reset (Optional)
  - POST `/api/auth/reset-password`
  - Generate reset token
  - Send email (or skip for MVP)

### 2.3 Parking Zone Endpoints

- [ ] **2.3.1** Get Nearby Parking Zones

  - GET `/api/parking/nearby?lat=...&lng=...&radius=...`
  - Call `GetNearbyParkingZones` stored procedure
  - Return parking zones with availability
  - Add pagination support

- [ ] **2.3.2** Get Specific Parking Zone

  - GET `/api/parking/:id`
  - Query `parking_zone_availability` view
  - Include recent reports
  - Return 404 if not found

- [ ] **2.3.3** Create Parking Zone (Admin)

  - POST `/api/parking`
  - Validate coordinates
  - Insert into `parking_zones` table
  - Require admin authentication

- [ ] **2.3.4** Update Parking Zone (Admin)
  - PUT `/api/parking/:id`
  - Update capacity, location, etc.
  - Validate data
  - Require admin authentication

### 2.4 Report Endpoints

- [ ] **2.4.1** Create User Report

  - POST `/api/reports`
  - Call `CreateUserReport` stored procedure
  - Validate reported_count
  - Trigger auto-updates occupancy (via trigger)
  - Return report ID

- [ ] **2.4.2** Get Reports for Zone

  - GET `/api/reports?spotId=...`
  - Query `user_reports` table
  - Filter by time range
  - Include user info (anonymized)

- [ ] **2.4.3** Get User's Report History
  - GET `/api/reports/me`
  - Filter by authenticated user
  - Include parking zone info
  - Paginate results

### 2.5 Image Upload Endpoints

- [ ] **2.5.1** Upload Report Image

  - POST `/api/reports/:id/images`
  - Accept multipart/form-data
  - Validate image format (JPEG, PNG)
  - Validate file size (max 5MB)
  - Store file on Raspberry Pi filesystem
  - Insert metadata into `report_images` table
  - Return image URL

- [ ] **2.5.2** Serve Images

  - GET `/api/images/:filename`
  - Serve from filesystem
  - Add caching headers
  - Resize on-the-fly (optional)

- [ ] **2.5.3** Delete Image (Admin)
  - DELETE `/api/images/:id`
  - Remove from filesystem
  - Remove from database
  - Require admin authentication

### 2.6 API Security & Validation

- [ ] **2.6.1** Implement Rate Limiting

  - Use express-rate-limit or equivalent
  - Limit: 100 requests per 15 minutes per IP
  - Stricter limits for write operations

- [ ] **2.6.2** Add Input Validation

  - Validate all request parameters
  - Sanitize user inputs
  - Return 400 for invalid data
  - Use validation library (Joi, Zod, etc.)

- [ ] **2.6.3** Add CORS Configuration

  - Allow Flutter app origin
  - Configure allowed methods
  - Handle preflight requests

- [ ] **2.6.4** Add Request Logging

  - Log all API requests
  - Include timestamp, method, path, user
  - Use Winston or similar logger

- [ ] **2.6.5** Add Error Handling Middleware
  - Catch all errors
  - Return consistent error format
  - Log errors
  - Don't expose internal details

### 2.7 API Testing

- [ ] **2.7.1** Write Unit Tests

  - Test database queries
  - Test validation logic
  - Test authentication logic
  - Aim for 80%+ coverage

- [ ] **2.7.2** Write Integration Tests

  - Test complete API flows
  - Test with test database
  - Test error scenarios

- [ ] **2.7.3** Test on Raspberry Pi
  - Deploy API to Raspberry Pi
  - Test from external network
  - Test performance under load
  - Monitor resource usage

### 2.8 API Documentation

- [ ] **2.8.1** Document All Endpoints

  - Use Swagger/OpenAPI
  - Include request/response examples
  - Document error codes
  - Document authentication

- [ ] **2.8.2** Create API README
  - Setup instructions
  - Environment variables
  - Running locally
  - Deployment instructions

---

## Phase 3: Flutter App Migration (Week 2-3)

### 3.1 Create API Service Layer

- [ ] **3.1.1** Create API Client Class

  - Create `lib/services/api_service.dart`
  - Use `http` or `dio` package
  - Add base URL configuration
  - Add request/response interceptors

- [ ] **3.1.2** Implement Authentication Methods

  - `signUp(email, password)`
  - `signIn(email, password)`
  - `signInAnonymously()`
  - Store JWT token securely (flutter_secure_storage)

- [ ] **3.1.3** Implement Token Management
  - Auto-attach token to requests
  - Handle token expiration
  - Refresh token logic (if implemented)
  - Clear token on logout

### 3.2 Replace Firestore Service

- [ ] **3.2.1** Create SQL Service Class

  - Create `lib/services/sql_service.dart`
  - Replace `FirestoreService` methods
  - Keep same method signatures for easy migration

- [ ] **3.2.2** Implement Parking Zone Methods

  - `getParkingZones(lat, lng, radius)` → API call
  - `getParkingZone(id)` → API call
  - Remove `setParkingZone` (admin only)

- [ ] **3.2.3** Implement Report Methods

  - `addUserReport(report)` → API call
  - `getRecentReports(spotId)` → API call
  - Remove direct database access

- [ ] **3.2.4** Implement Image Upload
  - `uploadImage(file, reportId)` → API call
  - Use multipart request
  - Show upload progress
  - Handle upload errors

### 3.3 Update UI Components

- [ ] **3.3.1** Update MapScreen

  - Replace Firestore stream with polling or WebSocket
  - Update markers from API data
  - Handle loading states
  - Handle error states

- [ ] **3.3.2** Update ReportingDialog

  - Fix duplicate code bug
  - Update to use API service
  - Add proper error handling
  - Add loading indicators

- [ ] **3.3.3** Update AuthScreen
  - Update to use API service
  - Handle API error responses
  - Update success/error messages

### 3.4 Remove Firebase Dependencies

- [ ] **3.4.1** Remove Firebase Packages

  - Remove from `pubspec.yaml`:
    - firebase_core
    - firebase_auth
    - cloud_firestore
    - firebase_storage
  - Run: `flutter pub get`

- [ ] **3.4.2** Remove Firebase Configuration Files

  - Delete `lib/firebase_options.dart`
  - Delete `google-services.json` (Android)
  - Delete `GoogleService-Info.plist` (iOS)

- [ ] **3.4.3** Update Android Configuration

  - Remove Firebase plugins from `android/build.gradle`
  - Remove google-services plugin
  - Clean build: `flutter clean`

- [ ] **3.4.4** Update iOS Configuration
  - Remove Firebase pods from `ios/Podfile`
  - Run: `cd ios && pod install`

### 3.5 Add Real-time Updates (Optional)

- [ ] **3.5.1** Choose Real-time Strategy

  - **Option A**: Polling (simple, works everywhere)
  - **Option B**: WebSockets (real-time, more complex)
  - **Option C**: Server-Sent Events (one-way real-time)

- [ ] **3.5.2** Implement Polling (if chosen)

  - Poll `/api/parking/nearby` every 30 seconds
  - Only when map is visible
  - Cancel when app backgrounded

- [ ] **3.5.3** Implement WebSocket (if chosen)
  - Add WebSocket endpoint to API
  - Connect from Flutter app
  - Subscribe to parking zone updates
  - Handle reconnection

### 3.6 Configuration Management

- [ ] **3.6.1** Create Environment Config

  - Create `lib/config/environment.dart`
  - Add API base URL
  - Support dev/staging/prod environments

- [ ] **3.6.2** Update .env File
  - Add: `API_BASE_URL=http://<raspberry-pi-ip>:3000`
  - Add: `API_TIMEOUT=30000`
  - Load in main.dart

### 3.7 Testing

- [ ] **3.7.1** Update Unit Tests

  - Mock API service instead of Firestore
  - Update test expectations
  - Ensure all tests pass

- [ ] **3.7.2** Update Widget Tests

  - Mock API responses
  - Test loading states
  - Test error states

- [ ] **3.7.3** Manual Testing
  - Test complete user flows
  - Test on real devices
  - Test with slow network
  - Test offline behavior

---

## Phase 4: Data Migration (Week 3)

### 4.1 Export Firestore Data

- [ ] **4.1.1** Export Users

  - Use Firebase Admin SDK or console
  - Export to JSON
  - Store securely

- [ ] **4.1.2** Export Parking Zones

  - Export all parking zones
  - Include all fields
  - Save as JSON

- [ ] **4.1.3** Export User Reports

  - Export all reports
  - Include timestamps
  - Save as JSON

- [ ] **4.1.4** Export Images
  - Download all images from Firebase Storage
  - Maintain folder structure
  - Note: May be large, plan storage

### 4.2 Transform Data

- [ ] **4.2.1** Create Migration Script

  - Create `scripts/migrate_data.py` (or .js)
  - Read JSON exports
  - Transform to SQL format

- [ ] **4.2.2** Handle User Data

  - Map Firebase UIDs to SQL UUIDs
  - Keep mapping table for reports
  - Hash passwords (if migrating from Firebase Auth)

- [ ] **4.2.3** Handle Parking Zones

  - Generate UUIDs
  - Map Firestore IDs to SQL IDs
  - Validate coordinates

- [ ] **4.2.4** Handle Reports
  - Map user IDs and spot IDs
  - Convert timestamps
  - Validate data

### 4.3 Import to SQL

- [ ] **4.3.1** Import Users

  - Run migration script for users
  - Verify count matches
  - Check for errors

- [ ] **4.3.2** Import Parking Zones

  - Run migration script for zones
  - Verify locations
  - Check constraints

- [ ] **4.3.3** Import Reports

  - Run migration script for reports
  - Verify foreign keys
  - Check triggers fired correctly

- [ ] **4.3.4** Import Images
  - Copy images to Raspberry Pi
  - Insert metadata into database
  - Update file paths

### 4.4 Verification

- [ ] **4.4.1** Verify Data Counts

  - Compare Firestore vs SQL counts
  - Check for missing data
  - Investigate discrepancies

- [ ] **4.4.2** Verify Data Integrity

  - Check foreign key relationships
  - Verify occupancy calculations
  - Test stored procedures with real data

- [ ] **4.4.3** Verify Images
  - Check all images accessible
  - Verify file paths correct
  - Test image serving

---

## Phase 5: Deployment & Monitoring (Week 3)

### 5.1 API Deployment

- [ ] **5.1.1** Set Up Process Manager

  - Install PM2: `npm install -g pm2`
  - Or use systemd service
  - Configure auto-restart

- [ ] **5.1.2** Configure API to Start on Boot

  - PM2: `pm2 startup`
  - PM2: `pm2 save`
  - Or create systemd service file

- [ ] **5.1.3** Set Up Reverse Proxy (Optional)

  - Install nginx
  - Configure proxy to API
  - Add SSL certificate (Let's Encrypt)

- [ ] **5.1.4** Configure Domain/DNS (Optional)
  - Set up dynamic DNS (if home network)
  - Point domain to Raspberry Pi IP
  - Configure port forwarding on router

### 5.2 Monitoring Setup

- [ ] **5.2.1** Set Up Database Monitoring

  - Monitor disk space
  - Monitor query performance
  - Set up alerts for issues

- [ ] **5.2.2** Set Up API Monitoring

  - Monitor API response times
  - Monitor error rates
  - Set up health check endpoint

- [ ] **5.2.3** Set Up Logging
  - Configure log rotation
  - Set up centralized logging (optional)
  - Monitor logs for errors

### 5.3 App Deployment

- [ ] **5.3.1** Update App Configuration

  - Set production API URL
  - Update app version
  - Test on staging first

- [ ] **5.3.2** Build Release APK/IPA

  - Android: `flutter build apk --release`
  - iOS: `flutter build ios --release`
  - Test release builds

- [ ] **5.3.3** Deploy to Users
  - Gradual rollout recommended
  - Monitor for issues
  - Have rollback plan ready

### 5.4 Post-Migration

- [ ] **5.4.1** Monitor Performance

  - Check API response times
  - Monitor database performance
  - Check Raspberry Pi resource usage

- [ ] **5.4.2** Monitor Errors

  - Check API error logs
  - Check database errors
  - Fix issues as they arise

- [ ] **5.4.3** Gather User Feedback

  - Monitor app reviews
  - Check for bug reports
  - Address critical issues quickly

- [ ] **5.4.4** Optimize as Needed
  - Add database indexes if slow
  - Optimize API queries
  - Scale if needed

### 5.5 Cleanup

- [ ] **5.5.1** Disable Firebase Services

  - Stop Firestore writes
  - Keep read-only for backup
  - Eventually delete Firebase project

- [ ] **5.5.2** Update Documentation

  - Document new architecture
  - Update setup instructions
  - Document API endpoints

- [ ] **5.5.3** Archive Old Code
  - Create git branch for Firebase version
  - Tag release
  - Clean up unused code

---

## Rollback Plan

If migration fails or has critical issues:

### Immediate Rollback

- [ ] Revert app to previous version (Firebase)
- [ ] Re-enable Firebase services
- [ ] Notify users of temporary issue

### Data Rollback

- [ ] Keep Firestore data until migration proven stable
- [ ] Don't delete Firebase project for 30 days
- [ ] Have backup of SQL database before migration

---

## Success Criteria

Migration is complete when:

- ✅ All users can authenticate via API
- ✅ All parking zones visible on map
- ✅ Users can submit reports successfully
- ✅ Images upload and display correctly
- ✅ Real-time updates working (polling or WebSocket)
- ✅ No critical bugs for 1 week
- ✅ Performance acceptable (API < 500ms response time)
- ✅ Database stable (no crashes, no data loss)

---

## Resources & References

### Documentation

- MariaDB Documentation: https://mariadb.com/kb/en/
- MySQL Documentation: https://dev.mysql.com/doc/
- Flutter HTTP Package: https://pub.dev/packages/http
- JWT.io: https://jwt.io/

### Existing Project Files

- `schema.sql` - Complete database schema
- `DATABASE_README.md` - Database documentation
- `migrate.sh` - Migration script
- `tasks/subtasks/setup-sql-on-pi/` - Raspberry Pi setup guides
- `tasks/subtasks/migrate-to-sql-db/` - Migration guides

### Tools Needed

- MySQL Workbench (database management)
- Postman or Insomnia (API testing)
- PM2 (process management)
- Git (version control)

---

## Notes & Considerations

### Security

- Use HTTPS in production (Let's Encrypt)
- Never expose database directly to internet
- Use strong passwords for database
- Implement rate limiting on API
- Validate all inputs server-side

### Performance

- Raspberry Pi 4 recommended (4GB+ RAM)
- Use SSD instead of SD card for better performance
- Monitor disk space (images can grow large)
- Consider image compression/resizing

### Networking

- Static IP recommended for Raspberry Pi
- Port forwarding required if accessing from internet
- Consider VPN for secure access
- Dynamic DNS if home IP changes

### Backup

- Daily automated database backups
- Weekly full system backups
- Store backups off-site (cloud storage)
- Test restore process regularly

---

**Last Updated:** November 11, 2025  
**Status:** Ready to begin Phase 1
