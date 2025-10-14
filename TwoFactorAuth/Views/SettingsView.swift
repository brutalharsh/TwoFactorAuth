//
//  SettingsView.swift
//  TwoFactorAuth
//
//  Settings view for the app
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("showCodeInMenuBar") private var showCodeInMenuBar = false
    @AppStorage("useBiometrics") private var useBiometrics = true

    var body: some View {
        TabView {
            // General settings
            Form {
                Section {
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