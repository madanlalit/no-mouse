#!/bin/bash
# Build and package NoMouse.app

set -e

echo "Building Release..."
swift build -c release

echo "Creating app bundle..."
mkdir -p NoMouse.app/Contents/MacOS
mkdir -p NoMouse.app/Contents/Resources

# Copy executable
cp .build/release/NoMouse NoMouse.app/Contents/MacOS/

echo "Build complete! Run with:"
echo "  open NoMouse.app"
