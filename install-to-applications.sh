#!/bin/bash

echo "📲 Installing TwoFactorAuth to /Applications..."
echo "This will require your administrator password."
echo ""

# Remove old version if it exists
if [ -d "/Applications/TwoFactorAuth.app" ]; then
    echo "Removing old version..."
    sudo rm -rf /Applications/TwoFactorAuth.app
fi

# Copy new version
echo "Installing new version..."
sudo cp -R TwoFactorAuth.app /Applications/

echo ""
echo "✅ Installation complete!"
echo "📍 App installed at: /Applications/TwoFactorAuth.app"
echo ""
echo "You can now launch the app from:"
echo "  - Spotlight (⌘+Space and type 'TwoFactorAuth')"
echo "  - Applications folder in Finder"
echo "  - Launchpad"