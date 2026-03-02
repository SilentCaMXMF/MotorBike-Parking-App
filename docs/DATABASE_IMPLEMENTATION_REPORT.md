# MariaDB Database Implementation Report

**Document Version:** 1.0  
**Date:** 2026-03-01  
**Database:** MariaDB 10.11.14 on Raspberry Pi 4 (192.168.1.67)  

---

## 1. Infrastructure Overview

| Property | Value |
|----------|-------|
| **Host** | Raspberry Pi 4 ("pivpn") |
| **IP Address** | 192.168.1.67 |
| **Database** | motorbike_parking_app |
| **Database Engine** | MariaDB 10.11.14 |
| **Database User** | motorbike_app |
| **Collation** | utf8mb4_unicode_ci |
| **Port** | 3306 |

---

## 2. Connection Details

### Application Connection (Read/Write)
```
Host: 192.168.1.67
Port: 3306
Database: motorbike_parking_app
User: motorbike_app
Password: [stored in backend/.env]
```

### Admin Connection (Full Access)
```
Host: 192.168.1.67
Port: 3306
User: root
Access: sudo mysql
```

---

## 3. Database Schema

### 3.1 Tables Overview

| Table | Records | Size | Description |
|-------|---------|------|-------------|
| users | 125 | 96 KB | User accounts (registered + anonymous) |
| parking_zones | 58 | 96 KB | Parking locations |
| user_reports | 11 | 80 KB | Availability reports |
| report_images | 1 | 64 KB | Report photo metadata |
| schema_version | 1 | 16 KB | Migration tracking |

### 3.2 Users Table

```sql
CREATE TABLE users (
    id CHAR(36) NOT NULL DEFAULT (UUID()),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NULL,
    is_anonymous TINYINT(1) NOT NULL DEFAULT 0,
    is_admin TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE INDEX idx_users_email (email),
    INDEX idx_users_created_at (created_at),
    INDEX idx_users_is_active (is_active)
) ENGINE=InnoDB;
```

**Fields:**
- `id` - UUID primary key
- `email` - Unique email address (NULL for anonymous)
- `password_hash` - Bcrypt hash (NULL for anonymous users)
- `is_anonymous` - TRUE for guest users
- `is_admin` - TRUE for admin users
- `is_active` - FALSE to disable account
- `created_at` - Account creation timestamp
- `updated_at` - Last update timestamp

### 3.3 Parking Zones Table

```sql
CREATE TABLE parking_zones (
    id CHAR(36) NOT NULL DEFAULT (UUID()),
    google_places_id VARCHAR(255) NULL UNIQUE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    total_capacity INT NOT NULL DEFAULT 0,
    current_occupancy INT NOT NULL DEFAULT 0,
    confidence_score DECIMAL(3, 2) NOT NULL DEFAULT 0.00,
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_parking_zones_google_places (google_places_id),
    INDEX idx_parking_zones_location (latitude, longitude),
    INDEX idx_parking_zones_last_updated (last_updated),
    INDEX idx_parking_zones_is_active (is_active),
    CONSTRAINT chk_latitude CHECK (latitude >= -90 AND latitude <= 90),
    CONSTRAINT chk_longitude CHECK (longitude >= -180 AND longitude <= 180),
    CONSTRAINT chk_capacity CHECK (total_capacity >= 0),
    CONSTRAINT chk_occupancy CHECK (current_occupancy >= 0 AND current_occupancy <= total_capacity),
    CONSTRAINT chk_confidence CHECK (confidence_score >= 0.00 AND confidence_score <= 1.00)
) ENGINE=InnoDB;
```

**Fields:**
- `id` - UUID primary key
- `google_places_id` - Google Places API reference
- `latitude`, `longitude` - Location coordinates
- `total_capacity` - Maximum parking spots
- `current_occupancy` - Current bike count
- `confidence_score` - Report reliability (0.00-1.00)
- `last_updated` - Last report timestamp
- `is_active` - Zone enabled/disabled

### 3.4 User Reports Table

```sql
CREATE TABLE user_reports (
    id CHAR(36) NOT NULL DEFAULT (UUID()),
    spot_id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    reported_count INT NOT NULL DEFAULT 1,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_latitude DECIMAL(10, 8) NULL,
    user_longitude DECIMAL(11, 8) NULL,
    is_verified TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_user_reports_spot_id (spot_id),
    INDEX idx_user_reports_user_id (user_id),
    INDEX idx_user_reports_timestamp (timestamp),
    INDEX idx_user_reports_is_verified (is_verified),
    FOREIGN KEY (spot_id) REFERENCES parking_zones(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;
```

**Fields:**
- `id` - UUID primary key
- `spot_id` - Reference to parking zone
- `user_id` - Reference to user
- `reported_count` - Number of bikes reported
- `timestamp` - Report timestamp
- `user_latitude`, `user_longitude` - Reporter's location
- `is_verified` - Whether report was verified

### 3.5 Report Images Table

```sql
CREATE TABLE report_images (
    id CHAR(36) NOT NULL DEFAULT (UUID()),
    report_id CHAR(36) NOT NULL,
    image_url VARCHAR(500) NULL,
    file_path VARCHAR(500) NULL,
    file_size INT NULL,
    mime_type VARCHAR(100) NULL,
    dimensions VARCHAR(50) NULL,
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_processed TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    INDEX idx_report_images_report_id (report_id),
    INDEX idx_report_images_uploaded_at (uploaded_at),
    FOREIGN KEY (report_id) REFERENCES user_reports(id) ON DELETE CASCADE
) ENGINE=InnoDB;
```

---

## 4. Views

### 4.1 parking_zone_availability

```sql
CREATE VIEW parking_zone_availability AS
SELECT 
    pz.id,
    pz.google_places_id,
    pz.latitude,
    pz.longitude,
    pz.total_capacity,
    pz.current_occupancy,
    (pz.total_capacity - pz.current_occupancy) AS available_slots,
    pz.confidence_score,
    pz.last_updated,
    pz.is_active,
    COUNT(ur.id) AS total_reports,
    SUM(CASE WHEN ur.timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN 1 ELSE 0 END) AS reports_24h,
    SUM(CASE WHEN ur.timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR) THEN 1 ELSE 0 END) AS reports_1h
FROM parking_zones pz
LEFT JOIN user_reports ur ON pz.id = ur.spot_id
WHERE pz.is_active = TRUE
GROUP BY pz.id;
```

### 4.2 recent_user_reports

```sql
CREATE VIEW recent_user_reports AS
SELECT 
    ur.*,
    u.email,
    u.is_anonymous AS user_is_anonymous,
    pz.latitude AS spot_latitude,
    pz.longitude AS spot_longitude
FROM user_reports ur
JOIN users u ON ur.user_id = u.id
JOIN parking_zones pz ON ur.spot_id = pz.id
WHERE ur.timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY ur.timestamp DESC;
```

---

## 5. Stored Procedures

### 5.1 GetNearbyParkingZones

```sql
CREATE PROCEDURE GetNearbyParkingZones(
    IN p_latitude DECIMAL(10, 8),
    IN p_longitude DECIMAL(11, 8),
    IN p_radius_km DECIMAL(8, 3),
    IN p_limit INT
)
BEGIN
    SELECT 
        pza.*,
        (
            6371 * ACOS(
                COS(RADIANS(p_latitude)) * 
                COS(RADIANS(pza.latitude)) * 
                COS(RADIANS(pza.longitude) - RADIANS(p_longitude)) + 
                SIN(RADIANS(p_latitude)) * 
                SIN(RADIANS(pza.latitude))
            )
        ) AS distance_km
    FROM parking_zone_availability pza
    HAVING distance_km <= p_radius_km
    ORDER BY distance_km ASC, pza.confidence_score DESC
    LIMIT p_limit;
END
```

**Usage:**
```sql
CALL GetNearbyParkingZones(38.7223, -9.1393, 5.0, 50);
```

### 5.2 CreateUserReport

```sql
CREATE PROCEDURE CreateUserReport(
    IN p_spot_id CHAR(36),
    IN p_user_id CHAR(36),
    IN p_reported_count INT,
    IN p_user_latitude DECIMAL(10, 8),
    IN p_user_longitude DECIMAL(11, 8)
)
BEGIN
    DECLARE v_report_id CHAR(36);
    
    SET v_report_id = UUID();
    
    INSERT INTO user_reports (
        id, spot_id, user_id, reported_count, user_latitude, user_longitude
    ) VALUES (
        v_report_id, p_spot_id, p_user_id, p_reported_count, p_user_latitude, p_user_longitude
    );
    
    SELECT v_report_id AS report_id;
END
```

**Usage:**
```sql
CALL CreateUserReport('zone-uuid', 'user-uuid', 5, 38.7223, -9.1393);
```

---

## 6. Current Data Summary

### 6.1 Users Breakdown

| Type | Count | Percentage |
|------|-------|------------|
| Registered Users | 1 | 0.8% |
| Anonymous Users | 124 | 99.2% |
| Admin Users | 0 | 0% |
| **Total** | **125** | 100% |

**Sample Users:**
| ID | Email | Type | Created |
|----|-------|------|---------|
| 20ff8f58-cd47... | test@example.com | Registered | 2025-11-29 |
| 14f8de3b-13fd... | anonymous_17722... | Anonymous | 2026-02-27 |

### 6.2 Parking Zones

| Metric | Value |
|--------|-------|
| Total Zones | 58 |
| Active Zones | 58 |
| Locations | Lisbon, Portugal (38.7°, -9.14°) |
| Capacity per Zone | 18 spots |
| Total Capacity | 1,044 spots |

**Sample Zones:**
| ID | Google Places ID | Lat | Lng | Capacity | Occupancy |
|----|-----------------|-----|-----|----------|-----------|
| 5f01bb46... | ChIJV2G... | 38.7092 | -9.1346 | 18 | 0 |
| 5f02ee49... | ChIJCfQ... | 38.7510 | -9.1430 | 18 | 0 |

### 6.3 Reports

| Metric | Value |
|--------|-------|
| Total Reports | 11 |
| Verified Reports | 0 |
| Reports with Images | 1 |
| Reports in Last 24h | 0 |

---

## 7. Backup Configuration

### 7.1 Backup Script

**Location:** `~/backup_db.sh`  
**Schedule:** Daily at 2:00 AM (cron)  
**Destination:** `~/backups/`

**Cron Entry:**
```bash
0 2 * * * /home/pedroocalado/backup_db.sh >> /home/pedroocalado/backup.log 2>&1
```

### 7.2 Backup Files

| File | Date | Size |
|------|------|------|
| motorbike_parking_app_20260301_020001.sql.gz | Mar 1 | 450 B |
| motorbike_parking_app_20260228_020001.sql.gz | Feb 28 | 450 B |
| motorbike_parking_app_20260227_020001.sql.gz | Feb 27 | 450 B |
| ... | ... | ... |

**Note:** Backup files are suspiciously small (450 bytes), suggesting backup may not be capturing data or is being compressed when empty.

---

## 8. Issues Identified

### 8.1 Critical Issues

| Issue | Severity | Description |
|-------|----------|-------------|
| Anonymous User Bloat | HIGH | 124 anonymous users with no cleanup - table will grow indefinitely |
| Small Backup Files | HIGH | 450 bytes suggests backup is not capturing data properly |
| No Triggers | MEDIUM | Schema mentions triggers for auto-occupancy but none exist in DB |

### 8.2 Data Quality Issues

| Issue | Description |
|-------|-------------|
| Zero Occupancy | All 58 zones have current_occupancy = 0 |
| Zero Confidence | All zones have confidence_score = 0.00 |
| No Recent Reports | 0 reports in last 24 hours |
| Low Report Volume | Only 11 reports total for 58 zones |

### 8.3 Recommendations

1. **Implement Anonymous User Cleanup** - Add job to delete anonymous users inactive for 30+ days
2. **Verify Backup Script** - Check why backups are only 450 bytes
3. **Add Triggers** - Implement auto-occupancy calculation triggers
4. **Increase User Engagement** - More reports needed for confidence scoring

---

## 9. Schema Version

| Version | Description | Applied |
|---------|-------------|---------|
| 1.0.0 | Initial schema with users, parking_zones, user_reports, report_images | 2025-11-11 03:46:26 |

---

## 10. Access Credentials

### Application User (motorbike_app)
```bash
mysql -h 192.168.1.67 -u motorbike_app -p'motorbike_app_password' motorbike_parking_app
```

### Admin User (root)
```bash
ssh pedroocalado@192.168.1.67
sudo mysql
USE motorbike_parking_app;
```

---

## Appendix: Useful Queries

### Get All Zones with Distance
```sql
CALL GetNearbyParkingZones(38.7223, -9.1393, 10.0, 50);
```

### Get User Report Stats
```sql
SELECT 
    DATE(timestamp) as date,
    COUNT(*) as reports,
    SUM(reported_count) as total_bikes
FROM user_reports
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

### Get Zone Availability
```sql
SELECT * FROM parking_zone_availability WHERE confidence_score > 0.5;
```

---

*Document generated: 2026-03-01*
