//
//  KeychainService.swift
//  TwoFactorAuth
//
//  Secure storage using macOS Keychain
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    private let serviceName = "com.twoFactorAuth.accounts"
    private let accountsKey = "2fa_accounts_data"

    private init() {}

    // Save accounts to keychain
    func saveAccounts(_ accounts: [Account]) -> Bool {
        do {
            let data = try JSONEncoder().encode(accounts)
            return save(data: data, for: accountsKey)
        } catch {
            print("Failed to encode accounts: \(error)")
            return false
        }
    }

    // Load accounts from keychain
    func loadAccounts() -> [Account] {
        guard let data = load(for: accountsKey) else {
            return []
        }

        do {
            let accounts = try JSONDecoder().decode([Account].self, from: data)
            return accounts
        } catch {
            print("Failed to decode accounts: \(error)")
            return []
        }
    }

    // Delete all accounts from keychain
    func deleteAllAccounts() -> Bool {
        return delete(for: accountsKey)
    }

    // MARK: - Private Keychain Operations

    private func save(data: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Try to delete any existing item first
        SecItemDelete(query as CFDictionary)

        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func load(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            return data
        }

        return nil
    }

    private func delete(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}