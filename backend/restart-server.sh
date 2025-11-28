#!/bin/bash

echo "=========================================="
echo "Restarting Backend Server"
echo "=========================================="
echo ""

# Find and kill the running Node.js server
echo "Stopping existing server..."
pkill -f "node.*server.js" 2>/dev/null || pkill -f "npm.*start" 2>/dev/null

# Wait a moment for the process to stop
sleep 2

# Check if port 3000 is still in use
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port 3000 still in use, force killing..."
    kill -9 $(lsof -t -i:3000) 2>/dev/null
    sleep 1
fi

echo "✅ Server stopped"
echo ""
echo "Starting server with updated code..."
echo "=========================================="
echo ""

# Start the server
npm start
