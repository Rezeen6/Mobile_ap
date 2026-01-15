#!/bin/bash

# Build APK Script for Nutrition App
# This script builds a release APK for testing on your phone

echo "🚀 Building APK for Nutrition App..."
echo ""

# Navigate to mobile_app directory
cd "$(dirname "$0")/mobile_app" || exit

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build APK
echo "🔨 Building release APK..."
flutter build apk --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ APK built successfully!"
    echo ""
    echo "📱 APK location:"
    echo "   mobile_app/build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "📲 To install on your phone:"
    echo "   1. Transfer the APK to your phone"
    echo "   2. Enable 'Install from Unknown Sources' in Settings"
    echo "   3. Open the APK file and install"
    echo ""
    echo "💡 Tip: Use 'adb install' if you have USB debugging enabled:"
    echo "   adb install build/app/outputs/flutter-apk/app-release.apk"
else
    echo ""
    echo "❌ Build failed! Please check the errors above."
    exit 1
fi

