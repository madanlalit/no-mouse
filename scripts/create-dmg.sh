#!/bin/bash

# create-dmg.sh - Creates a distributable DMG for NoMouse
# Usage: ./scripts/create-dmg.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

APP_NAME="NoMouse"
DMG_NAME="NoMouse"
VERSION="1.1.0"
DMG_FILENAME="${DMG_NAME}.dmg"

echo "🔨 Building release..."
swift build -c release

echo "📦 Creating app bundle..."
mkdir -p "${APP_NAME}.app/Contents/MacOS"
mkdir -p "${APP_NAME}.app/Contents/Resources"
cp .build/release/NoMouse "${APP_NAME}.app/Contents/MacOS/"

# Copy app icon
if [ -f "NoMouse/Resources/AppIcon.icns" ]; then
    cp NoMouse/Resources/AppIcon.icns "${APP_NAME}.app/Contents/Resources/"
    echo "🎨 App icon added"
fi

# Create Info.plist with icon reference
cat > "${APP_NAME}.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>NoMouse</string>
    <key>CFBundleIdentifier</key>
    <string>com.nomouse.app</string>
    <key>CFBundleName</key>
    <string>NoMouse</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAccessibilityUsageDescription</key>
    <string>NoMouse needs Accessibility permission to control the mouse cursor.</string>
</dict>
</plist>
EOF

echo "💿 Creating DMG..."

# Create temporary directory for DMG contents
DMG_TEMP="dmg_temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy app to temp directory
cp -R "${APP_NAME}.app" "$DMG_TEMP/"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP/Applications"

# Remove old DMG if exists
rm -f "$DMG_FILENAME"

# Create DMG
hdiutil create -volname "$DMG_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_FILENAME"

# Cleanup
rm -rf "$DMG_TEMP"

echo ""
echo "✅ DMG created: $DMG_FILENAME"
echo ""
echo "📋 To distribute:"
echo "   1. Upload $DMG_FILENAME to GitHub releases"
echo "   2. Users can download, open DMG, drag to Applications"
