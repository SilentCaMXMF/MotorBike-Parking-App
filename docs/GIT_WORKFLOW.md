# Git Workflow - Motorbike Parking App

## Overview

This document describes the Git workflow for developing, testing, and deploying the Motorbike Parking App.

---

## Branch Strategy

```
main
├── develop (optional)
│   ├── feature/feature-name
│   ├── bugfix/bugfix-name
│   └── hotfix/hotfix-name
```

### Branch Types

| Branch | Purpose | Merges Into |
|--------|---------|-------------|
| `main` | Production code | - |
| `feature/*` | New features | main |
| `bugfix/*` | Bug fixes | main |
| `hotfix/*` | Urgent production fixes | main |

### Naming Convention

```
<type>/<ticket-id>-<short-description>

Examples:
- feature/123-add-user-authentication
- bugfix/456-fix-map-crash
- hotfix/789-security-patch
```

---

## Commit Messages

### Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `style` | Code style (formatting) |
| `refactor` | Code refactoring |
| `test` | Tests |
| `chore` | Maintenance |

### Examples

```
feat(auth): add anonymous login support

fix(map): resolve crash on iOS when location permission denied

docs(readme): update deployment URLs

style(api): format code with flutter format
```

---

## Development Workflow

### 1. Start New Feature

```bash
# Update main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/123-new-feature
```

### 2. Make Changes

```bash
# Make your changes, then commit
git add .
git commit -m "feat(feature): description"
```

### 3. Keep Updated

```bash
# Periodically rebase on main
git fetch origin
git rebase origin/main
```

### 4. Push and Create PR

```bash
# Push branch
git push -u origin feature/123-new-feature

# Create Pull Request via GitHub UI
```

### 5. After Merge

```bash
# Switch to main and cleanup
git checkout main
git pull origin main
git branch -d feature/123-new-feature
```

---

## Build & Deployment Workflow

### Local Build (Recommended for Web)

Since Vercel doesn't have Flutter installed, builds are done locally:

```bash
# Option 1: Use the deploy script
./scripts/deploy-web.sh

# Option 2: Manual
flutter build web --release
cd build/web
vercel deploy --prod --yes
```

### CI/CD Pipeline

The project uses GitHub Actions (`.github/workflows/flutter-ci.yml`):

| Job | Trigger | Description |
|-----|---------|-------------|
| `test` | push/PR | Run analyze + tests |
| `build-android` | push/PR main | Build Android APK |

**Note:** Web deployment is **manual** due to Vercel limitation.

---

## Deployment Checklist

Before deploying, ensure:

- [ ] All tests pass (`flutter test`)
- [ ] No analysis errors (`flutter analyze`)
- [ ] Environment variables updated (`.env`)
- [ ] Version bumped (if applicable)
- [ ] Documentation updated (if needed)

---

## Quick Commands

```bash
# Check status
git status

# View branches
git branch -a

# Switch branch
git checkout <branch>

# Pull latest
git pull origin main

# Create and switch
git checkout -b feature/name

# Commit changes
git add . && git commit -m "type: message"

# Push branch
git push -u origin <branch>

# Merge main into current branch
git merge main

# Rebase on main
git rebase origin/main
```

---

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/deploy-web.sh` | Build and deploy web to Vercel |
| `scripts/start_debug_session.sh` | Start debug session on Pi |
| `scripts/phase1_*.sh` | Infrastructure setup scripts |

---

## Environment Variables

### Frontend (.env)

```env
DEV_API_BASE_URL=http://192.168.1.67:3000
PROD_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu
ENVIRONMENT=development
GOOGLE_MAPS_API_KEY=your_key
```

### Backend (backend/.env)

```env
NODE_ENV=development
PORT=3000
DB_HOST=192.168.1.67
DB_PORT=3306
DB_NAME=motorbike_parking_app
DB_USER=motorbike_app
DB_PASSWORD=your_password
JWT_SECRET=your_secret
JWT_EXPIRES_IN=7d
CORS_ORIGIN=http://localhost:3000,https://homelab-backendpi.pedroocalado.eu,https://motorbike-web.vercel.app
```
