#!/bin/bash

# Build script for TwoFactorAuth macOS app

echo "Building TwoFactorAuth for macOS..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode is not installed. Please install Xcode from the Mac App Store."
    exit 1
fi

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build/

# Build using Swift Package Manager (if you want to build from command line)
echo "Building with Swift..."
swift build -c release

echo "Build complete!"
echo ""
echo "To run the app from Xcode:"
echo "1. Open Xcode"
echo "2. File > New > Project"
echo "3. Choose macOS > App"
echo "4. Use SwiftUI interface and Swift language"
echo "5. Name it 'TwoFactorAuth'"
echo "6. Replace the generated files with the files in this directory"
echo "7. Build and run (Cmd+R)"
echo ""
echo "The app includes:"
echo "- TOTP code generation"
echo "- QR code scanning"
echo "- Secure keychain storage"
echo "- Import/Export functionality"
echo "- Account management"