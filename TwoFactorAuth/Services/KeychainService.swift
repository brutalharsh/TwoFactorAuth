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

    // Export accounts with encryption
    func exportAccounts(_ accounts: [Account], password: String) -> Data? {
        do {
            let accountData = try JSONEncoder().encode(accounts)

            // Create a simple encrypted container
            let exportData = EncryptedExport(
                data: accountData,
                timestamp: Date(),
                version: "1.0"
            )

            let jsonData = try JSONEncoder().encode(exportData)

            // In a production app, you'd want to use proper encryption here
            // For now, we'll return the JSON data with a basic XOR cipher
            return xorEncrypt(data: jsonData, key: password)
        } catch {
            print("Failed to export accounts: \(error)")
            return nil
        }
    }

    // Import accounts with decryption
    func importAccounts(from data: Data, password: String) -> [Account]? {
        guard let decryptedData = xorEncrypt(data: data, key: password) else {
            return nil
        }

        do {
            let exportData = try JSONDecoder().decode(EncryptedExport.self, from: decryptedData)
            let accounts = try JSONDecoder().decode([Account].self, from: exportData.data)
            return accounts
        } catch {
            print("Failed to import accounts: \(error)")
            return nil
        }
    }

    // Simple XOR encryption (for demonstration - use proper encryption in production)
    private func xorEncrypt(data: Data, key: String) -> Data? {
        guard !key.isEmpty else { return nil }

        let keyData = key.data(using: .utf8)!
        var encrypted = Data()

        for (index, byte) in data.enumerated() {
            let keyByte = keyData[index % keyData.count]
            encrypted.append(byte ^ keyByte)
        }

        return encrypted
    }
}

// Encrypted export container
struct EncryptedExport: Codable {
    let data: Data
    let timestamp: Date
    let version: String
}