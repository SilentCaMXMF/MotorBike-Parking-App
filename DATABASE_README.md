# Motorbike Parking App Database Schema

This directory contains the SQL database schema and migration system for the Motorbike Parking App.

## Files Overview

- `schema.sql` - Complete database schema with tables, views, triggers, and stored procedures
- `migrate.sh` - Migration script for applying and rolling back database changes
- `migrations/` - Directory containing migration files
- `README.md` - This documentation file

## Database Structure

### Core Tables

#### `users`
Stores user authentication and profile information.
- **Primary Key**: UUID (`id`)
- **Fields**: email, password_hash, is_anonymous, is_active, timestamps
- **Indexes**: email, created_at, is_active

#### `parking_zones`
Stores parking location and capacity information.
- **Primary Key**: UUID (`id`)
- **Fields**: google_places_id, coordinates, capacity, occupancy, confidence_score
- **Constraints**: Valid coordinate ranges, capacity/occupancy validation
- **Indexes**: location (lat/lng), google_places_id, last_updated

#### `user_reports`
Stores user-submitted parking availability reports.
- **Primary Key**: UUID (`id`)
- **Foreign Keys**: spot_id → parking_zones, user_id → users
- **Fields**: reported_count, timestamp, user_location, verification status
- **Indexes**: spot_id, user_id, timestamp, is_verified

#### `report_images`
Stores image metadata for user reports.
- **Primary Key**: UUID (`id`)
- **Foreign Key**: report_id → user_reports
- **Fields**: image_url, file_path, file_size, mime_type, dimensions
- **Indexes**: report_id, uploaded_at, is_processed

### Database Views

#### `parking_zone_availability`
Provides real-time parking availability with report statistics.
- Includes available slots calculation
- Aggregates report counts (24h, 1h)
- Filters active zones only

#### `recent_user_reports`
Shows recent reports with user and location information.
- 7-day lookback window
- Includes image counts
- Ordered by timestamp

### Triggers

#### `update_occupancy_on_report_insert`
Automatically updates parking zone occupancy when new reports are added.
- Calculates occupancy from last hour of reports
- Updates confidence score based on report volume
- Refreshes last_updated timestamp

#### `update_occupancy_on_report_delete`
Maintains data integrity when reports are removed.
- Recalculates occupancy and confidence scores
- Updates timestamps

### Stored Procedures

#### `GetNearbyParkingZones(latitude, longitude, radius_km, limit)`
Finds parking zones within specified radius using Haversine formula.
- Returns distance calculation
- Orders by distance and confidence
- Supports result limiting

#### `CreateUserReport(spot_id, user_id, reported_count, user_lat, user_lng)`
Creates new user reports with proper validation.
- Generates UUID for report
- Returns new report ID
- Triggers occupancy updates

## Migration System

The migration system uses the `migrate.sh` script to manage database schema changes.

### Quick Start

1. **Initialize Database** (first time only):
   ```bash
   ./migrate.sh init
   ```

2. **Check Status**:
   ```bash
   ./migrate.sh status
   ```

3. **Apply All Migrations**:
   ```bash
   ./migrate.sh latest up
   ```

### Migration Commands

| Command | Description |
|---------|-------------|
| `./migrate.sh init` | Initialize database with schema.sql |
| `./migrate.sh status` | Show current migration status |
| `./migrate.sh create <version> <description>` | Create new migration template |
| `./migrate.sh latest up` | Apply all pending migrations |
| `./migrate.sh <version> up` | Apply specific migration |
| `./migrate.sh <version> down` | Rollback specific migration |
| `./migrate.sh latest down` | Rollback last applied migration |

### Creating New Migrations

1. Create a new migration:
   ```bash
   ./migrate.sh create 1.0.2 "Add user preferences table"
   ```

2. This creates two files:
   - `migrations/1.0.2.sql` - Migration SQL
   - `migrations/1.0.2_rollback.sql` - Rollback SQL

3. Edit the migration file with your SQL changes:
   ```sql
   -- Migration: 1.0.2
   -- Description: Add user preferences table
   -- Applied: 2025-11-10

   START TRANSACTION;

   CREATE TABLE user_preferences (
       id CHAR(36) NOT NULL DEFAULT (UUID()),
       user_id CHAR(36) NOT NULL,
       preference_key VARCHAR(100) NOT NULL,
       preference_value TEXT NULL,
       created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
       
       PRIMARY KEY (id),
       UNIQUE KEY unique_user_preference (user_id, preference_key),
       FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
   ) ENGINE=InnoDB;

   COMMIT;
   ```

4. Edit the rollback file with reverse operations:
   ```sql
   -- Rollback: 1.0.2
   -- Description: Rollback for: Add user preferences table
   -- Applied: 2025-11-10

   START TRANSACTION;

   DROP TABLE IF EXISTS user_preferences;

   COMMIT;
   ```

5. Apply the migration:
   ```bash
   ./migrate.sh 1.0.2 up
   ```

## Configuration

### Database Connection

Update the configuration variables in `migrate.sh`:

```bash
DB_NAME="motorbike_parking_app"
DB_USER="motorbike_app"
DB_HOST="localhost"
```

### User Permissions

The schema includes commented-out GRANT statements. Uncomment and modify as needed:

```sql
CREATE USER 'motorbike_app'@'%' IDENTIFIED BY 'secure_password_here';
GRANT SELECT, INSERT, UPDATE, DELETE ON motorbike_parking_app.* TO 'motorbike_app'@'%';
FLUSH PRIVILEGES;
```

## Performance Considerations

### Indexes
- All foreign keys are indexed
- Location-based queries use composite indexes on (latitude, longitude)
- Timestamp indexes for time-based queries
- Status indexes for filtering active/verified data

### Partitioning (Optional)
The schema includes commented partitioning for large datasets:

```sql
ALTER TABLE user_reports PARTITION BY RANGE (UNIX_TIMESTAMP(timestamp)) (
    PARTITION p_current VALUES LESS THAN (UNIX_TIMESTAMP('2026-01-01')),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

### Storage Engine
- Uses InnoDB for transaction support and foreign key constraints
- Optimized for UTF-8 with `utf8mb4_unicode_ci` collation
- File-per-table enabled for better maintenance

## Data Integrity

### Constraints
- Coordinate validation (latitude: -90 to 90, longitude: -180 to 180)
- Capacity/occupancy relationships
- Positive values for counts and sizes
- UUID primary keys for distributed systems

### Foreign Keys
- All relationships properly constrained
- CASCADE delete for dependent data
- UPDATE CASCADE for UUID changes

### Transactions
- All migrations wrapped in transactions
- Rollback on failure
- Stored procedures use transactions

## Security

### Password Storage
- User passwords stored as hashes (not plain text)
- Anonymous users supported with NULL passwords

### Access Control
- Application user with limited privileges
- Schema separation from other databases

### Data Validation
- Input validation at database level
- Type checking and constraints
- Proper escaping in application layer

## Monitoring and Maintenance

### Schema Version Tracking
The `schema_version` table tracks all applied migrations:

```sql
SELECT * FROM schema_version ORDER BY applied_at DESC;
```

### Performance Monitoring
Key queries for monitoring:

```sql
-- Large tables
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.tables 
WHERE table_schema = 'motorbike_parking_app'
ORDER BY (data_length + index_length) DESC;

-- Index usage
SELECT 
    table_name,
    index_name,
    cardinality,
    sub_part,
    packed,
    nullable,
    index_type
FROM information_schema.statistics 
WHERE table_schema = 'motorbike_parking_app'
ORDER BY table_name, seq_in_index;
```

### Backup Strategy
- Regular full backups of the database
- Export schema separately: `mysqldump --no-data motorbike_parking_app > schema_backup.sql`
- Export data: `mysqldump --no-create-info motorbike_parking_app > data_backup.sql`

## Troubleshooting

### Common Issues

1. **Migration fails with "Cannot connect to database"**
   - Check database credentials in `migrate.sh`
   - Ensure database server is running
   - Verify database exists

2. **"Migration file not found" error**
   - Ensure migration file exists in `migrations/` directory
   - Check filename format: `VERSION.sql`

3. **"Foreign key constraint fails"**
   - Check data dependencies
   - Ensure referenced records exist
   - May need to clean up inconsistent data

### Recovery

If migrations fail midway:
1. Check current status: `./migrate.sh status`
2. Identify failed migration
3. Apply rollback if available: `./migrate.sh <version> down`
4. Fix the migration SQL
5. Re-apply: `./migrate.sh <version> up`

## Development Workflow

1. **Feature Development**:
   - Create migration: `./migrate.sh create 1.0.x "Feature description"`
   - Write migration SQL
   - Write rollback SQL
   - Test migration locally
   - Apply migration: `./migrate.sh 1.0.x up`

2. **Testing**:
   - Use test database
   - Verify rollback works: `./migrate.sh 1.0.x down`
   - Re-apply: `./migrate.sh 1.0.x up`
   - Check data integrity

3. **Production Deployment**:
   - Backup production database
   - Apply migration during maintenance window
   - Verify application functionality
   - Monitor for issues

## API Integration Notes

The Flutter app should interact with this schema through a backend API that:

1. **Authentication**: Uses the `users` table for login/registration
2. **Location Queries**: Calls `GetNearbyParkingZones` procedure
3. **Report Submission**: Uses `CreateUserReport` procedure
4. **Image Upload**: Stores metadata in `report_images` table
5. **Real-time Updates**: Leverages triggers for automatic occupancy calculations

### Example API Endpoints

```
POST /api/auth/register
POST /api/auth/login
GET /api/parking/nearby?lat=...&lng=...&radius=...
POST /api/reports
POST /api/reports/{id}/images
GET /api/parking/{id}/availability
```

This schema provides a robust foundation for the Motorbike Parking App with proper data relationships, performance optimization, and migration management.