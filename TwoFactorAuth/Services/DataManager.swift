//
//  DataManager.swift
//  TwoFactorAuth
//
//  Central data management for accounts
//

import Foundation
import SwiftUI
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()

    @Published var accounts: [Account] = []
    @Published var searchText = ""
    @Published var selectedAccount: Account?
    @Published var isAddingAccount = false
    @Published var isScanning = false
    @Published private(set) var tick: Date = Date()

    private let keychain = KeychainService.shared
    private var refreshCancellable: Any?
    private var refreshTimer: Timer? // deprecated; kept if referenced elsewhere
    private var timerCancellable: AnyCancellable?

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
        // Publish a tick every second on the main run loop, updating a harmless published value
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.tick = date
            }
    }

    deinit {
        timerCancellable?.cancel()
        refreshTimer?.invalidate()
    }
}
