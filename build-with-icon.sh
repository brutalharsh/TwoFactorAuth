#!/bin/bash

# Enhanced build script for TwoFactorAuth with icon support
# This script builds the app, adds the icon, and creates a DMG

set -e  # Exit on error

echo "🔨 Building TwoFactorAuth with Icon Support..."
echo "============================================"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf .build TwoFactorAuth.app TwoFactorAuth.dmg AppIcon.iconset AppIcon.icns

# Create ICNS icon from PNG
echo "🎨 Creating app icon from logo..."
mkdir -p AppIcon.iconset

# Create all required icon sizes
sips -z 1024 1024 pic/applogo.png --out AppIcon.iconset/icon_512x512@2x.png >/dev/null 2>&1
sips -z 512 512 pic/applogo.png --out AppIcon.iconset/icon_512x512.png >/dev/null 2>&1
sips -z 512 512 pic/applogo.png --out AppIcon.iconset/icon_256x256@2x.png >/dev/null 2>&1
sips -z 256 256 pic/applogo.png --out AppIcon.iconset/icon_256x256.png >/dev/null 2>&1
sips -z 256 256 pic/applogo.png --out AppIcon.iconset/icon_128x128@2x.png >/dev/null 2>&1
sips -z 128 128 pic/applogo.png --out AppIcon.iconset/icon_128x128.png >/dev/null 2>&1
sips -z 64 64 pic/applogo.png --out AppIcon.iconset/icon_32x32@2x.png >/dev/null 2>&1
sips -z 32 32 pic/applogo.png --out AppIcon.iconset/icon_32x32.png >/dev/null 2>&1
sips -z 32 32 pic/applogo.png --out AppIcon.iconset/icon_16x16@2x.png >/dev/null 2>&1
sips -z 16 16 pic/applogo.png --out AppIcon.iconset/icon_16x16.png >/dev/null 2>&1

# Convert to ICNS
iconutil -c icns AppIcon.iconset -o AppIcon.icns
echo "✅ Icon created successfully"

# Build release version (universal binary)
echo "📦 Building release executable (universal binary)..."
swift build -c release --arch arm64 --arch x86_64

# Create app bundle
echo "📁 Creating app bundle..."
mkdir -p TwoFactorAuth.app/Contents/{MacOS,Resources}

# Copy executable
cp .build/apple/Products/Release/TwoFactorAuth TwoFactorAuth.app/Contents/MacOS/

# Copy icon
cp AppIcon.icns TwoFactorAuth.app/Contents/Resources/

# Create Info.plist with icon reference
echo "📝 Creating Info.plist with icon..."
cat > TwoFactorAuth.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>TwoFactorAuth</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.twoFactorAuth.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>TwoFactorAuth</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSCameraUsageDescription</key>
    <string>Camera access is required to scan QR codes for adding 2FA accounts.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>UTExportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>com.twoFactorAuth.2fa</string>
            <key>UTTypeDescription</key>
            <string>2FA Export File</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.data</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>2fa</string>
                </array>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF

echo "✅ App bundle created successfully"

# Replace app in /Applications (requires sudo)
echo "📲 Installing app to /Applications..."
if [ -d "/Applications/TwoFactorAuth.app" ]; then
    echo "   Removing old version..."
    sudo rm -rf /Applications/TwoFactorAuth.app
fi
echo "   Copying new version..."
sudo cp -R TwoFactorAuth.app /Applications/
echo "✅ App installed to /Applications"

# Create DMG for distribution
echo "💿 Creating DMG for distribution..."
mkdir -p dist/TwoFactorAuth

# Copy app to distribution folder
cp -R TwoFactorAuth.app dist/TwoFactorAuth/

# Create symbolic link to Applications
ln -s /Applications dist/TwoFactorAuth/Applications

# Create DMG with compression
hdiutil create -volname "TwoFactorAuth" \
               -srcfolder dist/TwoFactorAuth \
               -ov \
               -format UDZO \
               TwoFactorAuth.dmg

# Move DMG to Downloads
echo "📥 Moving DMG to Downloads folder..."
mv TwoFactorAuth.dmg ~/Downloads/
echo "✅ DMG moved to ~/Downloads/TwoFactorAuth.dmg"

# Clean up
echo "🧹 Cleaning up temporary files..."
rm -rf dist AppIcon.iconset AppIcon.icns

echo ""
echo "============================================"
echo "✅ BUILD COMPLETE!"
echo "============================================"
echo "📍 App installed at: /Applications/TwoFactorAuth.app"
echo "📍 DMG available at: ~/Downloads/TwoFactorAuth.dmg"
echo ""
echo "You can now:"
echo "1. Run the app from /Applications/TwoFactorAuth.app"
echo "2. Share the DMG file from ~/Downloads/TwoFactorAuth.dmg"
echo "============================================"