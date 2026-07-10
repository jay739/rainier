#!/bin/bash
# Build a distributable Rainier.app into dist/.
set -euo pipefail
cd "$(dirname "$0")/.."

Scripts/build.sh

APP=dist/Rainier.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp dist/rainier "$APP/Contents/MacOS/Rainier"
cp -R Skins "$APP/Contents/Resources/Skins"

VERSION=$(grep -o '"[0-9.]*"' Sources/RainierCore/Version.swift | tr -d '"')
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>Rainier</string>
    <key>CFBundleIdentifier</key><string>dev.jay739.rainier</string>
    <key>CFBundleName</key><string>Rainier</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "built $APP"
