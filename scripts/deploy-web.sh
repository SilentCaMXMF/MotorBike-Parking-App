#!/bin/bash

# Deploy Web App to Vercel
# Usage: ./deploy-web.sh [environment]
#   environment: production (default), preview

set -e

ENVIRONMENT=${1:-production}

echo "=========================================="
echo "  Motorbike Parking App - Web Deploy"
echo "=========================================="
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Check if Vercel CLI is available
if ! command -v vercel &> /dev/null; then
    echo "Error: Vercel CLI is not installed"
    echo "Install with: npm install -g vercel"
    exit 1
fi

echo "Step 1: Checking Git status..."
if [ -n "$(git status --porcelain)" ]; then
    echo "Warning: You have uncommitted changes:"
    git status --short
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo ""
echo "Step 2: Running Flutter analyze..."
flutter analyze

echo ""
echo "Step 3: Running Flutter tests..."
flutter test || { echo "Tests failed!"; exit 1; }

echo ""
echo "Step 4: Building web release..."
flutter build web --release

echo ""
echo "Step 5: Deploying to Vercel ($ENVIRONMENT)..."
cd build/web

if [ "$ENVIRONMENT" = "preview" ]; then
    vercel --yes
else
    vercel deploy --prod --yes
fi

echo ""
echo "=========================================="
echo "  Deployment complete!"
echo "=========================================="
