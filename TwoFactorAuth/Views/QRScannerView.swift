//
//  QRScannerView.swift
//  TwoFactorAuth
//
//  QR code scanner for adding accounts
//

import SwiftUI
import AVFoundation
import CoreImage

struct QRScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var isScanning = false
    @State private var scannedCode: String?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingConfirmation = false
    @State private var pendingAccount: Account?
    @State private var manualCaptureMode = false  // For manual capture instead of auto-scan

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Scan QR Code")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Scanner view
            ZStack {
                if isScanning {
                    QRCodeScannerRepresentable(
                        scannedCode: $scannedCode,
                        isScanning: $isScanning,
                        manualCapture: true  // Disable auto-scanning
                    )
                    .overlay(
                        // Scanning overlay
                        ZStack {
                            // Top controls overlay
                            VStack {
                                HStack {
                                    Button(action: { isScanning = false }) {
                                        Label("Back", systemImage: "chevron.left")
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    .padding()

                                    Spacer()

                                    // Capture Screenshot button
                                    Button(action: { captureScreenshotWhileScanning() }) {
                                        Label("Capture Screenshot", systemImage: "camera.viewfinder")
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.blue.opacity(0.8))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    .padding()
                                }
                                Spacer()
                            }

                            // Corners overlay
                            GeometryReader { geometry in
                                let size = min(geometry.size.width, geometry.size.height) * 0.7
                                let cornerLength: CGFloat = 30
                                let cornerWidth: CGFloat = 4

                                ZStack {
                                    // Top-left corner
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: cornerLength))
                                        path.addLine(to: CGPoint(x: 0, y: 0))
                                        path.addLine(to: CGPoint(x: cornerLength, y: 0))
                                    }
                                    .stroke(Color.green, lineWidth: cornerWidth)

                                    // Top-right corner
                                    Path { path in
                                        path.move(to: CGPoint(x: size - cornerLength, y: 0))
                                        path.addLine(to: CGPoint(x: size, y: 0))
                                        path.addLine(to: CGPoint(x: size, y: cornerLength))
                                    }
                                    .stroke(Color.green, lineWidth: cornerWidth)

                                    // Bottom-left corner
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: size - cornerLength))
                                        path.addLine(to: CGPoint(x: 0, y: size))
                                        path.addLine(to: CGPoint(x: cornerLength, y: size))
                                    }
                                    .stroke(Color.green, lineWidth: cornerWidth)

                                    // Bottom-right corner
                                    Path { path in
                                        path.move(to: CGPoint(x: size - cornerLength, y: size))
                                        path.addLine(to: CGPoint(x: size, y: size))
                                        path.addLine(to: CGPoint(x: size, y: size - cornerLength))
                                    }
                                    .stroke(Color.green, lineWidth: cornerWidth)
                                }
                                .frame(width: size, height: size)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            }
                        }
                    )
                } else {
                    // Start scanning prompt with improved options
                    VStack(spacing: 20) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)

                        Text("Add Account from QR Code")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        // Main actions
                        VStack(spacing: 12) {
                            Button("Start Camera Scanner") {
                                requestCameraAccess()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)

                            Button("Upload QR Image") {
                                selectQRImage()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }

                        // Help text
                        VStack(spacing: 4) {
                            Text("Tips:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            Text("• For camera: Position QR code in view and click capture screenshot")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("• For upload: Select a saved QR code image file")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.9))

            // Instructions
            VStack(spacing: 8) {
                Text("Position the QR code within the frame")
                    .font(.headline)

                Text("Click 'Capture Screenshot' to scan the code")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 600, height: 500)
        .onChange(of: scannedCode) { newValue in
            if let code = newValue {
                handleScannedCode(code)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                // Reset scanning after error
                scannedCode = nil
                isScanning = true
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Add Account", isPresented: $showingConfirmation) {
            Button("Cancel") {
                // Reset scanning
                scannedCode = nil
                isScanning = true
                pendingAccount = nil
            }
            Button("Add") {
                if let account = pendingAccount {
                    dataManager.addAccount(account)
                    dismiss()
                }
            }
        } message: {
            if let account = pendingAccount {
                Text("Add account for \(account.displayName)?")
            }
        }
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    isScanning = true
                } else {
                    errorMessage = "Camera access is required to scan QR codes. Please enable camera access in System Settings > Security & Privacy > Camera."
                    showingError = true
                }
            }
        }
    }

    private func handleScannedCode(_ code: String) {
        // Stop scanning while processing
        isScanning = false

        // Check if it's a Google Authenticator migration QR
        if code.starts(with: "otpauth-migration://") {
            if let accounts = GoogleAuthenticatorMigration.parseGoogleAuthenticatorMigration(uri: code) {
                handleMigrationAccounts(accounts)
            } else {
                errorMessage = "Failed to parse migration QR code."
                showingError = true
            }
            return
        }

        // Try to parse the regular OTP URI
        guard let account = Account.from(uri: code) else {
            errorMessage = "Invalid QR code. Please scan a valid 2FA QR code."
            showingError = true
            return
        }

        // Check for duplicates
        if dataManager.accounts.contains(where: { $0.secret == account.secret && $0.issuer == account.issuer }) {
            errorMessage = "This account has already been added."
            showingError = true
            return
        }

        // Show confirmation
        pendingAccount = account
        showingConfirmation = true
    }

    private func handleMigrationAccounts(_ accounts: [Account]) {
        var addedCount = 0
        var skippedCount = 0

        for account in accounts {
            // Check for duplicates
            if !dataManager.accounts.contains(where: { $0.secret == account.secret && $0.issuer == account.issuer }) {
                dataManager.addAccount(account)
                addedCount += 1
            } else {
                skippedCount += 1
            }
        }

        // Show result
        if addedCount > 0 && skippedCount > 0 {
            errorMessage = "Added \(addedCount) account(s). Skipped \(skippedCount) duplicate(s)."
        } else if addedCount > 0 {
            errorMessage = "Successfully added \(addedCount) account(s)."
        } else {
            errorMessage = "All accounts already exist."
        }
        showingError = true

        // Dismiss if all successful
        if addedCount > 0 && skippedCount == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }

    private func selectQRImage() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select QR Code Image"
        openPanel.allowedContentTypes = [.image]
        openPanel.allowsMultipleSelection = false

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                detectQRCode(from: url)
            }
        }
    }

    private func captureScreenshotWhileScanning() {
        // Temporarily stop the scanner
        isScanning = false

        // Small delay to allow UI to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Capture the main screen
            if let image = captureScreen() {
                detectQRCodeFromImage(image)
            } else {
                errorMessage = "Failed to capture screenshot."
                showingError = true
                // Resume scanning on error
                isScanning = true
            }
        }
    }

    private func captureScreenshot() {
        // Add a delay to allow user to show the QR code
        errorMessage = "Display the QR code on your screen. Capture will happen in 3 seconds..."
        showingError = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Capture the main screen
            if let image = captureScreen() {
                detectQRCodeFromImage(image)
            } else {
                errorMessage = "Failed to capture screenshot."
                showingError = true
            }
        }
    }

    private func captureScreen() -> NSImage? {
        // Get the main screen
        guard let screen = NSScreen.main else { return nil }

        // Create window list options to capture all windows
        let windowListOption = CGWindowListOption(arrayLiteral: .optionOnScreenOnly)
        let windowID = CGWindowID(0)

        // Capture the screen
        guard let screenshot = CGWindowListCreateImage(
            screen.frame,
            windowListOption,
            windowID,
            .bestResolution
        ) else { return nil }

        return NSImage(cgImage: screenshot, size: screen.frame.size)
    }

    private func detectQRCodeFromImage(_ image: NSImage) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            errorMessage = "Failed to process screenshot."
            showingError = true
            return
        }

        let ciImage = CIImage(cgImage: cgImage)

        // Try multiple detection strategies
        var qrCode: String?

        // Strategy 1: High accuracy detector
        if qrCode == nil {
            let detector = CIDetector(
                ofType: CIDetectorTypeQRCode,
                context: nil,
                options: [
                    CIDetectorAccuracy: CIDetectorAccuracyHigh,
                    CIDetectorMinFeatureSize: 0.1
                ]
            )
            let features = detector?.features(in: ciImage) ?? []
            if let qrFeature = features.first as? CIQRCodeFeature {
                qrCode = qrFeature.messageString
            }
        }

        // Strategy 2: Try with enhanced image
        if qrCode == nil {
            if let enhancedImage = enhanceImageForQRDetection(ciImage) {
                let detector = CIDetector(
                    ofType: CIDetectorTypeQRCode,
                    context: nil,
                    options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
                )
                let features = detector?.features(in: enhancedImage) ?? []
                if let qrFeature = features.first as? CIQRCodeFeature {
                    qrCode = qrFeature.messageString
                }
            }
        }

        if let code = qrCode {
            handleScannedCode(code)
        } else {
            errorMessage = "No QR code found in the screenshot. Make sure the QR code is clearly visible on screen."
            showingError = true
        }
    }

    private func enhanceImageForQRDetection(_ image: CIImage) -> CIImage? {
        // Apply filters to enhance QR code detection
        let filters = [
            "CIColorControls": [
                kCIInputSaturationKey: 0.0,  // Convert to grayscale
                kCIInputContrastKey: 1.5,    // Increase contrast
                kCIInputBrightnessKey: 0.0
            ],
            "CISharpenLuminance": [
                kCIInputSharpnessKey: 0.4
            ]
        ]

        var processedImage = image
        for (filterName, parameters) in filters {
            if let filter = CIFilter(name: filterName) {
                filter.setValue(processedImage, forKey: kCIInputImageKey)
                for (key, value) in parameters {
                    filter.setValue(value, forKey: key as String)
                }
                if let output = filter.outputImage {
                    processedImage = output
                }
            }
        }

        return processedImage
    }

    private func detectQRCode(from url: URL) {
        guard let image = NSImage(contentsOf: url) else {
            errorMessage = "Failed to load image."
            showingError = true
            return
        }

        // Use the enhanced detection method
        detectQRCodeFromImage(image)
    }
}

// NSViewRepresentable for QR code scanning
struct QRCodeScannerRepresentable: NSViewRepresentable {
    @Binding var scannedCode: String?
    @Binding var isScanning: Bool
    var manualCapture: Bool = false  // New parameter to disable auto-scanning

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true

        let captureSession = AVCaptureSession()
        context.coordinator.captureSession = captureSession

        // Configure session preset for better quality
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("No video capture device available")
            return view
        }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error creating video input: \(error)")
            return view
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("Cannot add video input to session")
            return view
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            // Only set delegate if not in manual capture mode
            if !manualCapture {
                // Set delegate and queue before configuring metadata types
                metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)

                // Configure metadata types after adding output
                let availableTypes = metadataOutput.availableMetadataObjectTypes
                print("Available metadata types: \(availableTypes)")

                // Set all QR-related types that are available
                var typesToSet: [AVMetadataObject.ObjectType] = []
                if availableTypes.contains(.qr) {
                    typesToSet.append(.qr)
                }
                if availableTypes.contains(.code128) {
                    typesToSet.append(.code128)
                }
                if availableTypes.contains(.aztec) {
                    typesToSet.append(.aztec)
                }
                if availableTypes.contains(.dataMatrix) {
                    typesToSet.append(.dataMatrix)
                }

                if !typesToSet.isEmpty {
                    metadataOutput.metadataObjectTypes = typesToSet
                    print("Set metadata types: \(typesToSet)")
                } else {
                    print("No supported metadata types available")
                }
            } else {
                print("Manual capture mode - auto-scanning disabled")
            }
        } else {
            print("Cannot add metadata output to session")
            return view
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        if view.layer == nil {
            view.layer = CALayer()
        }
        view.layer?.addSublayer(previewLayer)

        // Store preview layer for later updates
        context.coordinator.previewLayer = previewLayer

        // Start the session on a background queue
        DispatchQueue.global(qos: .userInitiated).async {
            if !captureSession.isRunning {
                captureSession.startRunning()
                print("Capture session started")
            }
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isScanning {
            if let session = context.coordinator.captureSession, !session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                    print("Restarting capture session")
                }
            }
        } else {
            if let session = context.coordinator.captureSession, session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    session.stopRunning()
                    print("Stopping capture session")
                }
            }
        }

        // Update preview layer frame if needed
        if let previewLayer = context.coordinator.previewLayer {
            previewLayer.frame = nsView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: QRCodeScannerRepresentable
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        private var lastScannedCode: String?
        private var lastScannedTime: Date?

        init(_ parent: QRCodeScannerRepresentable) {
            self.parent = parent
            super.init()
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                          didOutput metadataObjects: [AVMetadataObject],
                          from connection: AVCaptureConnection) {
            guard parent.isScanning else { return }

            for metadataObject in metadataObjects {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { continue }
                guard let stringValue = readableObject.stringValue else { continue }

                // Prevent duplicate scans within a short time window
                if let lastTime = lastScannedTime,
                   let lastCode = lastScannedCode,
                   lastCode == stringValue,
                   Date().timeIntervalSince(lastTime) < 2.0 {
                    continue
                }

                print("Scanned code: \(stringValue)")

                // Haptic feedback
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .levelChange,
                    performanceTime: .default
                )

                // Update parent's scanned code
                DispatchQueue.main.async {
                    self.lastScannedCode = stringValue
                    self.lastScannedTime = Date()
                    self.parent.scannedCode = stringValue
                }

                // Stop after first valid code
                break
            }
        }
    }
}