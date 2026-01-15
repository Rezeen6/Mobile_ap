# Quick Start Guide

## Quick Login Credentials

**Email:** `admin@gmail.com`  
**Password:** `admin!@#`

Just tap the **"Quick Login (Admin)"** button on the login screen!

## Build APK for Your Phone

### Quick Build (One Command)

```bash
cd mobile_app
./build_apk.sh
```

The APK will be at: `mobile_app/build/app/outputs/flutter-apk/app-release.apk`

### Manual Build

```bash
cd mobile_app
flutter clean
flutter pub get
flutter build apk --release
```

## Install on Phone

1. **Transfer APK** to your phone (USB, email, or cloud)
2. **Enable "Install from Unknown Sources"** in Settings
3. **Open APK** and tap Install

## Important: Backend Connection

### For Physical Device Testing

You need to update the backend URL to use your computer's IP address:

1. **Find your computer's IP:**
   ```bash
   # Linux/Mac
   hostname -I | awk '{print $1}'
   
   # Or
   ip addr show | grep "inet " | grep -v 127.0.0.1
   ```

2. **Update `mobile_app/lib/config/api_config.dart`:**
   ```dart
   static const String baseUrl = 'http://YOUR_IP:8000/api/v1';
   // Example: 'http://192.168.1.100:8000/api/v1'
   ```

3. **Rebuild APK:**
   ```bash
   cd mobile_app
   flutter build apk --release
   ```

4. **Make sure backend is running:**
   ```bash
   cd backend
   python -m uvicorn main:app --host 0.0.0.0 --port 8000
   ```

5. **Check firewall** allows connections on port 8000

## Testing Checklist

- [ ] Backend is running on your computer
- [ ] Backend URL is updated in `api_config.dart` (for physical device)
- [ ] APK is built successfully
- [ ] APK is installed on phone
- [ ] Quick Login works
- [ ] Dashboard shows data
- [ ] Can log meals
- [ ] Today's Progress updates

## Troubleshooting

**Can't connect to backend?**
- Check backend is running: `curl http://localhost:8000/health`
- Verify IP address in `api_config.dart`
- Check firewall settings
- Ensure phone and computer are on same network

**APK won't install?**
- Enable "Install from Unknown Sources"
- Check if APK is corrupted (rebuild)
- Try installing via ADB: `adb install app-release.apk`

**App crashes?**
- Check backend is accessible
- View logs: `adb logcat | grep flutter`
- Verify all dependencies: `flutter pub get`

## Next Steps

1. Test all features
2. Log some meals
3. Check Today's Progress updates
4. Test meal plan generation
5. Verify nutrition tracking

Happy testing! 🚀

