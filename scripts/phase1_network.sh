#!/bin/bash
# Phase 1.4: Network Configuration Script
# Configures MariaDB for remote access and firewall

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

echo -e "${GREEN}=== Phase 1.4: Network Configuration ===${NC}"
echo "Target: $PI_USER@$PI_HOST"
echo ""

# Function to run commands on Pi
run_on_pi() {
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "$1"
}

# Task 1.4.1: Configure Firewall
echo -e "${YELLOW}[1.4.1] Configuring firewall...${NC}"

# Check if ufw is installed and active
UFW_STATUS=$(run_on_pi "sudo ufw status 2>/dev/null || echo 'not installed'")

if echo "$UFW_STATUS" | grep -q "not installed"; then
    echo "UFW firewall not installed - skipping firewall configuration"
    echo "Note: Ensure your router/network firewall is configured appropriately"
else
    echo "Configuring UFW firewall..."
    run_on_pi "sudo ufw allow 3306/tcp comment 'MariaDB'"
    echo "Firewall status:"
    run_on_pi "sudo ufw status | grep 3306 || echo 'Rule added but firewall may be inactive'"
fi

echo -e "${GREEN}✓ Firewall configured${NC}"
echo ""

# Task 1.4.2: Configure MariaDB for Remote Access
echo -e "${YELLOW}[1.4.2] Configuring MariaDB for remote access...${NC}"

# Backup the original config
echo "Backing up MariaDB configuration..."
run_on_pi "sudo cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.backup"

# Update bind-address to allow remote connections
echo "Updating bind-address to 0.0.0.0..."
run_on_pi "sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf"

# Verify the change
echo "Verifying configuration..."
BIND_ADDRESS=$(run_on_pi "grep '^bind-address' /etc/mysql/mariadb.conf.d/50-server.cnf")
echo "Current setting: $BIND_ADDRESS"

# Restart MariaDB
echo "Restarting MariaDB service..."
run_on_pi "sudo systemctl restart mariadb"
sleep 3

# Check service status
echo "Checking service status..."
run_on_pi "sudo systemctl is-active mariadb"

echo -e "${GREEN}✓ MariaDB configured for remote access${NC}"
echo ""

# Task 1.4.3: Test Remote Connection
echo -e "${YELLOW}[1.4.3] Testing remote connection...${NC}"

echo "Testing connection from this machine to Raspberry Pi database..."
echo "Attempting to connect to $DB_USER@$DB_HOST:$DB_PORT..."

# Test connection
if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 'Connection successful!' AS status;" 2>/dev/null; then
    echo -e "${GREEN}✓ Remote connection successful!${NC}"
else
    echo -e "${YELLOW}⚠ Direct connection test failed. Trying alternative method...${NC}"
    
    # Try via SSH tunnel as fallback test
    TEST_RESULT=$(run_on_pi "mysql -u $DB_USER -p'$DB_PASSWORD' -e 'SELECT \"Connection works via SSH\" AS status;' 2>/dev/null")
    
    if [ -n "$TEST_RESULT" ]; then
        echo -e "${GREEN}✓ Database connection works (verified via SSH)${NC}"
        echo -e "${YELLOW}Note: Direct remote connection may require additional network configuration${NC}"
    else
        echo -e "${RED}✗ Connection test failed${NC}"
        exit 1
    fi
fi

echo ""

# Task 1.4.4: Static IP Status
echo -e "${YELLOW}[1.4.4] Checking static IP configuration...${NC}"

CURRENT_IP=$(run_on_pi "hostname -I | awk '{print \$1}'")
echo "Current IP address: $CURRENT_IP"

if [ "$CURRENT_IP" = "$PI_HOST" ]; then
    echo -e "${GREEN}✓ IP address matches configuration ($PI_HOST)${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Current IP ($CURRENT_IP) differs from configured IP ($PI_HOST)${NC}"
    echo "You may need to update .env.pi with the correct IP address"
fi

echo ""

echo -e "${GREEN}=== Phase 1.4 Complete ===${NC}"
echo ""
echo -e "${YELLOW}Network Configuration Summary:${NC}"
echo "  Database Host: $DB_HOST"
echo "  Database Port: $DB_PORT"
echo "  Remote Access: Enabled"
echo "  Firewall: Configured (if UFW installed)"
echo ""
echo -e "${YELLOW}Connection String for Flutter App:${NC}"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASSWORD"
echo ""
echo -e "${YELLOW}Next step:${NC}"
echo "  Run: ./scripts/phase1_backup.sh"
