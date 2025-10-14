//
//  Account.swift
//  TwoFactorAuth
//
//  Account model for 2FA entries
//

import Foundation
import SwiftUI

struct Account: Identifiable, Codable, Hashable {
    let id: UUID
    var issuer: String
    var accountName: String
    var secret: String
    var algorithm: AlgorithmType
    var digits: Int
    var period: Int
    var iconName: String?
    var createdAt: Date
    var lastUsed: Date?

    enum AlgorithmType: String, Codable, CaseIterable {
        case sha1 = "SHA1"
        case sha256 = "SHA256"
        case sha512 = "SHA512"

        var totpAlgorithm: TOTPGenerator.Algorithm {
            switch self {
            case .sha1:
                return .sha1
            case .sha256:
                return .sha256
            case .sha512:
                return .sha512
            }
        }
    }

    init(
        id: UUID = UUID(),
        issuer: String,
        accountName: String,
        secret: String,
        algorithm: AlgorithmType = .sha1,
        digits: Int = 6,
        period: Int = 30,
        iconName: String? = nil,
        createdAt: Date = Date(),
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.issuer = issuer
        self.accountName = accountName
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
        self.iconName = iconName
        self.createdAt = createdAt
        self.lastUsed = lastUsed
    }

    // Generate current OTP code
    func generateCode() -> String {
        TOTPGenerator.generate(
            secret: secret,
            algorithm: algorithm.totpAlgorithm,
            digits: digits,
            period: TimeInterval(period)
        ) ?? "------"
    }

    // Get time remaining for current code
    var timeRemaining: TimeInterval {
        TOTPGenerator.timeRemaining(period: TimeInterval(period))
    }

    // Get progress for visual indicator
    var progress: Double {
        TOTPGenerator.progress(period: TimeInterval(period))
    }

    // Get display name
    var displayName: String {
        if !issuer.isEmpty && !accountName.isEmpty {
            return "\(issuer) (\(accountName))"
        } else if !issuer.isEmpty {
            return issuer
        } else {
            return accountName
        }
    }

    // Icon color based on issuer
    var iconColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan, .indigo]
        let hash = issuer.hashValue &+ accountName.hashValue
        return colors[abs(hash) % colors.count]
    }

    // Parse from otpauth:// URI
    static func from(uri: String) -> Account? {
        guard uri.hasPrefix("otpauth://totp/") || uri.hasPrefix("otpauth://hotp/") else {
            return nil
        }

        guard let url = URL(string: uri),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        // Parse label (issuer:accountName or just accountName)
        let label = url.path.replacingOccurrences(of: "/", with: "")
        var issuer = ""
        var accountName = label

        if let colonIndex = label.firstIndex(of: ":") {
            issuer = String(label[..<colonIndex])
            accountName = String(label[label.index(after: colonIndex)...])
        }

        // Parse query parameters
        var secret = ""
        var algorithm = AlgorithmType.sha1
        var digits = 6
        var period = 30

        if let queryItems = components.queryItems {
            for item in queryItems {
                switch item.name {
                case "secret":
                    secret = item.value ?? ""
                case "issuer":
                    issuer = item.value ?? issuer
                case "algorithm":
                    if let value = item.value?.uppercased() {
                        algorithm = AlgorithmType(rawValue: value) ?? .sha1
                    }
                case "digits":
                    digits = Int(item.value ?? "6") ?? 6
                case "period":
                    period = Int(item.value ?? "30") ?? 30
                default:
                    break
                }
            }
        }

        guard !secret.isEmpty else {
            return nil
        }

        // Decode URL encoding
        issuer = issuer.removingPercentEncoding ?? issuer
        accountName = accountName.removingPercentEncoding ?? accountName

        return Account(
            issuer: issuer,
            accountName: accountName,
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            period: period
        )
    }

    // Convert to otpauth:// URI
    func toURI() -> String {
        var components = URLComponents()
        components.scheme = "otpauth"
        components.host = "totp"

        let label = issuer.isEmpty ? accountName : "\(issuer):\(accountName)"
        components.path = "/\(label)"

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "secret", value: secret)
        ]

        if !issuer.isEmpty {
            queryItems.append(URLQueryItem(name: "issuer", value: issuer))
        }

        if algorithm != .sha1 {
            queryItems.append(URLQueryItem(name: "algorithm", value: algorithm.rawValue))
        }

        if digits != 6 {
            queryItems.append(URLQueryItem(name: "digits", value: String(digits)))
        }

        if period != 30 {
            queryItems.append(URLQueryItem(name: "period", value: String(period)))
        }

        components.queryItems = queryItems

        return components.url?.absoluteString ?? ""
    }
}