#!/bin/bash

# Integration Test Runner
# This script helps run integration tests with proper setup

set -e

echo "=================================="
echo "Integration Test Runner"
echo "=================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if backend is running
echo "Checking backend server..."
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend server is running${NC}"
else
    echo -e "${RED}✗ Backend server is not running${NC}"
    echo ""
    echo "Please start the backend server first:"
    echo "  cd backend"
    echo "  npm run dev"
    echo ""
    exit 1
fi

echo ""
echo "Running integration tests..."
echo ""

# Run the tests
flutter test integration_test/ --verbose

echo ""
echo -e "${GREEN}Integration tests completed!${NC}"
