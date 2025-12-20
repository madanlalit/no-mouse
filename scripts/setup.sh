#!/bin/bash
# NoMouse Setup Script
# Builds, packages, and sets up NoMouse.app

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="NoMouse"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"

echo "╔════════════════════════════════════════╗"
echo "║         NoMouse Setup Script           ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Build
echo "📦 Building release..."
cd "$SCRIPT_DIR"
swift build -c release

# Create app bundle structure
echo "📁 Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Create Info.plist if not exists
if [ ! -f "$APP_BUNDLE/Contents/Info.plist" ]; then
    cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>NoMouse</string>
    <key>CFBundleDisplayName</key>
    <string>NoMouse</string>
    <key>CFBundleIdentifier</key>
    <string>com.nomouse.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>NoMouse</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF
fi

echo ""
echo "✅ Build complete!"
echo ""
echo "═══════════════════════════════════════════"
echo "  IMPORTANT: Grant Permissions"
echo "═══════════════════════════════════════════"
echo ""
echo "1. Open System Settings → Privacy & Security"
echo ""
echo "2. Add NoMouse to ACCESSIBILITY:"
echo "   Click '+' → Navigate to:"
echo "   $APP_BUNDLE"
echo "   Toggle ON"
echo ""
echo "3. Add NoMouse to INPUT MONITORING:"
echo "   Same process as above"
echo ""
echo "═══════════════════════════════════════════"
echo ""

# Kill any existing instance
pkill -f "$APP_NAME" 2>/dev/null || true

# Ask to open permissions
read -p "Open Accessibility settings now? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
fi

# Launch app
read -p "Launch NoMouse now? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    echo "🚀 Launching NoMouse..."
    open "$APP_BUNDLE"
    echo ""
    echo "Look for the cursor icon (⌖) in your menu bar!"
    echo "Press ⌃ Space (Control + Space) to activate the grid."
fi
