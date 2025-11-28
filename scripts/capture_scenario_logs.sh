#!/bin/bash

# Simple log capture for a specific scenario
# Usage: ./scripts/capture_scenario_logs.sh <scenario_name>

SCENARIO=$1
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="debug_sessions/scenario_${SCENARIO}_${TIMESTAMP}.log"

if [ -z "$SCENARIO" ]; then
    echo "Usage: $0 <scenario_name>"
    echo "Examples:"
    echo "  $0 offline"
    echo "  $0 invalid_token"
    echo "  $0 404_error"
    echo "  $0 500_error"
    echo "  $0 timeout"
    echo "  $0 retry"
    exit 1
fi

echo "Capturing logs for scenario: $SCENARIO"
echo "Log file: $LOG_FILE"
echo ""
echo "Dumping current logcat buffer..."

# Dump current logcat and filter
adb logcat -d | grep -E "MotorbikeParking|flutter" > "$LOG_FILE"

LINES=$(wc -l < "$LOG_FILE")
echo "Captured $LINES lines"
echo ""
echo "Recent errors:"
grep -i "error" "$LOG_FILE" | tail -5
echo ""
echo "Recent connectivity logs:"
grep -i "connectivity\|offline\|online" "$LOG_FILE" | tail -5
echo ""
echo "Log saved to: $LOG_FILE"
