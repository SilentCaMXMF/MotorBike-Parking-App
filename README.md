# Motorbike Parking App

A Flutter application for finding and reporting motorbike parking availability in real-time.

## Live Demo

| Service | URL | Status |
|---------|-----|--------|
| **Web App** | https://motorbike-web.vercel.app | Active |
| **Backend API** | https://homelab-backendpi.pedroocalado.eu | Active |

> **Note**: The backend uses a permanent Cloudflare domain - it does NOT change on restart.

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
│                     Motorbike Parking App                    │
├─────────────────────────────────────────────────────────────┤
│  FRONTEND (Flutter)                                         │
│  ├── Mobile (iOS/Android)                                   │
│  ├── Web (Vercel - auto-deployed from main)               │
│  └── lib/ (source code at root)                            │
└─────────────────────┬───────────────────────────────────────┘
                    │ HTTP/REST
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  BACKEND (Node.js + Express)                               │
│  ├── Raspberry Pi 4 (192.168.1.67)                        │
│  ├── PM2 Process Manager                                   │
│  └── Cloudflare Tunnel (public exposure)                   │
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

### Hosting Components

| Service | Purpose | Technology |
|---------|---------|------------|
| **Vercel** | Flutter web frontend hosting | Static web hosting (auto-deploys from GitHub) |
| **Cloudflare Tunnel** | Backend API exposure | Tunnel from Raspberry Pi to public URL |
| **Raspberry Pi** | Backend server | Node.js + Express + MariaDB + PM2 |

---

## Tech Stack

| Component | Technology | Location |
|-----------|------------|----------|
| **Frontend** | Flutter 3.24+ | Root `/lib` |
| **Backend** | Node.js + Express | `/backend` |
| **Database** | MariaDB 10.11.14 | Raspberry Pi |
| **Maps** | flutter_map + OpenStreetMap | Flutter app |
| **Hosting (Web)** | Vercel | Cloud |
| **Hosting (API)** | Raspberry Pi 4 + Cloudflare Tunnel | Local |
| **Process Manager** | PM2 | Raspberry Pi |

---

## Current Status

### Infrastructure

| Service | Host | Status |
|---------|------|--------|
| Backend API | 192.168.1.67:3000 (local) / homelab-backendpi.pedroocalado.eu | ✅ Online |
| MariaDB | 192.168.1.67:3306 | ✅ Online |
| Cloudflare Tunnel | homelab-backendpi.pedroocalado.eu | ✅ Online |

### Database Statistics

| Metric | Value |
|--------|-------|
| Total Users | 43 |
| Registered Users | 28 |
| Anonymous Users | 15 |
| Parking Zones | 58 |
| Total Reports | 11 |
| Images Uploaded | 1 |

### Security (Completed)

| Fix | Status | Date |
|-----|--------|------|
| Backup Script Fixed | ✅ Working (9.3KB) | 2026-03-01 |
| Anonymous Cleanup | ✅ 82 users deleted | 2026-03-01 |
| Database Triggers | ✅ Auto-occupancy | 2026-03-01 |
| CORS Restricted | ✅ Allowed origins only | 2026-03-01 |
| Rate Limiting | ✅ 5 attempts/15min | 2026-03-01 |
| JWT Secret | ✅ 256-bit generated | 2026-03-01 |
| Token Blacklist | ✅ Logout invalidates | 2026-03-01 |
| Debug Logs Removed | ✅ | 2026-03-01 |
| Pagination Added | ✅ | 2026-03-01 |

---

## Project Structure

```
MotorBike_Parking_App/
├── lib/                      # Flutter source code
│   ├── config/              # Environment configuration
│   ├── models/              # Data models
│   ├── screens/             # UI screens
│   ├── services/            # API & business services
│   ├── widgets/             # Reusable widgets
│   ├── utils/               # Utilities
│   └── main.dart            # Entry point
│
├── backend/                  # Node.js API server
│   ├── src/
│   │   ├── config/          # Database config
│   │   ├── controllers/     # Route handlers
│   │   ├── middleware/      # Auth, validation
│   │   └── routes/          # API routes
│   ├── .env                 # Environment config
│   └── package.json
│
├── docs/                    # Documentation
│   ├── DATABASE_README.md    # Database schema
│   ├── DATABASE_IMPLEMENTATION_REPORT.md
│   ├── ROADMAP_BACKEND_SECURITY.md
│   ├── SWOT_ANALYSIS_BACKEND.md
│   └── infrastructure/      # Infrastructure docs
│
├── android/                 # Android platform
├── ios/                     # iOS platform
├── web/                     # Built web output
├── test/                    # Unit tests
├── integration_test/        # Integration tests
├── migrations/              # Database migrations
├── schema.sql              # Full database schema
├── pubspec.yaml            # Flutter dependencies
└── README.md               # This file
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [GIT_WORKFLOW.md](./docs/GIT_WORKFLOW.md) | Git workflow, branching, commit conventions |
| [DATABASE_README.md](./docs/DATABASE_README.md) | Database schema, views, triggers, procedures |
| [DATABASE_IMPLEMENTATION_REPORT.md](./docs/DATABASE_IMPLEMENTATION_REPORT.md) | MariaDB implementation details |
| [SWOT_ANALYSIS_BACKEND.md](./docs/SWOT_ANALYSIS_BACKEND.md) | Backend strengths, weaknesses, opportunities |
| [ROADMAP_BACKEND_SECURITY.md](./docs/ROADMAP_BACKEND_SECURITY.md) | Security fixes and improvements |
| [backend/README.md](./backend/README.md) | Backend API documentation |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.24+
- Node.js 18+ (for local development)
- MariaDB/MySQL (or connect to Pi database)

### Frontend Setup

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build for web
flutter build web --release
```

### Backend Setup (Local Development)

```bash
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
PROD_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu
ENVIRONMENT=development
# No API key needed - uses OpenStreetMap
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
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,https://homelab-backendpi.pedroocalado.eu,https://motorbike-web.vercel.app

# Admin setup (optional)
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=SecureAdminPassword123!
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
| POST | /api/auth/logout | JWT | Logout (invalidates token) |

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
| GET | /api/reports | JWT | Get zone reports (paginated) |
| GET | /api/reports/me | JWT | Get my reports |
| POST | /api/reports/:id/images | JWT | Upload image |

> **Rate Limiting:**
> - Auth endpoints: 5 attempts per 15 minutes
> - General API: 100 requests per 15 minutes

---

## Connecting to Pi Database

### SSH Access

```bash
ssh pedrocalado@192.168.1.67
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

Vercel is used as **static hosting only** - Flutter is built locally before deployment.

```bash
# Option 1: Use deploy script (recommended)
./scripts/deploy-web.sh

# Option 2: Manual
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

## Testing

```bash
# Flutter tests
flutter test

# Backend tests
cd backend
npm test
```

---

## License

MIT
