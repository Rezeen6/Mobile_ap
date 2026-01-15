#!/bin/bash
# Setup USB Connection for Android Device
# This script sets up ADB reverse port forwarding so the app can connect to backend via USB

echo "🔌 Setting up USB connection for Android device..."

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "❌ Error: ADB (Android Debug Bridge) is not installed or not in PATH"
    echo "   Please install Android SDK Platform Tools"
    exit 1
fi

# Check if device is connected
echo "📱 Checking for connected devices..."
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ No Android device found via USB"
    echo ""
    echo "Please:"
    echo "1. Connect your Android phone via USB cable"
    echo "2. Enable USB Debugging:"
    echo "   Settings → About Phone → Tap 'Build Number' 7 times"
    echo "   Settings → Developer Options → Enable 'USB Debugging'"
    echo "3. On your phone, tap 'Allow USB Debugging' when prompted"
    exit 1
fi

echo "✅ Found $DEVICE_COUNT device(s) connected"

# Remove existing reverse forwarding if any
echo "🔄 Removing existing port forwarding..."
adb reverse --remove tcp:8000 2>/dev/null

# Set up reverse port forwarding
echo "🔗 Setting up reverse port forwarding (device:8000 → host:8000)..."
adb reverse tcp:8000 tcp:8000

if [ $? -eq 0 ]; then
    echo "✅ Port forwarding established!"
    echo ""
    echo "📋 Connection Details:"
    echo "   Device → Host: localhost:8000 → localhost:8000"
    echo "   App URL: http://localhost:8000/api/v1"
    echo ""
    echo "💡 Your mobile app can now connect to the backend via USB"
    echo "   Make sure the backend is running:"
    echo "   cd ../backend && python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000"
else
    echo "❌ Failed to set up port forwarding"
    exit 1
fi

# List all reverse forwards
echo ""
echo "📋 Active port forwards:"
adb reverse --list

