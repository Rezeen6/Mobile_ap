#!/bin/bash
# Launch emulator, set up port forwarding, and run Flutter app

echo "🚀 Launching Android Emulator and Setting Up USB Connection"
echo "============================================================"
echo ""

# Check if emulator is already running
if adb devices | grep -q "emulator"; then
    echo "✅ Emulator is already running"
else
    echo "📱 Launching Android Emulator..."
    flutter emulators --launch Medium_Phone_API_36.1 &
    
    echo "⏳ Waiting for emulator to start (this may take 30-60 seconds)..."
    
    # Wait for emulator to be ready (max 2 minutes)
    MAX_WAIT=120
    ELAPSED=0
    while [ $ELAPSED -lt $MAX_WAIT ]; do
        if adb devices | grep -q "emulator.*device"; then
            echo "✅ Emulator is ready!"
            break
        fi
        sleep 2
        ELAPSED=$((ELAPSED + 2))
        if [ $((ELAPSED % 10)) -eq 0 ]; then
            echo "   Still waiting... ($ELAPSED seconds)"
        fi
    done
    
    if ! adb devices | grep -q "emulator.*device"; then
        echo "❌ Emulator failed to start or is taking too long"
        echo "   Try launching manually: flutter emulators --launch Medium_Phone_API_36.1"
        exit 1
    fi
fi

echo ""
echo "🔌 Setting up USB/ADB port forwarding..."

# Set up ADB reverse port forwarding
adb reverse --remove tcp:8000 2>/dev/null
if adb reverse tcp:8000 tcp:8000; then
    echo "✅ Port forwarding established: device:8000 → host:8000"
    echo "   App will use localhost:8000 (no internet needed!)"
    adb reverse --list
else
    echo "⚠️  Warning: Could not set up port forwarding"
    echo "   App may still work, but connection might fail"
fi

echo ""
echo "🔍 Checking backend server..."

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
echo "📱 Running Flutter app on emulator..."
echo ""

# Run Flutter app
cd "$(dirname "$0")"
flutter run -d $(adb devices | grep "emulator" | head -1 | cut -f1)

