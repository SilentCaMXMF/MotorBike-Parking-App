# Deployment Guide - Motorbike Parking App

**Updated:** March 11, 2026  
**Status:** ✅ Production Active

---

## Deployment Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    🌐 INTERNET                                │
│                                                             │
│  ┌──────────────────────┐    ┌──────────────────────┐      │
│  │  Flutter Web App     │    │  Backend API         │      │
│  │                      │    │                      │      │
│  │  https://              │    │  https://               │      │
│  │  motorbike-web        │    │  homelab-backendpi     │      │
│  │  .vercel.app          │    │  .pedroocalado.eu      │      │
│  └──────────┬───────────┘    └──────────┬───────────┘      │
│             │                            │                   │
│             └────────────┬───────────────┘                   │
│                          │                                   │
│                          ▼                                   │
│                 ┌────────────────────┐                       │
│                 │  Flutter API Client │                       │
│                 │  (lib/services/)    │                       │
│                 └──────────┬─────────┘                       │
│                            │                                 │
│                            ▼                                 │
│                 ┌────────────────────┐                       │
│                 │  Environment Config │                       │
│                 │  (environment.dart) │                       │
│                 └────────────────────┘                       │
└──────────────────────────────────────────────────────────────┘
```

---

## Deployment Options

### Option 1: Automated CI/CD (Recommended)

**Best for:** Production deployments with automated testing and building

**Workflow:**
1. Push to main branch
2. GitHub Actions runs tests and builds
3. Vercel automatically deploys

**Setup:**
1. Add secrets to GitHub:
   - `VERCEL_TOKEN` - Your Vercel API token
   - `VERCEL_ORG_ID` - Your Vercel organization ID
   - `VERCEL_PROJECT_ID` - Your Vercel project ID

2. The workflow automatically:
   - Analyzes code with `flutter analyze`
   - Runs tests with coverage
   - Builds web app
   - Deploys to Vercel (production)

**Pros:**
- Automated and reliable
- Always deploys the latest tested code
- Integrated with GitHub

**Cons:**
- Requires secrets setup
- No control over deployment environment

---

### Option 2: Manual Local Build (For Development)

**Best for:** Testing, preview builds, fine-grained control

**Steps:**

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Check code quality:**
   ```bash
   flutter analyze
   ```

3. **Run tests:**
   ```bash
   flutter test
   ```

4. **Build web app:**
   ```bash
   flutter build web --release
   ```

5. **Deploy to Vercel:**
   ```bash
   cd build/web
   vercel deploy --prod --yes
   ```

**Using the deployment script:**
```bash
./scripts/deploy-web.sh [production|preview]
```

**Pros:**
- Full control over build process
- Can test before deploying
- No GitHub secrets needed

**Cons:**
- Manual process
- Higher chance of deployment errors

---

### Option 3: CI/CD Only (Automated Build)

**Best for:** Pure automated deployment without secrets

**Workflow:**
1. Push to main branch
2. GitHub Actions builds web app
3. Build artifact uploaded
4. Manual Vercel deployment

**Pros:**
- No secrets required
- Automated building

**Cons:**
- Still needs manual Vercel deployment
- Not fully automated

---

## Live URLs

| Service | URL | Status |
|---------|-----|--------|
| Web App (Vercel) | https://motorbike-web.vercel.app | ✅ Active |
| Backend API (Cloudflare) | https://homelab-backendpi.pedroocalado.eu | ✅ Active |

---

## Environment Configuration

### Frontend (Web/Mobile)

**Web app uses hardcoded values:**
```dart
'DEV_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
'PROD_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
'GOOGLE_MAPS_API_KEY': 'AIzaSyCj7NygIqVX9qpdYhtmiksowqfjOHyHshQ',
'API_TIMEOUT': '30000',
```

**Mobile app uses .env file:**
```env
DEV_API_BASE_URL=http://localhost:3000
PROD_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu
GOOGLE_MAPS_API_KEY=your_google_maps_key_here
API_TIMEOUT=30000
```

### Backend (Raspberry Pi)

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
```

---

## Deployment Checklist

### Before Deploying to Vercel:

**Code Quality:**
- [ ] All tests pass (`flutter test`)
- [ ] No analysis errors (`flutter analyze`)
- [ ] No linter warnings

**Configuration:**
- [ ] Environment variables updated (for mobile)
- [ ] API keys configured (Google Maps)
- [ ] CORS settings correct

**Testing:**
- [ ] Local build successful (`flutter build web --release`)
- [ ] Manual deployment test passed
- [ ] All features work in built app

**For CI/CD Deployment:**
- [ ] GitHub secrets configured (if using Vercel deployment)
- [ ] GitHub Actions workflow enabled
- [ ] Secrets tested in pull requests

---

## Troubleshooting

### CI/CD Issues

**Problem:** GitHub Actions fails

**Solutions:**
1. Check workflow logs in GitHub Actions tab
2. Verify Flutter version: `3.24.0`
3. Ensure `flutter pub get` succeeds
4. Test locally: `flutter test`

### Vercel Deployment Issues

**Problem:** Deployment fails

**Solutions:**
1. Check Vercel logs: Dashboard → Your Project → Deployments
2. Verify build output directory is `build/web`
3. Check Vercel environment variables
4. Test deployment locally first

### Build Issues

**Problem:** Flutter build fails

**Solutions:**
1. Clean build: `flutter clean && flutter pub get`
2. Check Flutter version: `flutter --version`
3. Update dependencies: `flutter pub upgrade`
4. Check for deprecated packages

### Connection Issues

**Problem:** API calls fail after deployment

**Solutions:**
1. Verify backend URL in code matches deployed backend
2. Check CORS settings in backend
3. Test backend directly: `curl https://homelab-backendpi.pedroocalado.eu/health`
4. Check Cloudflare tunnel status

---

## Quick Deployment Commands

```bash
# Check current branch
git branch

# Pull latest changes
git pull origin main

# Check if there are uncommitted changes
git status

# Run analysis and tests locally
flutter analyze
flutter test

# Build web release
flutter build web --release

# Deploy to Vercel (manual)
cd build/web
vercel deploy --prod --yes

# Deploy using script (production)
./scripts/deploy-web.sh production

# Deploy using script (preview)
./scripts/deploy-web.sh preview
```

---

## Files Reference

### Deployment Scripts
- `scripts/deploy-web.sh` - Automated web deployment script

### Configuration Files
- `vercel.json` - Vercel configuration (security headers, caching)
- `pubspec.yaml` - Flutter dependencies
- `.env` - Environment variables (mobile only)

### CI/CD
- `.github/workflows/flutter-ci.yml` - GitHub Actions workflow
  - `test` job - Code analysis and testing
  - `build-web` job - Web build artifact
  - `deploy-vercel` job - Vercel deployment (conditional on main branch)

### Documentation
- `docs/GIT_WORKFLOW.md` - Comprehensive Git workflow guide
- `docs/frontend/DEPLOYMENT_GUIDE.md` - Detailed frontend deployment guide
- `docs/backend/CLOUDFLARE_TUNNEL_SETUP.md` - Backend tunnel setup
- `docs/deployment/WEB_DEPLOYMENT_SUMMARY.md` - Web deployment history

---

## Maintenance

### Regular Tasks

1. **Weekly:**
   - Check CI/CD workflow status
   - Review deployment logs
   - Update dependencies

2. **Monthly:**
   - Review and update documentation
   - Test critical features
   - Update security headers if needed

3. **Quarterly:**
   - Full deployment test
   - Dependency audit
   - Performance review

---

## Support & Resources

- [Flutter Deployment Docs](https://docs.flutter.dev/deployment/web)
- [Vercel Documentation](https://vercel.com/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

---

**Last Updated:** March 11, 2026  
**Version:** 2.1
