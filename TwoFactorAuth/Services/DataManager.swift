//
//  DataManager.swift
//  TwoFactorAuth
//
//  Central data management for accounts
//

import Foundation
import SwiftUI

class DataManager: ObservableObject {
    static let shared = DataManager()

    @Published var accounts: [Account] = []
    @Published var searchText = ""
    @Published var selectedAccount: Account?
    @Published var isAddingAccount = false
    @Published var isScanning = false

    private let keychain = KeychainService.shared
    private var refreshTimer: Timer?

    private init() {
        loadAccounts()
        startRefreshTimer()
    }

    // MARK: - Account Management

    func loadAccounts() {
        accounts = keychain.loadAccounts()
    }

    func saveAccounts() {
        _ = keychain.saveAccounts(accounts)
    }

    func addAccount(_ account: Account) {
        accounts.append(account)
        saveAccounts()
        objectWillChange.send()
    }

    func updateAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts()
            objectWillChange.send()
        }
    }

    func deleteAccount(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
        objectWillChange.send()
    }

    func deleteAccounts(at offsets: IndexSet) {
        accounts.remove(atOffsets: offsets)
        saveAccounts()
    }

    func moveAccounts(from source: IndexSet, to destination: Int) {
        accounts.move(fromOffsets: source, toOffset: destination)
        saveAccounts()
    }

    // MARK: - Search and Filter

    var filteredAccounts: [Account] {
        if searchText.isEmpty {
            return accounts
        } else {
            return accounts.filter { account in
                account.issuer.localizedCaseInsensitiveContains(searchText) ||
                account.accountName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Import/Export

    func exportAccounts(password: String) -> Data? {
        return keychain.exportAccounts(accounts, password: password)
    }

    func importAccounts(from data: Data, password: String) -> Bool {
        guard let importedAccounts = keychain.importAccounts(from: data, password: password) else {
            return false
        }

        // Merge with existing accounts (avoid duplicates)
        for account in importedAccounts {
            if !accounts.contains(where: { $0.secret == account.secret && $0.issuer == account.issuer }) {
                accounts.append(account)
            }
        }

        saveAccounts()
        return true
    }

    func importFromURI(_ uri: String) -> Bool {
        guard let account = Account.from(uri: uri) else {
            return false
        }

        // Check for duplicates
        if accounts.contains(where: { $0.secret == account.secret && $0.issuer == account.issuer }) {
            return false
        }

        addAccount(account)
        return true
    }

    // MARK: - Code Generation

    func generateCode(for account: Account) -> String {
        // Update last used
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index].lastUsed = Date()
            saveAccounts()
        }

        return account.generateCode()
    }

    func copyCode(for account: Account) {
        let code = generateCode(for: account)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
    }

    // MARK: - Timer for UI Updates

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // This will trigger UI updates for progress indicators
            self.objectWillChange.send()
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }

    // MARK: - Demo Data

    func loadDemoAccounts() {
        let demoAccounts = [
            Account(
                issuer: "GitHub",
                accountName: "john.doe@example.com",
                secret: "JBSWY3DPEHPK3PXP"
            ),
            Account(
                issuer: "Google",
                accountName: "john.doe@gmail.com",
                secret: "HXDMVJECJJWSRB3H"
            ),
            Account(
                issuer: "Microsoft",
                accountName: "john.doe@outlook.com",
                secret: "GEZDGNBVGY3TQOJQ"
            ),
            Account(
                issuer: "Amazon AWS",
                accountName: "admin",
                secret: "MFRGGZDFMZTWQ2LK"
            ),
            Account(
                issuer: "Dropbox",
                accountName: "john.doe@company.com",
                secret: "NNXWC3LQNRUXG2DJ"
            )
        ]

        accounts = demoAccounts
        saveAccounts()
    }
}