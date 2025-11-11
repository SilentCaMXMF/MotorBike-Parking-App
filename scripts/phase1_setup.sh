#!/bin/bash
# Phase 1: Raspberry Pi Database Setup Script
# This script automates the MariaDB installation and configuration

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

echo -e "${GREEN}=== Phase 1: Raspberry Pi Database Setup ===${NC}"
echo "Target: $PI_USER@$PI_HOST"
echo ""

# Function to run commands on Pi
run_on_pi() {
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "$1"
}

# Function to copy files to Pi
copy_to_pi() {
    sshpass -p "$PI_PASSWORD" scp -o StrictHostKeyChecking=no "$1" "$PI_USER@$PI_HOST:$2"
}

# Task 1.1.1: Update Raspberry Pi OS
echo -e "${YELLOW}[1.1.1] Updating Raspberry Pi OS...${NC}"
run_on_pi "sudo apt update && sudo apt upgrade -y"
echo -e "${GREEN}✓ OS updated${NC}"
echo ""

# Task 1.1.2: Install MariaDB Server
echo -e "${YELLOW}[1.1.2] Installing MariaDB Server...${NC}"
run_on_pi "sudo apt install mariadb-server mariadb-client -y"
run_on_pi "mysql --version"
echo -e "${GREEN}✓ MariaDB installed${NC}"
echo ""

# Task 1.1.3: Start and Enable MariaDB Service
echo -e "${YELLOW}[1.1.3] Starting MariaDB Service...${NC}"
run_on_pi "sudo systemctl start mariadb"
run_on_pi "sudo systemctl enable mariadb"
run_on_pi "sudo systemctl status mariadb --no-pager | head -5"
echo -e "${GREEN}✓ MariaDB service started and enabled${NC}"
echo ""

echo -e "${GREEN}=== Phase 1.1 Complete ===${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run secure installation: ./scripts/phase1_secure.sh"
echo "2. Create database and user: ./scripts/phase1_database.sh"
echo "3. Import schema: ./scripts/phase1_import.sh"
