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
                        isScanning: $isScanning
                    )
                    .overlay(
                        // Scanning overlay
                        ZStack {
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
                    // Start scanning prompt
                    VStack(spacing: 20) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)

                        Text("Click to Start Scanning")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Button("Start Scanner") {
                            requestCameraAccess()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.9))

            // Instructions
            VStack(spacing: 8) {
                Text("Position the QR code within the frame")
                    .font(.headline)

                Text("The code will be scanned automatically")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 600, height: 500)
        .onChange(of: scannedCode) { _, newValue in
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

        // Try to parse the OTP URI
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
}

// NSViewRepresentable for QR code scanning
struct QRCodeScannerRepresentable: NSViewRepresentable {
    @Binding var scannedCode: String?
    @Binding var isScanning: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let captureSession = AVCaptureSession()
        context.coordinator.captureSession = captureSession

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return view
        }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return view
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return view
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return view
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer = CALayer()
        view.layer?.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isScanning {
            context.coordinator.captureSession?.startRunning()
        } else {
            context.coordinator.captureSession?.stopRunning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: QRCodeScannerRepresentable
        var captureSession: AVCaptureSession?

        init(_ parent: QRCodeScannerRepresentable) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                          didOutput metadataObjects: [AVMetadataObject],
                          from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }

                // Haptic feedback
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .levelChange,
                    performanceTime: .default
                )

                parent.scannedCode = stringValue
            }
        }
    }
}