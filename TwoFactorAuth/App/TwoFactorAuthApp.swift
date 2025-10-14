//
//  TwoFactorAuthApp.swift
//  TwoFactorAuth
//
//  2FA Authenticator for macOS
//

import SwiftUI

@main
struct TwoFactorAuthApp: App {
    @StateObject private var dataManager = DataManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()

            CommandGroup(replacing: .newItem) {
                Button("Add Account") {
                    NotificationCenter.default.post(name: .addNewAccount, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(dataManager)
        }
    }
}

extension Notification.Name {
    static let addNewAccount = Notification.Name("addNewAccount")
    static let refreshAccounts = Notification.Name("refreshAccounts")
}
