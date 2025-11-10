# Migrate to SQL DB on Raspberry Pi

Objective: Replace Firebase with SQL database on Raspberry Pi for data storage and authentication in the Motorbike Parking App.

Status legend: [ ] todo, [~] in-progress, [x] done

Tasks
- [ ] 01 — Design SQL database schema for users, parking zones, reports, and images → `01-design-sql-database-schema.md`
- [ ] 02 — Set up SQL database (MariaDB/MySQL) on Raspberry Pi → `02-setup-sql-database-on-raspberry-pi.md`
- [ ] 03 — Create backend API server on Raspberry Pi (Node.js/Express or Python/FastAPI) → `03-create-backend-api-server.md`
- [ ] 04 — Implement user authentication in backend API → `04-implement-user-authentication.md`
- [ ] 05 — Implement CRUD operations for parking zones and availability → `05-implement-crud-operations.md`
- [ ] 06 — Implement report submission and retrieval → `06-implement-report-operations.md`
- [ ] 07 — Set up image storage and serving on Raspberry Pi → `07-setup-image-storage.md`
- [ ] 08 — Update Flutter models to match new API data structures → `08-update-flutter-models.md`
- [ ] 09 — Replace Firebase Auth with API-based authentication in Flutter → `09-replace-firebase-auth.md`
- [ ] 10 — Replace Firestore with API calls for data operations in Flutter → `10-replace-firestore.md`
- [ ] 11 — Replace Firebase Storage with API for image uploads in Flutter → `11-replace-firebase-storage.md`
- [ ] 12 — Update notification service to work without Firebase → `12-update-notification-service.md`
- [ ] 13 — Remove Firebase dependencies from pubspec.yaml → `13-remove-firebase-dependencies.md`
- [ ] 14 — Test full integration between Flutter app and Raspberry Pi backend → `14-test-integration.md`

Dependencies
- 02 depends on 01
- 03 depends on 02
- 04 depends on 03
- 05 depends on 03
- 06 depends on 03
- 07 depends on 03
- 08 depends on 01
- 09 depends on 04,08
- 10 depends on 05,08
- 11 depends on 07,08
- 12 depends on 03
- 13 depends on 09,10,11
- 14 depends on all

Exit criteria
- The app successfully connects to the Raspberry Pi SQL database for all data operations
- Authentication works via API without Firebase
- Reports and images are stored and retrieved from RPi
- No Firebase dependencies remain in the codebase
- Full functionality tested and working on both Android and iOS