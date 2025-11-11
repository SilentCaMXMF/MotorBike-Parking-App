#!/bin/bash
# Phase 1.2: Database Creation Script
# Creates database, user, and grants privileges

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

echo -e "${GREEN}=== Phase 1.2: Database Creation ===${NC}"
echo "Target: $PI_USER@$PI_HOST"
echo ""

# Generate a secure password for the database user if not set
if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-20)
    echo "Generated database password: $DB_PASSWORD"
    # Update .env.pi file
    sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env.pi
    echo -e "${GREEN}✓ Password saved to .env.pi${NC}"
fi

# Function to run MySQL commands on Pi
run_mysql() {
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
        "mysql -u root -p'$DB_ROOT_PASSWORD' -e \"$1\""
}

# Task 1.2.1: Create Database
echo -e "${YELLOW}[1.2.1] Creating database '$DB_NAME'...${NC}"
run_mysql "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
run_mysql "SHOW DATABASES LIKE '$DB_NAME';"
echo -e "${GREEN}✓ Database created${NC}"
echo ""

# Task 1.2.2: Create Database User
echo -e "${YELLOW}[1.2.2] Creating database user '$DB_USER'...${NC}"
run_mysql "CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';"
echo -e "${GREEN}✓ User created${NC}"
echo ""

# Task 1.2.3: Grant Privileges
echo -e "${YELLOW}[1.2.3] Granting privileges...${NC}"
run_mysql "GRANT SELECT, INSERT, UPDATE, DELETE ON $DB_NAME.* TO '$DB_USER'@'%';"
run_mysql "FLUSH PRIVILEGES;"
run_mysql "SHOW GRANTS FOR '$DB_USER'@'%';"
echo -e "${GREEN}✓ Privileges granted${NC}"
echo ""

echo -e "${GREEN}=== Phase 1.2 Complete ===${NC}"
echo ""
echo -e "${YELLOW}Database Credentials:${NC}"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASSWORD"
echo "  Host: $DB_HOST:$DB_PORT"
echo ""
echo -e "${YELLOW}Next step:${NC}"
echo "  Run: ./scripts/phase1_import.sh"
