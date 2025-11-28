# Design Document

## Overview

This design addresses the deployment of backend API response format fixes from the local development environment to the production server. The backend controllers have been updated to return a consistent `{ data: [...] }` format, but these changes exist only in the local codebase. The production server at 192.168.1.67:3000 still serves the old code with inconsistent response keys, causing the Flutter app to fail when loading parking zones.

The solution involves:
1. Verifying the database schema on the production server matches expectations
2. Deploying the updated backend code to production via SSH
3. Restarting the backend service on the production server
4. Verifying the deployment with automated tests
5. Updating the Flutter app configuration to use production endpoints

## Architecture

### System Components

```
Development Environment          Production Environment (192.168.1.67)
┌─────────────────────┐         ┌──────────────────────────────────┐
│ Local Backend       │         │ Production Backend               │
│ localhost:3000      │         │ :3000                            │
└──────────┬──────────┘         └────────┬─────────────────────────┘
           │                              │
           │                              │
           ▼                              ▼
    ┌─────────────┐              ┌──────────────┐
    │ Git Repo    │─────────────▶│ MariaDB      │
    └─────────────┘              │ Database     │
                                 └──────────────┘
                                        ▲
                                        │
                                        │
                                 ┌──────┴───────┐
                                 │ Flutter App  │
                                 └──────────────┘
```

### Deployment Flow

1. Developer runs `deploy-to-production.sh`
2. Script tests connectivity to production server
3. Script establishes SSH connection
4. Code is pushed to git repository
5. Production server pulls latest code via SSH
6. Dependencies are installed with `npm install`
7. Old server process is stopped
8. New server process is started
9. API endpoints are tested for correct response format
10. Deployment success/failure is reported


## Components and Interfaces

### 1. Database Schema Verification

**Component**: `schema-validator.sh` (new script)

**Purpose**: Verify the production database schema matches the expected structure before deployment.

**Interface**:
```bash
./schema-validator.sh [--host 192.168.1.67] [--user pedroocalado]
```

**Validation Checks**:
- Table existence: `users`, `parking_zones`, `user_reports`, `report_images`
- View existence: `parking_zone_availability`, `recent_user_reports`
- Stored procedure existence: `GetNearbyParkingZones`, `CreateUserReport`
- Trigger existence: `update_occupancy_on_report_insert`, `update_occupancy_on_report_delete`

### 2. Deployment Script Enhancement

**Component**: `deploy-to-production.sh` (enhanced)

**Current Functionality**:
- Tests server connectivity
- Establishes SSH connection
- Pushes code to git
- Pulls code on production server
- Restarts backend service
- Verifies API response format

**Enhancements Needed**:
- Add database schema validation step
- Add rollback capability if deployment fails
- Add backup of current running code before deployment
- Add more comprehensive API endpoint testing

### 3. Backend API Controllers

**Component**: `parkingController.js`, `reportController.js`

**Current State**: Already updated locally with `data` key format

**Response Format**:
```javascript
// All endpoints return this structure
{
  "data": [...] | {...},  // Array for lists, Object for single items
  "count": 10,            // Optional: for list endpoints
  "message": "Success"    // Optional: for create/update operations
}
```

**Endpoints to Verify**:
- `GET /api/parking/nearby` → `{ data: [zones], count: N }`
- `GET /api/parking/:id` → `{ data: zone }`
- `POST /api/reports` → `{ data: report, message: "..." }`
- `GET /api/reports` → `{ data: [reports], count: N }`
- `POST /api/reports/:reportId/images` → `{ data: { imageUrl, filename } }`

### 4. Flutter Environment Configuration

**Component**: `.env` file

**Current Configuration**:
```properties
DEV_API_BASE_URL=http://localhost:3000
PROD_API_BASE_URL=http://192.168.1.67:3000
ENVIRONMENT=development  # ← Needs to change to 'production'
```

**Post-Deployment Configuration**:
```properties
ENVIRONMENT=production
```

## Data Models

### API Response Format (Standardized)

**List Response**:
```json
{
  "data": [
    {
      "id": "uuid-string",
      "latitude": 38.7223,
      "longitude": -9.1393,
      "total_capacity": 20,
      "current_occupancy": 5,
      "available_slots": 15,
      "confidence_score": 0.85,
      "last_updated": "2025-11-18T10:30:00Z",
      "distance_km": 1.2
    }
  ],
  "count": 1
}
```

**Single Item Response**:
```json
{
  "data": {
    "id": "uuid-string",
    "latitude": 38.7223,
    "longitude": -9.1393,
    "total_capacity": 20,
    "current_occupancy": 5,
    "available_slots": 15,
    "confidence_score": 0.85,
    "last_updated": "2025-11-18T10:30:00Z"
  }
}
```

### Database Schema (Production)

**Tables**:
- `users`: User authentication and profile data
- `parking_zones`: Parking location and capacity information
- `user_reports`: User-submitted parking availability reports
- `report_images`: Image metadata for reports

**Views**:
- `parking_zone_availability`: Computed view with available slots and report counts
- `recent_user_reports`: Recent reports with user and location information

**Stored Procedures**:
- `GetNearbyParkingZones(lat, lng, radius, limit)`: Returns nearby zones with distance
- `CreateUserReport(spotId, userId, reportedCount, userLat, userLng)`: Creates report

**Triggers**:
- `update_occupancy_on_report_insert`: Updates zone occupancy when report is added
- `update_occupancy_on_report_delete`: Updates zone occupancy when report is deleted

## Error Handling

### Deployment Errors

**Connection Errors**:
```bash
Error: Cannot reach server at 192.168.1.67
Solution: Check network connectivity, verify server is running
Exit Code: 1
```

**SSH Authentication Errors**:
```bash
Error: Cannot SSH to server
Solution: Set up SSH keys with ssh-copy-id pedroocalado@192.168.1.67
Exit Code: 1
```

**Server Start Errors**:
```bash
Error: Server failed to start
Solution: Check server.log for details, verify database connection
Exit Code: 1
```

### Runtime API Errors

**Frontend Error Handling** (already implemented):

```dart
// SqlService.dart error handling
try {
  final response = await _apiService.get('/api/parking/nearby', ...);
  final data = response.data['data'];
  if (data is! List) {
    throw Exception('PARSING:Invalid response format');
  }
  return parseZones(data);
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    throw Exception('AUTH:Session expired. Please log in again.');
  }
  if (e.type == DioExceptionType.connectionTimeout) {
    throw Exception('TIMEOUT:Connection timed out.');
  }
  throw Exception('API:Failed to fetch parking zones.');
}
```

## Testing Strategy

### Pre-Deployment Testing

**1. Local Backend Testing**:
```bash
# Start local backend
cd backend && npm start

# Test endpoints
curl "http://localhost:3000/api/parking/nearby?lat=38.7214&lng=-9.1350&radius=5&limit=1"
# Expected: { "data": [...], "count": 1 }
```

**2. Database Schema Validation**:
```bash
# Run schema validator
./schema-validator.sh --host 192.168.1.67 --user pedroocalado

# Expected output: ✅ All schema validations passed
```

### Deployment Testing

**1. Connectivity Tests**:
```bash
# Ping test
ping -c 1 192.168.1.67

# SSH test
ssh pedroocalado@192.168.1.67 "echo 'SSH OK'"
```

**2. Deployment Execution**:
```bash
./deploy-to-production.sh

# Monitor output for success indicators
```

### Post-Deployment Testing

**1. API Endpoint Verification**:
```bash
# Run verification script
./verify-deployment.sh

# Expected: ✅ PRODUCTION: Returns 'data' key (CORRECT)
```

**2. Flutter App Integration Testing**:
```bash
# Update .env
echo "ENVIRONMENT=production" > .env

# Rebuild app
flutter build apk --release

# Install and test on device
```

## Security Considerations

**SSH Access**:
- Use SSH key authentication (no passwords)
- Use non-root user (pedroocalado) for deployments

**Database Credentials**:
- Store in .env file on production server
- Never commit credentials to git

**API Security**:
- JWT authentication required for protected endpoints
- Rate limiting enabled (100 requests per 15 minutes)
- CORS configured for specific origins

## Performance Considerations

**Deployment Downtime**:
- Expected downtime: 5-10 seconds during server restart
- Use `nohup` to keep server running after SSH disconnect

**Database Performance**:
- Stored procedures optimize query performance
- Indexes on frequently queried columns
- Views pre-compute expensive calculations

**API Performance**:
- Compression middleware reduces response size
- Connection pooling for database connections
- Rate limiting prevents abuse
