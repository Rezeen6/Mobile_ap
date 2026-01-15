# Quick Setup - USB Connection (No Internet)

## 🚀 One-Command Setup

```bash
cd mobile_app
./run_with_usb.sh
```

This script automatically:
1. ✅ Sets up ADB reverse port forwarding
2. ✅ Checks if backend is running  
3. ✅ Runs the Flutter app

## 📱 Manual Setup (3 Steps)

### Step 1: Set Up Port Forwarding
```bash
adb reverse tcp:8000 tcp:8000
```

### Step 2: Start Backend (if not running)
```bash
cd ../backend
source venv/bin/activate
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Step 3: Run App
```bash
cd mobile_app
flutter run
```

## ✅ That's It!

- ✅ **No Internet Required** - Works via USB cable
- ✅ **No WiFi Needed** - ADB reverse handles connection
- ✅ **Works for Emulator** - ADB reverse works for emulator too
- ✅ **Works for Physical Device** - USB connection with ADB reverse

## 🔧 How It Works

**ADB Reverse:**
```
Device (localhost:8000) → ADB Bridge → Computer (localhost:8000) → Backend
```

The app uses `localhost:8000` which forwards via USB to your computer!

## 📝 Notes

- Port forwarding resets when you disconnect USB
- Run `adb reverse tcp:8000 tcp:8000` again after reconnecting
- Or use `./run_with_usb.sh` script which does it automatically

