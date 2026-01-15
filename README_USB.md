# USB Connection Setup - Run App Without Internet

## Quick Start

```bash
cd mobile_app
./run_with_usb.sh
```

This script will:
1. ✅ Set up ADB reverse port forwarding automatically
2. ✅ Check if backend is running
3. ✅ Run the Flutter app

## Manual Setup

### Step 1: Connect Device/Emulator

**For Physical Device:**
- Connect Android phone via USB cable
- Enable USB Debugging (Settings → Developer Options)

**For Emulator:**
- Start emulator: `flutter emulators --launch Medium_Phone_API_36.1`

### Step 2: Set Up Port Forwarding

```bash
# Set up ADB reverse port forwarding (works for both emulator and physical device)
adb reverse tcp:8000 tcp:8000

# Verify
adb reverse --list
```

### Step 3: Start Backend

```bash
cd backend
source venv/bin/activate
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Step 4: Run App

```bash
cd mobile_app
flutter run
```

## How It Works

**ADB Reverse Port Forwarding:**
```
Device/Emulator (localhost:8000) → ADB Bridge → Computer (localhost:8000) → Backend
```

- ✅ **No Internet Required** - Works completely offline via USB
- ✅ **No WiFi Needed** - USB cable provides connection
- ✅ **Works for Emulator** - ADB reverse works for emulator too
- ✅ **Works for Physical Device** - USB connection with ADB reverse

## Configuration

The app is configured to use:
- **Host**: `localhost` (default)
- **Port**: `8000`
- **URL**: `http://localhost:8000/api/v1`

This works with ADB reverse for both emulator and USB physical device!

## Troubleshooting

**Port forwarding not working?**
```bash
# Remove and re-add
adb reverse --remove tcp:8000
adb reverse tcp:8000 tcp:8000
adb reverse --list
```

**App still can't connect?**
- Verify backend is running: `curl http://localhost:8000/health`
- Check ADB connection: `adb devices`
- Restart ADB: `adb kill-server && adb start-server`

**For emulator without ADB reverse:**
- Change default host to `10.0.2.2` in `lib/config/api_config.dart`
- Or run: `adb reverse tcp:8000 tcp:8000` (recommended)
