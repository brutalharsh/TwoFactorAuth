# Frequently Asked Questions (FAQ)

## General Questions

### 1. What is TwoFactorAuth for macOS?
TwoFactorAuth is a native, secure, and modern Two-Factor Authentication (2FA) app built with SwiftUI specifically for macOS. It generates time-based one-time passwords (TOTP) to help you secure your online accounts without requiring an internet connection.

### 2. Is TwoFactorAuth free to use?
Yes, TwoFactorAuth is completely free and open-source. You can download, use, modify, and contribute to the project without any cost.

### 3. What macOS versions are supported?
TwoFactorAuth requires macOS 13.0 (Ventura) or later. For building from source, you'll need Xcode 15.0 or later.

### 4. Does the app work offline?
Yes! TwoFactorAuth works completely offline. All TOTP codes are generated locally on your device without requiring any internet connection, ensuring maximum privacy and security.

### 5. How is my data stored securely?
All secret keys are stored in the macOS Keychain with the `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` flag. This means your secrets are encrypted and only accessible when your device is unlocked, and they never leave your Mac.

## Setup and Installation

### 6. How do I install TwoFactorAuth?
You can either download the pre-built DMG file from the repository, or build the app from source using Xcode. For building from source, clone the repository and open it in Xcode, or use the included `build.sh` script.

### 7. Why does the app request camera permissions?
Camera access is needed for the QR code scanning feature. This allows you to quickly add accounts by scanning QR codes. If you prefer not to grant camera access, you can still add accounts manually or by uploading QR code images.

### 8. What permissions does the app need?
The app may request:
- **Camera**: For QR code scanning
- **Keychain Access**: For secure storage of secret keys (automatic)
- **Accessibility**: For auto-paste functionality in the menu bar feature
- **Automation**: For browser detection to match websites with your accounts

## Features and Usage

### 9. How do I add a new account?
You can add accounts in four ways:
1. **QR Code Scanning**: Use live camera, upload an image, or capture a screenshot
2. **Google Authenticator Migration**: Import multiple accounts at once from Google Authenticator
3. **Manual Entry**: Enter the service name, account name, and secret key manually
4. **Import from URI**: Copy an `otpauth://` URI and the app will detect it automatically

### 10. What is the menu bar quick access feature?
The menu bar feature adds a shield icon to your macOS menu bar, allowing you to quickly access 2FA codes. It can detect which website you're currently on and automatically show matching accounts. You can click to copy and paste codes, or use the Cmd+Shift+V keyboard shortcut for instant auto-fill.

### 11. How does the smart website detection work?
The app can detect your current browser tab's URL and match it with your saved accounts. For example, if you're on github.com, it will automatically show your GitHub 2FA account. This works with Safari, Chrome, Edge, Brave, and other popular browsers.

### 12. Can I import accounts from Google Authenticator?
Yes! Go to Google Authenticator → Settings → Transfer accounts → Export accounts, then scan the migration QR code in TwoFactorAuth. All your accounts will be imported at once.

### 13. What algorithms and configurations are supported?
TwoFactorAuth supports:
- **Algorithms**: SHA1, SHA256, and SHA512
- **Digits**: 6 or 8-digit codes
- **Period**: Customizable time period (default 30 seconds)

### 14. Can I manage multiple accounts at once?
Yes, the app includes bulk account management. Click the "Select" button to choose multiple accounts and delete them all at once. You can also reorder accounts, search by name or issuer, and track when each account was last used.

## Security and Privacy

### 15. Does TwoFactorAuth sync my data to the cloud?
No. TwoFactorAuth does not sync your data to any cloud service. All data remains completely local to your device, ensuring maximum privacy and security.

### 16. Can I export or backup my accounts?
Currently, the app stores all data in the macOS Keychain. While there's no built-in export feature, your accounts are backed up as part of your macOS Keychain when you backup your Mac.

### 17. Is my data encrypted?
Yes. All secret keys are stored encrypted in the macOS Keychain using Apple's Security Framework with device-only access flags. The data is only accessible when your device is unlocked.

### 18. What happens if I lose my device?
Since TwoFactorAuth stores data locally and uses device-only Keychain access, your 2FA secrets cannot be recovered from another device. This is why it's important to save backup codes provided by services when you initially set up 2FA.

## Troubleshooting

### 19. Why isn't the QR code scanner working?
Common solutions:
- Ensure you've granted camera permissions in System Settings → Privacy & Security → Camera
- Click the "Capture QR Code" button - the app uses manual capture mode
- Try alternative methods: "Upload Image" for saved QR codes or "Capture Screenshot" for on-screen codes
- Check that the QR code is a valid `otpauth://` or `otpauth-migration://` format

### 20. The auto-paste feature isn't working. What should I do?
For auto-paste to work:
- Enable it in Settings (Cmd+,) → General tab
- Grant Accessibility permissions in System Settings → Privacy & Security → Accessibility
- Grant Automation permissions for browser detection in System Settings → Privacy & Security → Automation
- Ensure TwoFactorAuth is added to the allowed apps list for your browser

### 21. How can I contribute to the project or report issues?
TwoFactorAuth is open-source and welcomes contributions! You can:
- Submit pull requests on GitHub with improvements or bug fixes
- Open issues on the GitHub repository for bugs, feature requests, or questions
- Fork the project and customize it for your own needs
- Share feedback to help improve the app for everyone
