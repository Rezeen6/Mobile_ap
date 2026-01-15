# USB Connection Setup - No Internet Required

## 🔌 Connect Mobile App via USB Cable (No WiFi/Internet Needed)

This guide shows you how to run the mobile app on your physical Android device using a USB cable, **without requiring internet connection or WiFi**.

---

## 📋 Prerequisites

1. **USB Cable** - Connect your Android phone to computer via USB
2. **USB Debugging Enabled** - On your phone:
   - Go to: **Settings → About Phone**
   - Tap **"Build Number"** 7 times (enables Developer Options)
   - Go to: **Settings → Developer Options**
   - Enable **"USB Debugging"**
3. **ADB Installed** - Android Debug Bridge (usually comes with Android SDK)

---

## 🚀 Quick Setup (One Command)

### Option 1: Using Setup Script (Recommended)

```bash
cd mobile_app
./setup_usb_connection.sh
```

This script will:
- ✅ Check if device is connected via USB
- ✅ Set up ADB reverse port forwarding automatically
- ✅ Configure connection to use `localhost:8000`

### Option 2: Manual Setup

```bash
# Connect your phone via USB
# Enable USB Debugging on your phone

# Set up port forwarding
adb reverse tcp:8000 tcp:8000

# Verify
adb reverse --list
```

---

## 🔧 How It Works

**ADB Reverse Port Forwarding:**
```
Android Device (localhost:8000)  →  ADB Bridge  →  Computer (localhost:8000)
```

When you run `adb reverse tcp:8000 tcp:8000`:
- The device's `localhost:8000` forwards to your computer's `localhost:8000`
- The app uses `http://localhost:8000` which works via USB
- **No internet or WiFi needed!**

---

## 📱 Running the App

### Step 1: Connect Device & Setup Port Forwarding

```bash
cd mobile_app
./setup_usb_connection.sh
```

### Step 2: Start Backend (on your computer)

```bash
cd ../backend
source venv/bin/activate
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Step 3: Run Flutter App

```bash
cd mobile_app
flutter run
```

The app will automatically use `localhost:8000` which works via USB!

---

## ✅ Verification

After running `adb reverse tcp:8000 tcp:8000`, verify:

```bash
# Check port forwarding is active
adb reverse --list
# Should show: tcp:8000 tcp:8000

# Test connection from device (if you have terminal on device)
# Or just try logging in the app - it should work!
```

---

## 🎯 App Configuration

The app is configured to use:
- **Default Host**: `localhost`
- **Default Port**: `8000`
- **URL**: `http://localhost:8000/api/v1`

This works for:
- ✅ **USB Physical Device** (via ADB reverse)
- ✅ **Android Emulator** (10.0.2.2 also works, but localhost works too)

---

## 🔄 Reconnecting

Every time you reconnect your USB device:

1. **Run setup script again:**
   ```bash
   cd mobile_app
   ./setup_usb_connection.sh
   ```

2. **Or manually:**
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```

Port forwarding is reset when you disconnect the USB cable.

---

## 🛠️ Troubleshooting

### Issue: "adb: no devices/emulators found"

**Solution:**
1. Check USB cable is connected
2. Enable USB Debugging on phone
3. On phone, tap "Allow USB Debugging" when prompted
4. Try: `adb kill-server && adb start-server`

### Issue: "Port forwarding failed"

**Solution:**
1. Remove existing forwarding: `adb reverse --remove tcp:8000`
2. Try again: `adb reverse tcp:8000 tcp:8000`
3. Check if port 8000 is available: `lsof -i :8000`

### Issue: "Connection timeout" in app

**Solution:**
1. Verify port forwarding: `adb reverse --list`
2. Verify backend is running: `curl http://localhost:8000/health`
3. Restart port forwarding: `adb reverse --remove tcp:8000 && adb reverse tcp:8000 tcp:8000`
4. Hot restart app: Press `R` in Flutter terminal

### Issue: USB Debugging not showing

**Solution:**
1. Enable Developer Options (tap Build Number 7 times)
2. Go to Settings → Developer Options
3. Enable "USB Debugging"
4. Enable "Install via USB" (optional)
5. Reconnect USB cable

---

## 📝 Notes

- ✅ **No Internet Required** - Works completely offline via USB
- ✅ **No WiFi Needed** - USB cable provides connection
- ✅ **Fast Connection** - USB is faster than WiFi
- ✅ **More Reliable** - No network issues
- ✅ **Port Forwarding Persists** - Until USB disconnected or device restarted

---

## 🎓 Understanding the Setup

**Without ADB Reverse:**
```
App → 10.0.2.2:8000 (emulator) or 192.168.x.x:8000 (WiFi) → Backend
❌ Requires internet/WiFi
```

**With ADB Reverse (USB):**
```
App → localhost:8000 → ADB Bridge → Computer localhost:8000 → Backend
✅ Works via USB cable (no internet needed!)
```

---

**Last Updated**: Current as of latest development
**Script**: `mobile_app/setup_usb_connection.sh`

