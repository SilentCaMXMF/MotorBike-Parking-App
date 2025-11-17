#!/bin/bash

# Example Debug Session Workflow for Motorbike Parking App
# This script demonstrates a complete debugging workflow from device connection
# through log capture, analysis, and export.

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_PACKAGE="com.pedroocalado.motorbikeparking"
SESSION_NAME="debug_session_$(date +%Y%m%d_%H%M%S)"
LOG_DIR="logs/$SESSION_NAME"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

# Function to print colored messages
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Function to check if ADB is installed
check_adb() {
    if ! command -v adb &> /dev/null; then
        print_error "ADB is not installed or not in PATH"
        echo "Please install Android SDK Platform Tools"
        exit 1
    fi
    print_success "ADB is installed"
}

# Function to check device connection
check_device() {
    print_step "Checking for connected devices..."
    DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)
    
    if [ "$DEVICE_COUNT" -eq 0 ]; then
        print_error "No devices connected"
        echo ""
        echo "Please connect an Android device via USB and enable USB debugging"
        echo "Or connect via WiFi using: adb connect <device_ip>:5555"
        exit 1
    elif [ "$DEVICE_COUNT" -gt 1 ]; then
        print_warning "Multiple devices connected. Using first device."
        echo "To specify a device, use: export ANDROID_SERIAL=<device_id>"
    fi
    
    DEVICE_ID=$(adb devices | grep -v "List" | grep "device$" | head -1 | awk '{print $1}')
    print_success "Connected to device: $DEVICE_ID"
}

# Function to gather device information
gather_device_info() {
    print_step "Gathering device information..."
    
    mkdir -p "$LOG_DIR"
    
    DEVICE_MODEL=$(adb shell getprop ro.product.model | tr -d '\r')
    ANDROID_VERSION=$(adb shell getprop ro.build.version.release | tr -d '\r')
    SDK_VERSION=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
    
    cat > "$LOG_DIR/device_info.txt" << EOF
=== Device Information ===
Device ID: $DEVICE_ID
Model: $DEVICE_MODEL
Android Version: $ANDROID_VERSION
SDK Version: $SDK_VERSION
Session: $SESSION_NAME
Started: $(date)
==========================
EOF
    
    # Save full device properties
    adb shell getprop > "$LOG_DIR/device_properties.txt"
    
    print_success "Device info saved to $LOG_DIR/device_info.txt"
    echo "  Model: $DEVICE_MODEL"
    echo "  Android: $ANDROID_VERSION (SDK $SDK_VERSION)"
}

# Function to check if APK exists
check_apk() {
    if [ ! -f "$APK_PATH" ]; then
        print_warning "APK not found at $APK_PATH"
        echo ""
        echo "Building release APK..."
        flutter build apk --release
        
        if [ ! -f "$APK_PATH" ]; then
            print_error "Failed to build APK"
            exit 1
        fi
    fi
    print_success "APK found: $APK_PATH"
}

# Function to install APK
install_apk() {
    print_step "Installing APK on device..."
    
    # Check if app is already installed
    if adb shell pm list packages | grep -q "$APP_PACKAGE"; then
        print_warning "App already installed. Reinstalling..."
        adb install -r "$APK_PATH"
    else
        adb install "$APK_PATH"
    fi
    
    print_success "APK installed successfully"
}

# Function to clear logcat buffer
clear_logs() {
    print_step "Clearing logcat buffer..."
    adb logcat -c
    print_success "Logcat buffer cleared"
}

# Function to start log capture
start_log_capture() {
    print_step "Starting log capture..."
    
    # Start full log capture in background
    adb logcat -v threadtime > "$LOG_DIR/logcat_full.txt" &
    LOGCAT_PID=$!
    echo $LOGCAT_PID > "$LOG_DIR/logcat.pid"
    
    # Start filtered log capture (errors only)
    adb logcat -v threadtime *:E > "$LOG_DIR/logcat_errors.txt" &
    LOGCAT_ERROR_PID=$!
    echo $LOGCAT_ERROR_PID > "$LOG_DIR/logcat_errors.pid"
    
    # Start Flutter-specific log capture
    adb logcat -v threadtime | grep -E "flutter|DartVM" > "$LOG_DIR/logcat_flutter.txt" &
    LOGCAT_FLUTTER_PID=$!
    echo $LOGCAT_FLUTTER_PID > "$LOG_DIR/logcat_flutter.pid"
    
    print_success "Log capture started (PIDs: $LOGCAT_PID, $LOGCAT_ERROR_PID, $LOGCAT_FLUTTER_PID)"
    echo "  Full logs: $LOG_DIR/logcat_full.txt"
    echo "  Errors only: $LOG_DIR/logcat_errors.txt"
    echo "  Flutter logs: $LOG_DIR/logcat_flutter.txt"
}

# Function to launch app
launch_app() {
    print_step "Launching app..."
    adb shell am start -n "$APP_PACKAGE/.MainActivity"
    sleep 2
    print_success "App launched"
}

# Function to monitor logs in real-time
monitor_logs() {
    print_header "MONITORING LOGS"
    echo "Watching for errors and Flutter logs..."
    echo "Press Ctrl+C to stop monitoring and continue to analysis"
    echo ""
    
    # Monitor errors and Flutter logs in real-time
    adb logcat -v time *:E | grep -E "flutter|$APP_PACKAGE|DartVM" || true
}

# Function to stop log capture
stop_log_capture() {
    print_step "Stopping log capture..."
    
    if [ -f "$LOG_DIR/logcat.pid" ]; then
        kill $(cat "$LOG_DIR/logcat.pid") 2>/dev/null || true
        rm "$LOG_DIR/logcat.pid"
    fi
    
    if [ -f "$LOG_DIR/logcat_errors.pid" ]; then
        kill $(cat "$LOG_DIR/logcat_errors.pid") 2>/dev/null || true
        rm "$LOG_DIR/logcat_errors.pid"
    fi
    
    if [ -f "$LOG_DIR/logcat_flutter.pid" ]; then
        kill $(cat "$LOG_DIR/logcat_flutter.pid") 2>/dev/null || true
        rm "$LOG_DIR/logcat_flutter.pid"
    fi
    
    # Give processes time to finish writing
    sleep 1
    
    print_success "Log capture stopped"
}

# Function to analyze logs
analyze_logs() {
    print_header "ANALYZING LOGS"
    
    print_step "Running log analysis..."
    
    # Create analysis report
    ANALYSIS_FILE="$LOG_DIR/analysis_report.txt"
    
    cat > "$ANALYSIS_FILE" << EOF
=== Log Analysis Report ===
Session: $SESSION_NAME
Generated: $(date)
===========================

EOF
    
    # Count log entries by level
    echo "=== Log Level Summary ===" >> "$ANALYSIS_FILE"
    echo "Errors: $(grep -c "E/" "$LOG_DIR/logcat_full.txt" || echo 0)" >> "$ANALYSIS_FILE"
    echo "Warnings: $(grep -c "W/" "$LOG_DIR/logcat_full.txt" || echo 0)" >> "$ANALYSIS_FILE"
    echo "Info: $(grep -c "I/" "$LOG_DIR/logcat_full.txt" || echo 0)" >> "$ANALYSIS_FILE"
    echo "" >> "$ANALYSIS_FILE"
    
    # Flutter errors
    echo "=== Flutter Errors ===" >> "$ANALYSIS_FILE"
    grep -i "E/flutter" "$LOG_DIR/logcat_full.txt" >> "$ANALYSIS_FILE" 2>/dev/null || echo "No Flutter errors found" >> "$ANALYSIS_FILE"
    echo "" >> "$ANALYSIS_FILE"
    
    # Exceptions
    echo "=== Exceptions ===" >> "$ANALYSIS_FILE"
    grep -i "exception" "$LOG_DIR/logcat_full.txt" >> "$ANALYSIS_FILE" 2>/dev/null || echo "No exceptions found" >> "$ANALYSIS_FILE"
    echo "" >> "$ANALYSIS_FILE"
    
    # Network errors
    echo "=== Network Errors ===" >> "$ANALYSIS_FILE"
    grep -iE "network.*error|http.*error|connection.*fail|socket.*exception" "$LOG_DIR/logcat_full.txt" >> "$ANALYSIS_FILE" 2>/dev/null || echo "No network errors found" >> "$ANALYSIS_FILE"
    echo "" >> "$ANALYSIS_FILE"
    
    # Stack traces
    echo "=== Stack Traces ===" >> "$ANALYSIS_FILE"
    grep -A 10 "StackTrace" "$LOG_DIR/logcat_full.txt" >> "$ANALYSIS_FILE" 2>/dev/null || echo "No stack traces found" >> "$ANALYSIS_FILE"
    echo "" >> "$ANALYSIS_FILE"
    
    print_success "Analysis complete: $ANALYSIS_FILE"
    
    # Display summary
    echo ""
    echo "=== Quick Summary ==="
    grep "Log Level Summary" -A 4 "$ANALYSIS_FILE"
}

# Function to export logs
export_logs() {
    print_header "EXPORTING LOGS"
    
    print_step "Creating compressed archive..."
    
    ARCHIVE_NAME="debug_logs_${SESSION_NAME}.tar.gz"
    tar -czf "$ARCHIVE_NAME" "$LOG_DIR"
    
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_NAME" | cut -f1)
    
    print_success "Logs exported to: $ARCHIVE_NAME ($ARCHIVE_SIZE)"
    echo ""
    echo "Archive contents:"
    echo "  - device_info.txt: Device specifications"
    echo "  - device_properties.txt: Full device properties"
    echo "  - logcat_full.txt: Complete log capture"
    echo "  - logcat_errors.txt: Error-level logs only"
    echo "  - logcat_flutter.txt: Flutter-specific logs"
    echo "  - analysis_report.txt: Automated analysis results"
}

# Function to display next steps
show_next_steps() {
    print_header "NEXT STEPS"
    
    echo "1. Review the analysis report:"
    echo "   cat $LOG_DIR/analysis_report.txt"
    echo ""
    echo "2. Search for specific errors:"
    echo "   grep -i 'your_error' $LOG_DIR/logcat_full.txt"
    echo ""
    echo "3. Filter by component:"
    echo "   grep '\[Network\]' $LOG_DIR/logcat_flutter.txt"
    echo ""
    echo "4. View errors with context:"
    echo "   grep -B 5 -A 10 'Exception' $LOG_DIR/logcat_full.txt"
    echo ""
    echo "5. Share logs with team:"
    echo "   Send the archive: $ARCHIVE_NAME"
    echo ""
    echo "6. Run custom analysis:"
    echo "   ./scripts/analyze_logs.sh $LOG_DIR/logcat_full.txt"
    echo ""
    echo "7. Start a new debug session:"
    echo "   ./scripts/example_debug_session.sh"
    echo ""
}

# Cleanup function for interrupts
cleanup() {
    echo ""
    print_warning "Interrupted. Cleaning up..."
    stop_log_capture
    exit 1
}

trap cleanup INT TERM

# Main workflow
main() {
    print_header "MOTORBIKE PARKING APP - DEBUG SESSION"
    
    echo "This script will:"
    echo "  1. Check device connection"
    echo "  2. Gather device information"
    echo "  3. Install/update the APK"
    echo "  4. Capture logs during app execution"
    echo "  5. Analyze logs for errors and issues"
    echo "  6. Export logs for sharing"
    echo ""
    
    # Step 1: Prerequisites
    print_header "STEP 1: CHECKING PREREQUISITES"
    check_adb
    check_device
    check_apk
    
    # Step 2: Device Setup
    print_header "STEP 2: DEVICE SETUP"
    gather_device_info
    install_apk
    
    # Step 3: Log Capture
    print_header "STEP 3: LOG CAPTURE"
    clear_logs
    start_log_capture
    launch_app
    
    echo ""
    print_success "Debug session is now active!"
    echo ""
    echo "The app is running and logs are being captured."
    echo "Please interact with the app to reproduce any issues."
    echo ""
    read -p "Press Enter when you're done testing (or Ctrl+C to abort)..."
    
    # Step 4: Stop and Analyze
    stop_log_capture
    analyze_logs
    
    # Step 5: Export
    export_logs
    
    # Step 6: Next Steps
    show_next_steps
    
    print_header "DEBUG SESSION COMPLETE"
    print_success "Session saved to: $LOG_DIR"
    print_success "Archive created: $ARCHIVE_NAME"
}

# Run main workflow
main
