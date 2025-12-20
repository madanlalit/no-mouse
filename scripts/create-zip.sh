#!/bin/bash

# create-zip.sh - Creates a distributable ZIP for NoMouse
# ZIP distribution is preferred for unsigned apps (no Apple Developer account)
# ZIPs have higher success rate with Gatekeeper than DMGs
#
# Usage: ./scripts/create-zip.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

APP_NAME="NoMouse"
VERSION="1.1.0"
ZIP_FILENAME="${APP_NAME}-${VERSION}.zip"

echo "🔨 Building release..."
swift build -c release

echo "📦 Creating app bundle..."
rm -rf "${APP_NAME}.app"
mkdir -p "${APP_NAME}.app/Contents/MacOS"
mkdir -p "${APP_NAME}.app/Contents/Resources"
cp .build/release/NoMouse "${APP_NAME}.app/Contents/MacOS/"

# Copy app icon
if [ -f "NoMouse/Resources/AppIcon.icns" ]; then
    cp NoMouse/Resources/AppIcon.icns "${APP_NAME}.app/Contents/Resources/"
    echo "🎨 App icon added"
fi

# Create Info.plist with icon reference
cat > "${APP_NAME}.app/Contents/Info.plist" <<EOF
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

echo "🔏 Applying ad-hoc signature..."
# This fixes the "Damaged" error by resigning the bundle after we added files
codesign --force --deep --sign - "${APP_NAME}.app"

echo "📦 Creating ZIP archive..."

# Remove old ZIP if exists
rm -f "$ZIP_FILENAME"

# Create ZIP using ditto (preserves macOS metadata, resource forks, etc.)
ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "$ZIP_FILENAME"

# Get file size
ZIP_SIZE=$(ls -lh "$ZIP_FILENAME" | awk '{print $5}')

# Calculate SHA256 for Homebrew cask
SHA256=$(shasum -a 256 "$ZIP_FILENAME" | awk '{print $1}')

echo ""
echo "✅ ZIP created: $ZIP_FILENAME ($ZIP_SIZE)"
echo ""
echo "📋 SHA256: $SHA256"
echo ""
echo "📋 To distribute:"
echo "   1. Upload $ZIP_FILENAME to GitHub releases"
echo "   2. Update Casks/no-mouse.rb with new SHA256"
echo ""
echo "📋 User installation instructions:"
echo "   1. Download $ZIP_FILENAME"
echo "   2. Double-click to unzip"
echo "   3. Right-click NoMouse.app → Open"
echo "   4. Click 'Open' in the warning dialog"
echo ""
echo "💡 Note: ZIP distribution works better than DMG for unsigned apps"
