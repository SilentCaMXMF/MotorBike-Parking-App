# Git Workflow - Motorbike Parking App

**Last Updated:** March 11, 2026

---

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
| `ci` | CI/CD configuration |

### Examples

```
feat(auth): add anonymous login support

fix(map): resolve crash on iOS when location permission denied

docs(readme): update deployment URLs

style(api): format code with flutter format

ci(vercel): add automated deployment workflow

test(auth): add unit tests for authentication service
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

# Verify branch created
git branch
```

### 2. Make Changes

```bash
# Make your changes
# ... code changes ...

# Check what changed
git status

# Stage changes
git add .

# Commit with proper message
git commit -m "feat(feature): description of changes"
```

### 3. Keep Updated

```bash
# Periodically rebase on main to stay current
git fetch origin
git rebase origin/main
```

### 4. Push and Create PR

```bash
# Push branch to remote
git push -u origin feature/123-new-feature

# Check PR on GitHub
# Create Pull Request via GitHub UI
```

### 5. After Merge

```bash
# Switch to main and pull changes
git checkout main
git pull origin main

# Delete feature branch locally
git branch -d feature/123-new-feature

# Delete feature branch remotely
git push origin --delete feature/123-new-feature
```

---

## Deployment Workflow

### For Manual Deployment (Local)

```bash
# Make sure you're on main and up to date
git checkout main
git pull origin main

# Check status
git status

# Run tests locally
flutter test
flutter analyze

# Build web app
flutter build web --release

# Deploy to Vercel
cd build/web
vercel deploy --prod --yes
```

### Using Deployment Script

```bash
# Make script executable
chmod +x scripts/deploy-web.sh

# Deploy to production
./scripts/deploy-web.sh production

# Deploy to preview
./scripts/deploy-web.sh preview
```

**What the script does:**
1. Checks Git status for uncommitted changes
2. Runs `flutter analyze` for code quality
3. Runs `flutter test` for testing
4. Builds web app: `flutter build web --release`
5. Deploys to Vercel with specified environment

### For CI/CD Deployment (Automated)

When you push to `main` branch:

1. **GitHub Actions Workflow Triggers:**
   ```yaml
   on:
     push:
       branches: [ main, master ]
     pull_request:
       branches: [ main, master ]
   ```

2. **Workflow Stages:**
   - **Test Job:** Runs `flutter analyze` and `flutter test`
   - **Build Web Job:** Builds web app artifact
   - **Deploy Vercel Job:** Deploys to Vercel (conditional on main branch)

3. **Prerequisites for Automatic Deployment:**
   - Add GitHub secrets:
     - `VERCEL_TOKEN` - Vercel API token
     - `VERCEL_ORG_ID` - Vercel organization ID
     - `VERCEL_PROJECT_ID` - Vercel project ID

4. **Automatic Flow:**
   ```
   Push to main → Run Tests → Build Web → Deploy to Vercel
   ```

5. **Manual Deployment (No Secrets):**
   - Upload web build artifact
   - Manual Vercel deployment required

---

## Build & Deployment Checklist

### Before Deploying

**Code Quality:**
- [ ] All tests pass: `flutter test`
- [ ] No analysis errors: `flutter analyze`
- [ ] No linter warnings
- [ ] Code formatted: `flutter format .`

**Configuration:**
- [ ] Environment variables updated (for mobile)
- [ ] API keys configured (Google Maps)
- [ ] CORS settings correct
- [ ] Build configuration correct

**Testing:**
- [ ] Local build successful: `flutter build web --release`
- [ ] Manual deployment test passed
- [ ] All features work in built app
- [ ] No console errors

**For CI/CD Deployment:**
- [ ] GitHub secrets configured (if using automatic deployment)
- [ ] CI/CD workflow enabled
- [ ] Secrets tested in pull requests
- [ ] Production environment configured

**For Manual Deployment:**
- [ ] Deployment script executable: `chmod +x scripts/deploy-web.sh`
- [ ] Flutter SDK installed and in PATH
- [ ] Vercel CLI installed: `npm install -g vercel`
- [ ] Vercel logged in: `vercel login`

---

## Quick Commands

```bash
# Check current branch
git branch

# Check git status
git status

# View branches
git branch -a

# Switch branch
git checkout <branch>

# Create and switch branch
git checkout -b <branch-name>

# Pull latest changes
git pull origin main

# Push branch
git push -u origin <branch>

# Merge main into current branch
git merge main

# Rebase on main
git rebase origin/main

# Stash changes
git stash

# List stashed changes
git stash list

# Apply stashed changes
git stash pop

# Commit changes
git add . && git commit -m "type: message"

# Verify commit
git log --oneline -5
```

---

## CI/CD Workflow Details

### GitHub Actions Workflow

**File:** `.github/workflows/flutter-ci.yml`

**Jobs:**

1. **test** (runs on push/PR)
   ```yaml
   - flutter analyze
   - flutter test --coverage
   ```

2. **build-web** (depends on test)
   ```yaml
   - flutter build web --release
   - Upload artifact: web-build
   ```

3. **deploy-vercel** (depends on build-web, conditional on main)
   ```yaml
   - Download artifact
   - Deploy to Vercel with --prod flag
   ```

**Workflow Triggers:**
- Push to `main` or `master` branch
- Pull request to `main` or `master` branch

**Deployment Environments:**
- **Production:** Automatic deployment when pushing to main
- **Preview:** Manual deployment (artifact available)

**Dependencies:**
- Flutter 3.24.0

**Required GitHub Secrets:**
- `VERCEL_TOKEN` - For Vercel authentication
- `VERCEL_ORG_ID` - Vercel organization identifier
- `VERCEL_PROJECT_ID` - Vercel project identifier

---

## Scripts Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/deploy-web.sh` | Automated web deployment | `./scripts/deploy-web.sh [production\|preview]` |
| `scripts/start_debug_session.sh` | Start debug session on Pi | `./scripts/start_debug_session.sh` |
| `scripts/phase1_*.sh` | Infrastructure setup scripts | Run as root |

---

## Environment Variables

### Frontend (.env for Mobile)

```env
DEV_API_BASE_URL=http://localhost:3000
PROD_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu
ENVIRONMENT=development
GOOGLE_MAPS_API_KEY=your_key
API_TIMEOUT=30000
```

### Frontend (Hardcoded for Web)

```dart
'DEV_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
'PROD_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
'ENVIRONMENT': 'development',
'GOOGLE_MAPS_API_KEY': 'AIzaSyCj7NygIqVX9qpdYhtmiksowqfjOHyHshQ',
'API_TIMEOUT': '30000',
```

### Backend (backend/.env)

```env
NODE_ENV=development
PORT=3000
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=motorbike_parking_app
DB_USER=motorbike_app
DB_PASSWORD=your_password
JWT_SECRET=your_secret
JWT_EXPIRES_IN=7d
CORS_ORIGIN=http://localhost:3000,https://homelab-backendpi.pedroocalado.eu,https://motorbike-web.vercel.app
```

---

## Troubleshooting

### Git Issues

**Problem:** "fatal: not a git repository"

**Solution:**
```bash
cd /home/pedroocalado/motorbike_app
git init
git remote add origin https://github.com/SilentCaMXMF/MotorBike-Parking-App.git
git fetch origin
git checkout -b main origin/main
```

**Problem:** Merge conflicts

**Solution:**
```bash
# Accept theirs (use remote version)
git checkout --theirs .
git add .
git commit

# Or accept ours (use local version)
git checkout --ours .
git add .
git commit

# Or resolve manually
git diff --name-only --diff-filter=U
# Edit conflict files
git add conflict-files
git commit
```

### Build Issues

**Problem:** Flutter build fails

**Solution:**
```bash
# Clean build
flutter clean

# Update dependencies
flutter pub get

# Check Flutter version
flutter --version

# Try building again
flutter build web --release
```

**Problem:** Deployment script fails

**Solution:**
```bash
# Make script executable
chmod +x scripts/deploy-web.sh

# Run with verbose output
./scripts/deploy-web.sh production 2>&1 | tee deploy.log

# Check vercel login
vercel whoami

# Reinstall vercel if needed
npm install -g vercel
```

### CI/CD Issues

**Problem:** GitHub Actions fails

**Solution:**
```bash
# Check workflow logs in GitHub
# Settings → Actions → Workflows → flutter-ci.yml

# Test locally
flutter test
flutter analyze

# Check for deprecations
flutter pub outdated
```

**Problem:** Vercel deployment fails

**Solution:**
```bash
# Check secrets are set
# GitHub → Settings → Secrets and variables → Actions

# Test deployment manually
cd build/web
vercel --prod --yes

# Check Vercel logs
# Vercel Dashboard → Your Project → Deployments
```

---

## Best Practices

### Commits
- Use conventional commit messages
- Keep commits focused and small
- Test before committing
- Write meaningful commit messages

### Pull Requests
- Update base branch before creating PR
- Include detailed description of changes
- Reference related issues
- Include screenshots for UI changes

### Code Quality
- Run `flutter analyze` before committing
- Run `flutter test` before committing
- Run `flutter format .` before committing
- Address all analysis warnings

### Deployment
- Test locally before deploying
- Use deployment script for consistency
- Follow deployment checklist
- Monitor deployment logs

---

## Resources

- [Git Documentation](https://git-scm.com/doc)
- [Flutter CLI Reference](https://docs.flutter.dev/flutter-tools/cli)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Vercel Documentation](https://vercel.com/docs)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

---

**Last Updated:** March 11, 2026
**Maintained By:** Development Team
**Approved By:** [Team Name/Person]
