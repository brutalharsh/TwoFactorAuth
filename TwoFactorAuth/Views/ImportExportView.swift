//
//  ImportExportView.swift
//  TwoFactorAuth
//
//  Import and export accounts functionality
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingExportSavePanel = false
    @State private var showingImportOpenPanel = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Import/Export Accounts")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content
            VStack(spacing: 30) {
                // Export section
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Export Accounts", systemImage: "square.and.arrow.up")
                            .font(.headline)

                        Text("Export all your accounts to an encrypted file that can be imported later.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            SecureField("Password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)

                            Button("Export...") {
                                exportAccounts()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(password.isEmpty)
                        }

                        Text("Use a strong password to encrypt your export file.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                // Import section
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Import Accounts", systemImage: "square.and.arrow.down")
                            .font(.headline)

                        Text("Import accounts from a previously exported file.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button("Choose File...") {
                            importAccounts()
                        }
                        .buttonStyle(.borderedProminent)

                        Text("You'll need the password that was used to export the file.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                // Warning
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("Keep your export file and password secure. Anyone with both can access your accounts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()

            Spacer()
        }
        .frame(width: 500, height: 450)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func exportAccounts() {
        guard let exportData = dataManager.exportAccounts(password: password) else {
            showAlert(title: "Export Failed", message: "Failed to export accounts.")
            return
        }

        let savePanel = NSSavePanel()
        savePanel.title = "Export Accounts"
        savePanel.allowedContentTypes = [UTType(filenameExtension: "2fa")!]
        savePanel.nameFieldStringValue = "accounts.2fa"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try exportData.write(to: url)
                    showAlert(title: "Export Successful", message: "Accounts exported successfully.")
                    password = ""
                } catch {
                    showAlert(title: "Export Failed", message: "Failed to save file: \(error.localizedDescription)")
                }
            }
        }
    }

    private func importAccounts() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Import Accounts"
        openPanel.allowedContentTypes = [UTType(filenameExtension: "2fa")!]
        openPanel.allowsMultipleSelection = false

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                // Show password prompt
                promptForPassword { password in
                    do {
                        let data = try Data(contentsOf: url)
                        if dataManager.importAccounts(from: data, password: password) {
                            showAlert(title: "Import Successful", message: "Accounts imported successfully.")
                        } else {
                            showAlert(title: "Import Failed", message: "Invalid password or corrupted file.")
                        }
                    } catch {
                        showAlert(title: "Import Failed", message: "Failed to read file: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func promptForPassword(completion: @escaping (String) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Enter Password"
        alert.informativeText = "Enter the password used to export this file:"
        alert.alertStyle = .informational

        let passwordField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = passwordField

        alert.addButton(withTitle: "Import")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            completion(passwordField.stringValue)
        }
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// Settings View
struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("autoLock") private var autoLock = true
    @AppStorage("autoLockTimeout") private var autoLockTimeout = 5
    @AppStorage("showCodeInMenuBar") private var showCodeInMenuBar = false
    @AppStorage("useBiometrics") private var useBiometrics = true

    var body: some View {
        TabView {
            // General settings
            Form {
                Section {
                    Toggle("Auto-lock when inactive", isOn: $autoLock)

                    if autoLock {
                        Picker("Lock after", selection: $autoLockTimeout) {
                            Text("1 minute").tag(1)
                            Text("5 minutes").tag(5)
                            Text("10 minutes").tag(10)
                            Text("30 minutes").tag(30)
                        }
                    }

                    Toggle("Use Touch ID to unlock", isOn: $useBiometrics)
                    Toggle("Show codes in menu bar", isOn: $showCodeInMenuBar)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gear")
            }

            // Security settings
            Form {
                Section {
                    Button("Clear All Accounts") {
                        clearAllAccounts()
                    }
                    .foregroundColor(.red)

                    Text("This will permanently delete all accounts from this device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Security", systemImage: "lock")
            }

            // About
            VStack(spacing: 20) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)

                Text("Two-Factor Authenticator")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("A secure 2FA app for macOS")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 450, height: 300)
    }

    private func clearAllAccounts() {
        let alert = NSAlert()
        alert.messageText = "Clear All Accounts?"
        alert.informativeText = "This will permanently delete all accounts. This action cannot be undone."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Clear All")

        if alert.runModal() == .alertSecondButtonReturn {
            dataManager.accounts.removeAll()
            dataManager.saveAccounts()
        }
    }
}