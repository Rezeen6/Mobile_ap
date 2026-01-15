# Building APK for Testing

This guide will help you build an APK file to test the Nutrition App on your phone.

## Quick Login Credentials

For testing, use the **Quick Login** button on the login screen:
- **Email:** `admin@gmail.com`
- **Password:** `admin!@#`

Or manually enter these credentials.

## Prerequisites

1. **Flutter SDK** installed and configured
2. **Android SDK** installed
3. **Java JDK 17** or higher
4. **USB Debugging** enabled on your phone (optional, for direct install)

## Build Methods

### Method 1: Using the Build Script (Recommended)

```bash
# From the project root
cd mobile_app
chmod +x build_apk.sh
./build_apk.sh
```

### Method 2: Manual Flutter Commands

```bash
# Navigate to mobile_app directory
cd mobile_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

### Method 3: Build Split APKs (Smaller file size)

```bash
cd mobile_app
flutter build apk --split-per-abi --release
```

This creates separate APKs for different architectures:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM - most modern phones)
- `app-x86_64-release.apk` (64-bit x86)

## APK Location

After building, the APK will be located at:
```
mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

For split APKs:
```
mobile_app/build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk
├── app-arm64-v8a-release.apk
└── app-x86_64-release.apk
```

## Installing on Your Phone

### Option 1: Transfer and Install Manually

1. **Transfer APK to phone:**
   - Use USB cable, email, cloud storage, or file sharing app
   - Copy the APK file to your phone's Downloads folder

2. **Enable Unknown Sources:**
   - Go to Settings → Security → Enable "Install from Unknown Sources"
   - Or Settings → Apps → Special Access → Install Unknown Apps

3. **Install:**
   - Open the APK file using a file manager
   - Tap "Install"
   - Wait for installation to complete

### Option 2: Direct Install via ADB (USB Debugging)

```bash
# Connect your phone via USB
# Enable USB Debugging in Developer Options

# Install directly
adb install mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

### Option 3: Wireless ADB (Android 11+)

```bash
# Pair device wirelessly first
adb pair <IP_ADDRESS>:<PORT>

# Then install
adb install mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

## Testing the App

1. **Open the app** on your phone
2. **Use Quick Login:**
   - Tap the "Quick Login (Admin)" button
   - Or enter:
     - Email: `admin@gmail.com`
     - Password: `admin!@#`
3. **Test features:**
   - Dashboard with Today's Progress
   - Log meals
   - View nutrition tracking
   - Generate meal plans

## Important Notes

### Backend Connection

The app connects to the backend at:
- **Android Emulator:** `http://10.0.2.2:8000`
- **Physical Device:** Use your computer's IP address

To find your computer's IP:
```bash
# Linux/Mac
ip addr show | grep "inet " | grep -v 127.0.0.1

# Windows
ipconfig
```

Then update `mobile_app/lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://YOUR_IP_ADDRESS:8000/api/v1';
```

### Network Permissions

The app requires internet permission (already configured in AndroidManifest.xml).

### Signing (For Production)

For production releases, you need to:
1. Create a keystore
2. Configure signing in `android/app/build.gradle.kts`
3. Build with your signing key

Current build uses debug signing for testing.

## Troubleshooting

### Build Fails

1. **Check Flutter version:**
   ```bash
   flutter --version
   ```

2. **Check Android SDK:**
   ```bash
   flutter doctor
   ```

3. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

### App Crashes on Launch

1. Check backend is running
2. Verify network permissions
3. Check device logs:
   ```bash
   adb logcat | grep flutter
   ```

### Can't Connect to Backend

1. Ensure backend is running on your computer
2. Check firewall settings
3. Verify IP address in `api_config.dart`
4. Test backend URL in phone's browser

## Build Variants

### Debug APK (Larger, includes debugging info)
```bash
flutter build apk --debug
```

### Release APK (Optimized, smaller size)
```bash
flutter build apk --release
```

### App Bundle (For Google Play Store)
```bash
flutter build appbundle --release
```

## File Size Optimization

To reduce APK size:
1. Use split APKs: `--split-per-abi`
2. Enable ProGuard/R8 (already enabled in release builds)
3. Remove unused assets
4. Use code shrinking

## Next Steps

After testing:
1. Fix any bugs found
2. Update version in `pubspec.yaml`
3. Create production signing key
4. Build final release APK
5. Test thoroughly before distribution

