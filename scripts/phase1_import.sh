#!/bin/bash
# Phase 1.3: Schema Import Script
# Transfers and imports the database schema

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load configuration
if [ -f .env.pi ]; then
    source .env.pi
else
    echo -e "${RED}Error: .env.pi file not found${NC}"
    exit 1
fi

echo -e "${GREEN}=== Phase 1.3: Schema Import ===${NC}"
echo "Target: $PI_USER@$PI_HOST"
echo ""

# Check if schema.sql exists
if [ ! -f "schema.sql" ]; then
    echo -e "${RED}Error: schema.sql not found${NC}"
    exit 1
fi

# Task 1.3.1: Transfer schema.sql to Raspberry Pi
echo -e "${YELLOW}[1.3.1] Transferring schema.sql to Raspberry Pi...${NC}"
sshpass -p "$PI_PASSWORD" scp -o StrictHostKeyChecking=no schema.sql "$PI_USER@$PI_HOST:/tmp/schema.sql"
echo -e "${GREEN}✓ Schema file transferred${NC}"
echo ""

# Task 1.3.2: Import Database Schema
echo -e "${YELLOW}[1.3.2] Importing database schema...${NC}"
echo "This may take a minute..."
sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "mysql -u root -p'$DB_ROOT_PASSWORD' $DB_NAME < /tmp/schema.sql 2>&1"
echo -e "${GREEN}✓ Schema imported${NC}"
echo ""

# Task 1.3.3: Verify Schema Import
echo -e "${YELLOW}[1.3.3] Verifying schema import...${NC}"

# Check tables
echo "Checking tables..."
TABLES=$(sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "mysql -u root -p'$DB_ROOT_PASSWORD' $DB_NAME -e 'SHOW TABLES;' 2>/dev/null")
echo "$TABLES"

# Check schema version
echo ""
echo "Checking schema version..."
VERSION=$(sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "mysql -u root -p'$DB_ROOT_PASSWORD' $DB_NAME -e 'SELECT * FROM schema_version;' 2>/dev/null")
echo "$VERSION"

echo -e "${GREEN}✓ Schema verified${NC}"
echo ""

echo -e "${GREEN}=== Phase 1.3 Complete ===${NC}"
echo ""
echo -e "${YELLOW}Next step:${NC}"
echo "  Run: ./scripts/phase1_verify.sh"
