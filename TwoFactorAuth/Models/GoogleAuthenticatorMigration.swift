//
//  GoogleAuthenticatorMigration.swift
//  TwoFactorAuth
//
//  Parse Google Authenticator migration QR codes
//

import Foundation

// Google Authenticator Migration Protocol Buffer structures
// These are simplified representations of the protobuf format

struct MigrationPayload {
    struct OTPParameter {
        let secret: Data
        let name: String?
        let issuer: String?
        let algorithm: Int32
        let digits: Int32
        let type: Int32
        let counter: Int64
        let period: Int32
    }

    let otpParameters: [OTPParameter]
    let version: Int32
    let batchSize: Int32
    let batchIndex: Int32
}

class GoogleAuthenticatorMigration {

    static func parseGoogleAuthenticatorMigration(uri: String) -> [Account]? {
        guard let url = URL(string: uri),
              url.scheme == "otpauth-migration",
              url.host == "offline" else {
            return nil
        }

        // Get the data parameter
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let dataParam = components?.queryItems?.first(where: { $0.name == "data" })?.value else {
            return nil
        }

        // Decode base64 (URL-safe base64)
        let base64String = dataParam
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        let padding = (4 - base64String.count % 4) % 4
        let paddedBase64 = base64String + String(repeating: "=", count: padding)

        guard let data = Data(base64Encoded: paddedBase64) else {
            return nil
        }

        return parseProtobufData(data)
    }

    private static func parseProtobufData(_ data: Data) -> [Account]? {
        var accounts: [Account] = []
        var index = 0

        while index < data.count {
            let fieldResult = decodeVarint(data, from: index)
            let fieldNumber = fieldResult.0
            index = fieldResult.1
            let wireType = fieldNumber & 0x07

            if wireType == 2 && fieldNumber >> 3 == 1 { // OTP Parameter field
                let lengthResult = decodeVarint(data, from: index)
                let length = lengthResult.0
                index = lengthResult.1

                if let account = parseOTPParameter(data, from: index, length: Int(length)) {
                    accounts.append(account)
                }
                index += Int(length)
            } else {
                // Skip other fields
                index = skipField(data, from: index, wireType: wireType)
            }
        }

        return accounts.isEmpty ? nil : accounts
    }

    private static func parseOTPParameter(_ data: Data, from startIndex: Int, length: Int) -> Account? {
        var index = startIndex
        let endIndex = startIndex + length

        var secret: Data?
        var name: String?
        var issuer: String?
        var algorithm: Int32 = 0 // SHA1
        var digits: Int32 = 6
        var type: Int32 = 2 // TOTP
        var period: Int32 = 30

        while index < endIndex {
            let fieldResult = decodeVarint(data, from: index)
            let fieldNumber = fieldResult.0
            index = fieldResult.1
            let wireType = fieldNumber & 0x07

            let fieldId = fieldNumber >> 3

            switch fieldId {
            case 1: // Secret
                let lengthResult = decodeVarint(data, from: index)
                let length = lengthResult.0
                index = lengthResult.1
                secret = data.subdata(in: index..<(index + Int(length)))
                index += Int(length)
            case 2: // Name
                let lengthResult = decodeVarint(data, from: index)
                let length = lengthResult.0
                index = lengthResult.1
                name = String(data: data.subdata(in: index..<(index + Int(length))), encoding: .utf8)
                index += Int(length)
            case 3: // Issuer
                let lengthResult = decodeVarint(data, from: index)
                let length = lengthResult.0
                index = lengthResult.1
                issuer = String(data: data.subdata(in: index..<(index + Int(length))), encoding: .utf8)
                index += Int(length)
            case 4: // Algorithm
                let value = decodeVarint(data, from: index)
                algorithm = Int32(value.0)
                index = value.1
            case 5: // Digits
                let value = decodeVarint(data, from: index)
                digits = Int32(value.0)
                index = value.1
                print("Migration: Parsed digits field = \(digits)")  // Debug log
            case 6: // Type
                let value = decodeVarint(data, from: index)
                type = Int32(value.0)
                index = value.1
            case 8: // Period (for TOTP)
                let value = decodeVarint(data, from: index)
                period = Int32(value.0)
                index = value.1
            default:
                index = skipField(data, from: index, wireType: wireType)
            }
        }

        // Only support TOTP (type == 2)
        guard type == 2,
              let secretData = secret else {
            return nil
        }

        // Convert secret to base32
        let base32Secret = base32Encode(secretData)

        // Parse name and issuer
        let accountName: String
        let accountIssuer: String

        if let name = name {
            // Name might be in format "issuer:account" or just "account"
            let parts = name.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                accountIssuer = issuer ?? String(parts[0])
                accountName = String(parts[1])
            } else {
                accountIssuer = issuer ?? "Unknown"
                accountName = name
            }
        } else {
            accountIssuer = issuer ?? "Unknown"
            accountName = ""
        }

        // Convert algorithm (Google uses 1 for SHA1, not 0)
        let alg: Account.AlgorithmType
        switch algorithm {
        case 1, 0: alg = .sha1  // Google uses 1 for SHA1, but handle 0 as well
        case 2: alg = .sha256
        case 3: alg = .sha512
        default: alg = .sha1
        }

        // Ensure digits is valid (default to 6 if not set or is 1)
        // Google Authenticator sometimes exports with digits=1 which should be 6
        let finalDigits = (digits <= 1) ? 6 : Int(digits)
        print("Migration: digits=\(digits) -> finalDigits=\(finalDigits)")  // Debug log

        // Ensure period is valid (default to 30 if not set)
        let finalPeriod = (period == 0) ? 30 : Int(period)
        print("Migration: period=\(period) -> finalPeriod=\(finalPeriod)")  // Debug log

        return Account(
            issuer: accountIssuer,
            accountName: accountName,
            secret: base32Secret,
            algorithm: alg,
            digits: finalDigits,
            period: finalPeriod
        )
    }

    private static func decodeVarint(_ data: Data, from index: Int) -> (UInt64, Int) {
        var value: UInt64 = 0
        var shift: UInt64 = 0
        var currentIndex = index

        while currentIndex < data.count {
            let byte = data[currentIndex]
            value |= UInt64(byte & 0x7F) << shift
            currentIndex += 1
            if byte & 0x80 == 0 {
                break
            }
            shift += 7
        }

        return (value, currentIndex)
    }

    private static func skipField(_ data: Data, from index: Int, wireType: UInt64) -> Int {
        switch wireType {
        case 0: // Varint
            let result = decodeVarint(data, from: index)
            return result.1
        case 1: // 64-bit
            return index + 8
        case 2: // Length-delimited
            let length = decodeVarint(data, from: index)
            return length.1 + Int(length.0)
        case 5: // 32-bit
            return index + 4
        default:
            return index
        }
    }

    // Base32 encoding
    private static func base32Encode(_ data: Data) -> String {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var result = ""
        var buffer = 0
        var bitsLeft = 0

        for byte in data {
            buffer = (buffer << 8) | Int(byte)
            bitsLeft += 8

            while bitsLeft >= 5 {
                let index = (buffer >> (bitsLeft - 5)) & 0x1F
                result.append(alphabet[alphabet.index(alphabet.startIndex, offsetBy: index)])
                bitsLeft -= 5
            }
        }

        if bitsLeft > 0 {
            let index = (buffer << (5 - bitsLeft)) & 0x1F
            result.append(alphabet[alphabet.index(alphabet.startIndex, offsetBy: index)])
        }

        return result
    }
}