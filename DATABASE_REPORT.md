# Database Diagnostic Report - Raspberry Pi

**Date:** 2026-02-27  
**Database:** MariaDB 10.11.14

---

## Status Overview

| Component | Status |
|-----------|--------|
| MariaDB Service | ✅ Running |
| Database Connection | ✅ Working |
| Backend Connectivity | ✅ Connected |

---

## Database: `motorbike_parking_app`

### Tables

| Table | Status |
|-------|--------|
| users | ✅ Created |
| parking_zones | ✅ Created |
| parking_zone_availability | ✅ Created |
| user_reports | ✅ Created |
| recent_user_reports | ✅ Created |
| report_images | ✅ Created |
| schema_version | ✅ Created |

### Data Summary

| Entity | Count |
|--------|-------|
| Users | 119 |
| Parking Zones | 58 |

### Sample Parking Zones (Lisbon Area)

| ID | Latitude | Longitude | Capacity | Occupancy |
|----|----------|-----------|----------|-----------|
| 5f01bb46-bf55-11f0-93d3-b827ebb20cfc | 38.70920230 | -9.13465890 | 18 | 0 |
| 5f02ee49-bf55-11f0-93d3-b827ebb20cfc | 38.75100480 | -9.14300780 | 18 | 0 |
| 5f03b870-bf55-11f0-93d3-b827ebb20cfc | 38.70654370 | -9.14700640 | 18 | 0 |

---

## Configuration

### Database Connection
```
Host:     192.168.1.67
Port:     3306
Database: motorbike_parking_app
User:     motorbike_app
SSL:      Disabled
```

### JWT Settings
```
Secret:   [HIDDEN]
Expires:  7 days
```

---

## API Test

**Endpoint:** `POST /api/auth/anonymous`  
**Status:** ✅ Working

**Response:**
```json
{
  "message": "Anonymous user created",
  "user": {
    "id": "c97bc9e2-13f6-11f1-b044-b827ebb20cfc",
    "email": "anonymous_1772208722186@motorbike-parking.app",
    "isAnonymous": true,
    "createdAt": "2026-02-27T16:12:02.000Z"
  },
  "token": "eyJhbGci..."
}
```

---

## Issues

| Issue | Severity | Notes |
|-------|----------|-------|
| Missing `.env` file | ⚠️ Warning | Backend using `.env.example` only |

---

## Recommendations

1. Create `/home/pedroocalado/motorbike_app/backend/.env` with actual database credentials
