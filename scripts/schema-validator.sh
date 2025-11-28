#!/bin/bash

# Database Schema Validator for Motorbike Parking App
# Validates production database schema against expected structure

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
HOST="192.168.1.67"
USER="pedroocalado"
DB_NAME="motorbike_parking"
DB_USER="parking_user"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --host)
      HOST="$2"
      shift 2
      ;;
    --user)
      USER="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--host HOST] [--user USER]"
      exit 1
      ;;
  esac
done

echo "========================================="
echo "Database Schema Validation"
echo "========================================="
echo "Host: $HOST"
echo "SSH User: $USER"
echo "Database: $DB_NAME"
echo "========================================="
echo ""

# Track validation results
PASSED=0
FAILED=0

# Function to check if a table exists
check_table() {
  local table_name=$1
  echo -n "Checking table '$table_name'... "
  
  result=$(ssh "$USER@$HOST" "mysql -u $DB_USER -p\$(grep DB_PASSWORD /home/$USER/motorbike-parking-app/backend/.env | cut -d '=' -f2) -D $DB_NAME -se \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME' AND table_name='$table_name';\" 2>/dev/null")
  
  if [ "$result" = "1" ]; then
    echo -e "${GREEN}✅ EXISTS${NC}"
    ((PASSED++))
    return 0
  else
    echo -e "${RED}❌ NOT FOUND${NC}"
    ((FAILED++))
    return 1
  fi
}

# Function to check if a view exists
check_view() {
  local view_name=$1
  echo -n "Checking view '$view_name'... "
  
  result=$(ssh "$USER@$HOST" "mysql -u $DB_USER -p\$(grep DB_PASSWORD /home/$USER/motorbike-parking-app/backend/.env | cut -d '=' -f2) -D $DB_NAME -se \"SELECT COUNT(*) FROM information_schema.views WHERE table_schema='$DB_NAME' AND table_name='$view_name';\" 2>/dev/null")
  
  if [ "$result" = "1" ]; then
    echo -e "${GREEN}✅ EXISTS${NC}"
    ((PASSED++))
    return 0
  else
    echo -e "${RED}❌ NOT FOUND${NC}"
    ((FAILED++))
    return 1
  fi
}

# Function to check if a stored procedure exists
check_procedure() {
  local proc_name=$1
  echo -n "Checking stored procedure '$proc_name'... "
  
  result=$(ssh "$USER@$HOST" "mysql -u $DB_USER -p\$(grep DB_PASSWORD /home/$USER/motorbike-parking-app/backend/.env | cut -d '=' -f2) -D $DB_NAME -se \"SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='$DB_NAME' AND routine_name='$proc_name' AND routine_type='PROCEDURE';\" 2>/dev/null")
  
  if [ "$result" = "1" ]; then
    echo -e "${GREEN}✅ EXISTS${NC}"
    ((PASSED++))
    return 0
  else
    echo -e "${RED}❌ NOT FOUND${NC}"
    ((FAILED++))
    return 1
  fi
}

# Function to check if a trigger exists
check_trigger() {
  local trigger_name=$1
  echo -n "Checking trigger '$trigger_name'... "
  
  result=$(ssh "$USER@$HOST" "mysql -u $DB_USER -p\$(grep DB_PASSWORD /home/$USER/motorbike-parking-app/backend/.env | cut -d '=' -f2) -D $DB_NAME -se \"SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema='$DB_NAME' AND trigger_name='$trigger_name';\" 2>/dev/null")
  
  if [ "$result" = "1" ]; then
    echo -e "${GREEN}✅ EXISTS${NC}"
    ((PASSED++))
    return 0
  else
    echo -e "${RED}❌ NOT FOUND${NC}"
    ((FAILED++))
    return 1
  fi
}

# Test SSH connectivity first
echo "Testing SSH connectivity..."
if ! ssh -o ConnectTimeout=5 "$USER@$HOST" "echo 'SSH connection successful'" > /dev/null 2>&1; then
  echo -e "${RED}❌ Cannot connect to $HOST via SSH${NC}"
  echo "Please ensure:"
  echo "  1. The server is running"
  echo "  2. SSH keys are set up (run: ssh-copy-id $USER@$HOST)"
  echo "  3. The hostname/IP is correct"
  exit 1
fi
echo -e "${GREEN}✅ SSH connection successful${NC}"
echo ""

# Check Tables
echo "=== TABLES ==="
check_table "users"
check_table "parking_zones"
check_table "user_reports"
check_table "report_images"
echo ""

# Check Views
echo "=== VIEWS ==="
check_view "parking_zone_availability"
check_view "recent_user_reports"
echo ""

# Check Stored Procedures
echo "=== STORED PROCEDURES ==="
check_procedure "GetNearbyParkingZones"
check_procedure "CreateUserReport"
echo ""

# Check Triggers
echo "=== TRIGGERS ==="
check_trigger "update_occupancy_on_report_insert"
check_trigger "update_occupancy_on_report_delete"
echo ""

# Summary
echo "========================================="
echo "VALIDATION SUMMARY"
echo "========================================="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo "========================================="

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ All schema validations passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ Schema validation failed. Please review the errors above.${NC}"
  exit 1
fi
