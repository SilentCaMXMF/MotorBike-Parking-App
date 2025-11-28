# Debug Sessions Archive

This directory contains captured debug session logs from physical device testing.

## File Naming Convention

`session_YYYYMMDD_HHMMSS.log` - Raw log capture  
`results_YYYYMMDD_HHMMSS.md` - Analyzed results using DEBUG_SESSION_TEMPLATE.md

## Purpose

These logs help verify that:
- All debug logging points are functioning
- The parking zones fetch flow works correctly
- API calls are properly logged
- Polling mechanism operates as expected

## How to Add a Session

1. Run the test following `docs/DEBUG_SESSION_GUIDE.md`
2. Save the captured log file here
3. Fill out a results document using `DEBUG_SESSION_TEMPLATE.md`
4. Name files with timestamp for easy tracking

## Quick Analysis

To search across all sessions:

```bash
# Find all successful API calls
grep "Response status: 200" debug_sessions/*.log

# Find all polling events
grep "Polling parking zones" debug_sessions/*.log

# Find any errors
grep -i "error\|exception\|failed" debug_sessions/*.log
```

## Requirements Tracking

Each session should validate:
- **1.1**: MapScreen initialization logging
- **1.2**: Location service logging  
- **1.3**: Parking zones fetch logging
- **1.4**: API service detailed logging
- **1.5**: Polling mechanism logging
