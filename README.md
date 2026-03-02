# Motorbike Parking App

A Flutter application for finding and reporting motorbike parking availability in real-time.

## Live Demo

| Service | URL | Status |
|---------|-----|--------|
| **Web App** | https://web-smoky-chi-34.vercel.app | Active |
| **Backend API** | http://192.168.1.67:3000 | Active (Local) |
| **Cloudflare Tunnel** | https://delaware-compromise-someone-cheapest.trycloudflare.com | Active |

> **Note**: The Cloudflare tunnel URL changes when restarts. For production, use a permanent domain or local IP.

---

## Features

- Find nearby parking zones on an interactive map
- Report parking availability
- View parking zone details and confidence scores
- User authentication (email + anonymous/guest)
- Real-time occupancy updates based on user reports
- Cross-platform: iOS, Android, and Web

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Motorbike Parking App                   │
├─────────────────────────────────────────────────────────────┤
│  FRONTEND (Flutter)                                        │
│  ├── Mobile (iOS/Android)                                  │
│  └── Web (Vercel)                                          │
└─────────────────────┬───────────────────────────────────────┘
                    │ HTTP/REST
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  BACKEND (Node.js + Express)                               │
│  ├── Raspberry Pi 4 (192.168.1.67)                        │
│  └── PM2 Process Manager                                    │
└─────────────────────┬───────────────────────────────────────┘
                    │ MySQL Protocol
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  DATABASE (MariaDB 10.11.14)                                │
│  ├── Host: 192.168.1.67:3306                               │
│  ├── Database: motorbike_parking_app                        │
│  └── Tables: users, parking_zones, user_reports           │
└─────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Component | Technology | Location |
|-----------|------------|----------|
| **Frontend** | Flutter 3.24+ | This repo /frontend |
| **Backend** | Node.js + Express | Raspberry Pi / This repo /backend |
| **Database** | MariaDB 10.11.14 | Raspberry Pi |
| **Maps** | Google Maps Flutter | Flutter app |
| **Hosting (Web)** | Vercel | Cloud |
| **Hosting (API)** | Raspberry Pi 4 | Local |
| **Process Manager** | PM2 | Raspberry Pi |

---

## Current Status

### Infrastructure

| Service | Host | Status | Uptime |
|---------|------|--------|--------|
| Backend API | 192.168.1.67:3000 | ✅ Online | 2 days |
| MariaDB | 192.168.1.67:3306 | ✅ Online | 12 days |
| Cloudflare Tunnel | trycloudflare.com | ✅ Online | 2 days |

### Database Statistics

| Metric | Value |
|--------|-------|
| Total Users | 43 |
| Registered Users | 28 |
| Anonymous Users | 15 |
| Parking Zones | 58 |
| Total Reports | 11 |
| Images Uploaded | 1 |

### Security & Improvements (Completed)

| Fix | Status | Date |
|-----|--------|------|
| Backup Script Fixed | ✅ Working (9.3KB) | 2026-03-01 |
| Anonymous Cleanup | ✅ 82 users deleted | 2026-03-01 |
| Database Triggers | ✅ Auto-occupancy | 2026-03-01 |
| CORS Restricted | ✅ Allowed origins only | 2026-03-01 |
| Rate Limiting | ✅ 5 attempts/15min | 2026-03-01 |
| JWT Secret | ✅ 256-bit generated | 2026-03-01 |
| Token Blacklist | ✅ Logout invalidates | 2026-03-01 |
| Debug Logs | ✅ Removed | 2026-03-01 |
| Pagination | ✅ Added | 2026-03-01 |

> See [ROADMAP_BACKEND_SECURITY.md](./docs/ROADMAP_BACKEND_SECURITY.md) for full details

---

## Project Structure

```
MotorBike_Parking_App/
├── frontend/                 # Flutter app
│   ├── lib/                 # Source code
│   │   ├── config/          # Environment config
│   │   ├── models/          # Data models
│   │   ├── screens/         # UI screens
│   │   ├── services/        # API services
│   │   ├── widgets/         # Reusable widgets
│   │   └── main.dart       # Entry point
│   ├── test/                # Unit tests
│   ├── integration_test/    # Integration tests
│   ├── android/             # Android platform
│   ├── ios/                 # iOS platform
│   └── pubspec.yaml        # Dependencies
│
├── docs/                    # Documentation
│   ├── SWOT_ANALYSIS_BACKEND.md
│   ├── ROADMAP_BACKEND_SECURITY.md
│   ├── DATABASE_IMPLEMENTATION_REPORT.md
│   ├── DATABASE_README.md
│   └── ...
│
├── scripts/                 # Shared scripts
├── tasks/                  # Task tracking
├── schema.sql              # Database schema
└── README.md              # This file
```

<<<<<<< Updated upstream
## Architecture

The app uses a **client-server** architecture with separate hosting for frontend and backend:

```
┌─────────────────────────────┐     ┌─────────────────────────────┐
│      Flutter Web App        │     │     Raspberry Pi Backend    │
│       (Vercel)              │     │     (Node.js + MariaDB)     │
│                             │     │                             │
│  https://web-xxx.vercel.app │────▶│  localhost:3000             │
└─────────────────────────────┘     └──────────────┬──────────────┘
                                                   │
                                                   ▼
                                    ┌─────────────────────────────┐
                                    │    Cloudflare Tunnel        │
                                    │    (Public API Access)      │
                                    │                             │
                                    │  https://xxx.trycloudflare.com
                                    └─────────────────────────────┘
```

### Hosting Components

| Service | Purpose | Technology |
|---------|---------|------------|
| **Vercel** | Flutter web frontend hosting | Static web hosting (auto-deploys from GitHub) |
| **Cloudflare Tunnel** | Backend API exposure | Tunnel from Raspberry Pi to public URL |
| **Raspberry Pi** | Backend server | Node.js + Express + MariaDB + PM2 |

### Why Both Are Needed

- **Vercel** hosts the compiled Flutter web app (static HTML/JS/CSS)
- **Cloudflare Tunnel** exposes the Node.js backend API to the internet without port forwarding

> **Note**: The Cloudflare URL is temporary and changes each time the tunnel restarts. For production, purchase a domain and configure a permanent tunnel.
=======

---

## Documentation

| Document | Description |
|----------|-------------|
| [DATABASE_IMPLEMENTATION_REPORT.md](./docs/DATABASE_IMPLEMENTATION_REPORT.md) | MariaDB schema, tables, procedures |
| [SWOT_ANALYSIS_BACKEND.md](./docs/SWOT_ANALYSIS_BACKEND.md) | Backend strengths, weaknesses, opportunities, threats |
| [ROADMAP_BACKEND_SECURITY.md](./docs/ROADMAP_BACKEND_SECURITY.md) | Security fixes and improvements plan |
| [DATABASE_README.md](./docs/DATABASE_README.md) | Database schema and migration guide |

---
>>>>>>> Stashed changes

## Getting Started

### Prerequisites

- Flutter SDK 3.24+
- Node.js 18+ (for local development)
- MariaDB/MySQL (or connect to Pi database)

### Frontend Setup

```bash
# Navigate to frontend
cd frontend

# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build for web
flutter build web --release
```

### Backend Setup (Local Development)

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with database credentials
nano .env

# Run the server
npm run dev
```

### Environment Variables

#### Frontend (.env)

```env
DEV_API_BASE_URL=http://192.168.1.67:3000
PROD_API_BASE_URL=https://your-production-url.com
ENVIRONMENT=development
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
BACKEND_PI_SSH_LOGIN=pedroocalado@192.168.1.67
BACKEND_PI_SSH_PASSWORD=your_password
```

#### Backend (.env)

```env
NODE_ENV=development
PORT=3000
DB_HOST=192.168.1.67
DB_PORT=3306
DB_NAME=motorbike_parking_app
DB_USER=motorbike_app
DB_PASSWORD=your_db_password
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d
CORS_ORIGIN=http://localhost:3000,https://your-domain.com
```

---

## API Endpoints

### Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /api/auth/register | Public | Register new user |
| POST | /api/auth/login | Public | User login |
| POST | /api/auth/anonymous | Public | Guest login |
| GET | /api/auth/me | JWT | Get current user |
| POST | /api/auth/logout | JWT | Logout |

### Parking Zones

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | /api/parking/nearby | Public | Get nearby zones |
| GET | /api/parking/:id | Public | Get zone details |
| POST | /api/parking | Admin | Create zone |
| PUT | /api/parking/:id | Admin | Update zone |

### Reports

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /api/reports | JWT | Submit report |
| GET | /api/reports/zone/:spotId | JWT | Get zone reports (paginated) |
| GET | /api/reports/me | JWT | Get my reports |
| POST | /api/reports/:id/images | JWT | Upload image |

> **Rate Limiting:**
> - Auth endpoints: 5 attempts per 15 minutes
> - General API: 100 requests per 15 minutes
> - Token invalidation on logout enabled

---

## Connecting to Pi Database

### SSH Access

```bash
# Connect to Raspberryroocalado@192.168. Pi
ssh ped1.67
```

### Database Access

```bash
# Via SSH (on Pi)
mysql -u motorbike_app -p motorbike_parking_app

# Or directly from local machine
mysql -h 192.168.1.67 -u motorbike_app -p motorbike_parking_app
```

### PM2 Process Management

```bash
# On Pi - Check status
pm2 list

# View logs
pm2 logs motorbike-parking-api

# Restart
pm2 restart motorbike-parking-api
```

---

## Deployment

### Frontend (Vercel)

```bash
cd frontend
flutter build web --release
cd build/web
vercel deploy --prod --yes
```

### Backend (Pi)

```bash
# On Pi - Install and start
cd ~/motorbike_app/backend
npm install
pm2 start src/server.js --name motorbike-parking-api
pm2 save
pm2 startup
```

---

## Known Issues & Roadmap

### Critical Issues

1. **Backup not working** - Files are ~450 bytes (should be ~10KB+)
2. **Anonymous users bloat** - 124 users with no cleanup
3. **No occupancy data** - All zones show 0 occupancy

### Security Improvements

1. Restrict CORS (currently `*`)
2. Add rate limiting to auth endpoints
3. Generate strong JWT_SECRET
4. Implement token blacklist

> See [ROADMAP_BACKEND_SECURITY.md](./docs/ROADMAP_BACKEND_SECURITY.md) for full plan

---

## License

MIT

---

## Authors

- Pedro Calado - Initial work

## Acknowledgments

- Raspberry Pi 4 for hosting backend and database
- Google Maps Flutter for map integration
- Vercel for web hosting
