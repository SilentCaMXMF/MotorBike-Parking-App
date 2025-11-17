#!/bin/bash

# start_debug_session.sh - Automated log capture setup for APK debugging
# Usage: ./start_debug_session.sh [session_description]

SESSION_DESC=${1:-"debug_session"}
SESSION_NAME="debug_$(date +%Y%m%d_%H%M%S)"
SESSION_DIR="logs/$SESSION_NAME"

echo "=========================================="
echo "Starting Debug Session"
echo "Session: $SESSION_NAME"
echo "Description: $SESSION_DESC"
echo "=========================================="

# Create session directory
mkdir -p "$SESSION_DIR"

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "Error: ADB not found. Please install Android SDK Platform Tools."
    exit 1
fi

# Check for connected devices
echo -e "\n[1/6] Checking for connected devices..."
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "Error: No Android devices connected."
    echo "Please connect a device and enable USB debugging."
    exit 1
fi

echo "✓ Found $DEVICE_COUNT device(s)"

# If multiple devices, let user select
if [ "$DEVICE_COUNT" -gt 1 ]; then
    echo "Multiple devices detected:"
    adb devices
    echo "Please specify device with: export ANDROID_SERIAL=<device_id>"
    exit 1
fi

# Capture device information
echo -e "\n[2/6] Capturing device information..."
adb shell getprop > "$SESSION_DIR/device_info.txt"

DEVICE_MODEL=$(adb shell getprop ro.product.model | tr -d '\r')
DEVICE_ID=$(adb shell getprop ro.serialno | tr -d '\r')
ANDROID_VERSION=$(adb shell getprop ro.build.version.release | tr -d '\r')
SDK_VERSION=$(adb shell getprop ro.build.version.sdk | tr -d '\r')

echo "Device: $DEVICE_MODEL"
echo "Android: $ANDROID_VERSION (SDK $SDK_VERSION)"
echo "Serial: $DEVICE_ID"

# Capture app information
echo -e "\n[3/6] Capturing app information..."
PACKAGE_NAME="com.pedroocalado.motorbikeparking"
APP_VERSION=$(adb shell dumpsys package "$PACKAGE_NAME" | grep versionName | head -1 | awk '{print $1}' | cut -d'=' -f2 || echo "unknown")
BUILD_TYPE="unknown"

# Try to determine build type from app
if adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
    echo "App installed: $PACKAGE_NAME"
    echo "Version: $APP_VERSION"
else
    echo "Warning: App not installed on device"
fi

# Create session metadata file
cat > "$SESSION_DIR/session_metadata.txt" << EOF
=== Debug Session Metadata ===
Session ID: $SESSION_NAME
Description: $SESSION_DESC
Started: $(date)

Device Information:
- Model: $DEVICE_MODEL
- Serial: $DEVICE_ID
- Android Version: $ANDROID_VERSION
- SDK Version: $SDK_VERSION

App Information:
- Package: $PACKAGE_NAME
- Version: $APP_VERSION
- Build Type: $BUILD_TYPE

Session Directory: $SESSION_DIR
==============================
EOF

echo "✓ Metadata saved to $SESSION_DIR/session_metadata.txt"

# Clear logcat buffer
echo -e "\n[4/6] Clearing logcat buffer..."
adb logcat -c
echo "✓ Logcat buffer cleared"

# Start log capture
echo -e "\n[5/6] Starting log capture..."
LOG_FILE="$SESSION_DIR/logcat.txt"

echo "Capturing logs to: $LOG_FILE"
echo "Press Ctrl+C to stop logging"
echo ""

# Create a trap to handle cleanup on exit
cleanup() {
    echo -e "\n\n[6/6] Stopping log capture..."
    
    # Analyze the captured logs
    if [ -f "$LOG_FILE" ]; then
        echo "Analyzing logs..."
        bash "$(dirname "$0")/analyze_logs.sh" "$LOG_FILE" > "$SESSION_DIR/analysis.txt" 2>&1
        
        echo "✓ Analysis saved to $SESSION_DIR/analysis.txt"
        
        # Show quick summary
        echo -e "\n=========================================="
        echo "Debug Session Complete"
        echo "=========================================="
        echo "Session: $SESSION_NAME"
        echo "Duration: $(date)"
        echo ""
        echo "Files created:"
        echo "  - $SESSION_DIR/logcat.txt (raw logs)"
        echo "  - $SESSION_DIR/analysis.txt (analysis report)"
        echo "  - $SESSION_DIR/device_info.txt (device properties)"
        echo "  - $SESSION_DIR/session_metadata.txt (session info)"
        echo ""
        echo "To view analysis:"
        echo "  cat $SESSION_DIR/analysis.txt"
        echo ""
        echo "To search logs:"
        echo "  grep -i 'error' $SESSION_DIR/logcat.txt"
        echo "=========================================="
    fi
    
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start capturing logs with threadtime format
adb logcat -v threadtime > "$LOG_FILE" 2>&1 &
LOGCAT_PID=$!

echo "Logging started (PID: $LOGCAT_PID)"
echo ""
echo "Tip: In another terminal, you can:"
echo "  - Install APK: adb install -r path/to/app.apk"
echo "  - Launch app: adb shell am start -n $PACKAGE_NAME/.MainActivity"
echo "  - Filter errors: tail -f $LOG_FILE | grep -i error"
echo ""

# Wait for the logcat process
wait $LOGCAT_PID
