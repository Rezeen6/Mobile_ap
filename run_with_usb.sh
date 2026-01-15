#!/bin/bash
# Complete script to run Flutter app with USB connection (no internet needed)
# This sets up ADB reverse port forwarding and runs the app

echo "🚀 Flutter App - USB Connection Setup"
echo "======================================"
echo ""

# Step 1: Setup USB/ADB port forwarding
echo "Step 1: Setting up port forwarding for USB/emulator connection..."
if command -v adb &> /dev/null; then
    # Check if device/emulator is connected
    DEVICE_COUNT=$(adb devices | grep -v "List" | grep -E "device$|emulator" | wc -l)
    
    if [ "$DEVICE_COUNT" -eq 0 ]; then
        echo "⚠️  No device/emulator found via ADB"
        echo "   Starting emulator or connect physical device..."
    else
        echo "✅ Found $DEVICE_COUNT device(s) connected"
        # Remove existing forwarding
        adb reverse --remove tcp:8000 2>/dev/null
        
        # Set up new forwarding (works for both physical device and emulator)
        if adb reverse tcp:8000 tcp:8000; then
            echo "✅ Port forwarding established: device:8000 → host:8000"
            echo "   App will use localhost:8000 (no internet needed!)"
            adb reverse --list
        else
            echo "⚠️  Warning: Could not set up port forwarding"
            echo "   For emulator: App will try to use 10.0.2.2 as fallback"
        fi
    fi
else
    echo "⚠️  Warning: ADB not found. Port forwarding skipped."
    echo "   Install Android SDK Platform Tools for USB connection"
fi

echo ""
echo "Step 2: Checking backend server..."

# Check if backend is running
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Backend is running on port 8000"
else
    echo "⚠️  Backend not detected on port 8000"
    echo ""
    echo "Please start the backend in another terminal:"
    echo "  cd ../backend"
    echo "  source venv/bin/activate"
    echo "  python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "Step 3: Running Flutter app..."
echo ""

# Run Flutter app
cd "$(dirname "$0")"
flutter run

