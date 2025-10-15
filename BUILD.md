# Build Instructions for TwoFactorAuth

This document provides detailed instructions for building the TwoFactorAuth application on macOS.

## Prerequisites

- macOS 12.0 or later
- Xcode 14.0 or later (for Xcode build method)
- Swift 5.7 or later (for command line build)
- Developer ID certificate (optional, for signed builds)

## Build Methods

### Option 1: Xcode Build (Recommended for Development)

1. **Open the project in Xcode:**
   ```bash
   open Package.swift
   ```
   Or double-click `Package.swift` in Finder

2. **Select the build scheme:**
   - In Xcode, select "TwoFactorAuth" from the scheme selector in the toolbar
   - Choose "My Mac" as the destination

3. **Build the application:**
   - Press `⌘B` to build, or
   - Select Product → Build from the menu

4. **Run the application:**
   - Press `⌘R` to run, or
   - Select Product → Run from the menu

5. **Archive for distribution (optional):**
   - Select Product → Archive
   - Once archived, click "Distribute App"
   - Choose "Copy App" for local distribution

### Option 2: Swift Package Manager Build

1. **Build for debug:**
   ```bash
   swift build
   ```

2. **Build for release:**
   ```bash
   swift build -c release
   ```

3. **Run the application:**
   ```bash
   swift run TwoFactorAuth
   ```

### Option 3: Command Line Build (Quickest for Distribution)

1. **Build the release executable:**
   ```bash
   # Build for release
   swift build -c release --arch arm64 --arch x86_64
   ```

2. **Locate the built executable:**
   ```bash
   # The executable will be at:
   ls .build/release/TwoFactorAuth
   ```

3. **Create an app bundle:**
   ```bash
   # Create the app bundle structure
   mkdir -p TwoFactorAuth.app/Contents/{MacOS,Resources}

   # Copy the executable
   cp .build/release/TwoFactorAuth TwoFactorAuth.app/Contents/MacOS/

   # Copy Info.plist (create one if it doesn't exist)
   cat > TwoFactorAuth.app/Contents/Info.plist << EOF
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>CFBundleExecutable</key>
       <string>TwoFactorAuth</string>
       <key>CFBundleIdentifier</key>
       <string>com.yourcompany.TwoFactorAuth</string>
       <key>CFBundleName</key>
       <string>TwoFactorAuth</string>
       <key>CFBundlePackageType</key>
       <string>APPL</string>
       <key>CFBundleShortVersionString</key>
       <string>1.0.0</string>
       <key>CFBundleVersion</key>
       <string>1</string>
       <key>LSMinimumSystemVersion</key>
       <string>12.0</string>
   </dict>
   </plist>
   EOF

   # Copy assets if available
   if [ -d "TwoFactorAuth/Assets.xcassets" ]; then
       cp -r TwoFactorAuth/Assets.xcassets TwoFactorAuth.app/Contents/Resources/
   fi
   ```

4. **Install to Applications folder:**
   ```bash
   # Copy to Applications
   sudo cp -r TwoFactorAuth.app /Applications/
   ```

### Option 4: Create a DMG for Distribution

1. **Build the app using any method above**

2. **Create a distribution folder:**
   ```bash
   # Create a temporary distribution folder
   mkdir -p dist/TwoFactorAuth

   # Copy the app bundle
   cp -r TwoFactorAuth.app dist/TwoFactorAuth/

   # Create a symbolic link to Applications
   ln -s /Applications dist/TwoFactorAuth/Applications
   ```

3. **Create the DMG:**
   ```bash
   # Create DMG with compression
   hdiutil create -volname "TwoFactorAuth" \
                  -srcfolder dist/TwoFactorAuth \
                  -ov \
                  -format UDZO \
                  TwoFactorAuth.dmg
   ```

4. **Clean up:**
   ```bash
   rm -rf dist
   ```

## Automated Build Script

Create a `build.sh` script for one-command builds:

```bash
#!/bin/bash

# build.sh - Automated build script for TwoFactorAuth

set -e  # Exit on error

echo "🔨 Building TwoFactorAuth..."

# Clean previous builds
rm -rf .build TwoFactorAuth.app TwoFactorAuth.dmg

# Build release version (universal binary)
echo "📦 Building release executable..."
swift build -c release --arch arm64 --arch x86_64

# Create app bundle
echo "📁 Creating app bundle..."
mkdir -p TwoFactorAuth.app/Contents/{MacOS,Resources}
cp .build/release/TwoFactorAuth TwoFactorAuth.app/Contents/MacOS/

# Create Info.plist
cat > TwoFactorAuth.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TwoFactorAuth</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.TwoFactorAuth</string>
    <key>CFBundleName</key>
    <string>TwoFactorAuth</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
</dict>
</plist>
EOF

# Copy assets if they exist
if [ -d "TwoFactorAuth/Assets.xcassets" ]; then
    cp -r TwoFactorAuth/Assets.xcassets TwoFactorAuth.app/Contents/Resources/
fi

# Create DMG
echo "💿 Creating DMG..."
mkdir -p dist/TwoFactorAuth
cp -r TwoFactorAuth.app dist/TwoFactorAuth/
ln -s /Applications dist/TwoFactorAuth/Applications

hdiutil create -volname "TwoFactorAuth" \
               -srcfolder dist/TwoFactorAuth \
               -ov \
               -format UDZO \
               TwoFactorAuth.dmg

# Clean up
rm -rf dist

echo "✅ Build complete!"
echo "📍 App bundle: TwoFactorAuth.app"
echo "📍 DMG file: TwoFactorAuth.dmg"
```

Make the script executable:
```bash
chmod +x build.sh
```

Run the build:
```bash
./build.sh
```

## Code Signing (Optional)

To sign your application for distribution outside the Mac App Store:

1. **List available certificates:**
   ```bash
   security find-identity -v -p codesigning
   ```

2. **Sign the app:**
   ```bash
   codesign --force --deep --sign "Developer ID Application: Your Name" TwoFactorAuth.app
   ```

3. **Verify the signature:**
   ```bash
   codesign --verify --verbose TwoFactorAuth.app
   ```

4. **Notarize for Gatekeeper (requires Apple Developer account):**
   ```bash
   # Create a zip for notarization
   ditto -c -k --keepParent TwoFactorAuth.app TwoFactorAuth.zip

   # Submit for notarization
   xcrun notarytool submit TwoFactorAuth.zip \
                    --apple-id "your-apple-id@example.com" \
                    --team-id "YOUR_TEAM_ID" \
                    --password "your-app-specific-password" \
                    --wait

   # Staple the notarization
   xcrun stapler staple TwoFactorAuth.app
   ```

## Troubleshooting

### Build Errors

- **Module not found:** Run `swift package resolve` to fetch dependencies
- **Architecture issues:** Ensure you're building for the correct architecture
- **Permission denied:** Use `sudo` for copying to `/Applications`

### Runtime Issues

- **App won't open:** Check System Preferences → Security & Privacy
- **Missing dependencies:** Verify all Swift packages are included
- **Crash on launch:** Check Console.app for crash logs

## Additional Resources

- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Apple Developer - Distributing Apps](https://developer.apple.com/distribute/)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)