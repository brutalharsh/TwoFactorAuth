# Two-Factor Authenticator for macOS

A native, secure, and modern 2FA (Two-Factor Authentication) app built with SwiftUI for macOS.

## Features

### Core Functionality
- **TOTP Code Generation** - Generate time-based one-time passwords (6 or 8 digits)
- **QR Code Scanning** - Add accounts instantly by scanning QR codes
- **Manual Entry** - Add accounts by entering secret keys manually
- **Multiple Algorithms** - Support for SHA1, SHA256, and SHA512

### Security
- **Keychain Storage** - All secrets are securely stored in macOS Keychain
- **Encrypted Export** - Password-protected backup files
- **Touch ID Support** - Optional biometric authentication
- **Offline Operation** - No internet connection required

### User Experience
- **Native macOS Design** - Built with SwiftUI for a modern Mac experience
- **Account Management** - Easy add, edit, delete, and organize accounts
- **Search & Filter** - Quickly find accounts
- **One-Click Copy** - Copy codes to clipboard instantly
- **Visual Indicators** - Progress bars show time remaining for each code
- **Dark Mode Support** - Automatic theme switching

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building from source)

## Installation

### Method 1: Build from Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/brutalharsh/TwoFactorAuth.git
   cd TwoFactorAuth
   ```

2. **Open in Xcode:**
   - Open Xcode
   - File → Open → Select the `TwoFactorAuth` folder
   - Create a new macOS App project with SwiftUI
   - Replace the generated files with the source files

3. **Configure the project:**
   - Set the bundle identifier (e.g., `com.yourname.TwoFactorAuth`)
   - Enable Camera usage in Capabilities
   - Enable Keychain Sharing if needed

4. **Build and Run:**
   - Press `Cmd + R` to build and run
   - Or Archive → Distribute App for release build

### Method 2: Using the Build Script

```bash
chmod +x build.sh
./build.sh
```

## Usage

### Adding Accounts

**Method 1: QR Code Scanning**
1. Click the QR code scanner button in the toolbar
2. Allow camera access when prompted
3. Point the camera at the QR code
4. The account will be added automatically

**Method 2: Manual Entry**
1. Click the "+" button in the toolbar
2. Enter the service name (e.g., "GitHub")
3. Enter your account name or email
4. Paste or type the secret key
5. Click "Add Account"

**Method 3: Import from URI**
1. Copy an `otpauth://` URI to clipboard
2. Click "+" → "Paste from Clipboard"
3. The account details will be filled automatically

### Managing Accounts

- **View Code**: Select an account from the sidebar
- **Copy Code**: Click the copy button or use right-click menu
- **Edit Account**: Right-click → Edit or use the Edit button
- **Delete Account**: Right-click → Delete or swipe left
- **Search**: Use the search bar to filter accounts

### Backup & Restore

**Export Accounts:**
1. Click Menu → Import/Export
2. Enter a strong password for encryption
3. Click "Export" and choose save location
4. Keep the `.2fa` file and password secure

**Import Accounts:**
1. Click Menu → Import/Export
2. Click "Choose File" and select your `.2fa` backup
3. Enter the password used during export
4. Accounts will be merged with existing ones

## Security Considerations

- **Keychain Storage**: All secret keys are stored in the macOS Keychain, encrypted at rest
- **No Network Access**: The app works completely offline
- **Encrypted Exports**: Backup files are encrypted with your password
- **Secure Clipboard**: Copied codes are cleared from clipboard after 30 seconds (optional)

## Demo Accounts

To test the app with demo accounts:
1. Click the menu button (⋯) in the toolbar
2. Select "Load Demo Accounts"
3. Five sample accounts will be added

**Note**: Demo accounts use example secret keys and won't generate valid codes for real services.

## Troubleshooting

### Camera Access Issues
- Go to System Settings → Privacy & Security → Camera
- Ensure TwoFactorAuth has permission enabled

### Keychain Access Issues
- Restart the app
- Check Keychain Access app for any prompts
- Reset keychain permissions if needed

### Invalid QR Codes
- Ensure the QR code is a valid `otpauth://` URI
- Check if the service uses TOTP (not HOTP)
- Try manual entry if QR scanning fails

## Project Structure

```
TwoFactorAuth/
├── TwoFactorAuth/
│   ├── App/
│   │   ├── TwoFactorAuthApp.swift    # Main app entry point
│   │   └── ContentView.swift         # Main content view
│   ├── Models/
│   │   ├── Account.swift             # Account data model
│   │   └── TOTPGenerator.swift       # TOTP algorithm implementation
│   ├── Views/
│   │   ├── AccountListView.swift     # Sidebar account list
│   │   ├── AccountDetailView.swift   # Account detail view
│   │   ├── AddAccountView.swift      # Add/Edit account forms
│   │   ├── QRScannerView.swift       # QR code scanner
│   │   └── ImportExportView.swift    # Import/Export UI
│   ├── Services/
│   │   ├── KeychainService.swift     # Keychain operations
│   │   └── DataManager.swift         # Data management layer
│   └── Info.plist                    # App configuration
├── Package.swift                      # Swift Package Manager config
├── build.sh                           # Build script
└── README.md                          # This file
```

## Technologies Used

- **SwiftUI** - Modern declarative UI framework
- **CryptoKit** - Apple's cryptography framework for TOTP generation
- **AVFoundation** - Camera access for QR code scanning
- **Security Framework** - Keychain Services for secure storage
- **Combine** - Reactive programming for data binding

## Contributing

Contributions are welcome! Please feel free to submit pull requests.

## License

This project is provided as-is for educational and personal use.

## Acknowledgments

- TOTP algorithm implementation based on [RFC 6238](https://tools.ietf.org/html/rfc6238)
- Base32 encoding/decoding adapted from Swift community implementations

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

**Security Notice**: Never share your secret keys or backup files with anyone. Always use strong, unique passwords for your exports.