//
//  TOTPGenerator.swift
//  TwoFactorAuth
//
//  TOTP (Time-based One-Time Password) generator
//

import Foundation
import CryptoKit

class TOTPGenerator {

    enum Algorithm {
        case sha1
        case sha256
        case sha512

        var hmacFunction: (SymmetricKey, Data) -> Data {
            switch self {
            case .sha1:
                return { key, data in
                    Data(HMAC<Insecure.SHA1>.authenticationCode(for: data, using: key))
                }
            case .sha256:
                return { key, data in
                    Data(HMAC<SHA256>.authenticationCode(for: data, using: key))
                }
            case .sha512:
                return { key, data in
                    Data(HMAC<SHA512>.authenticationCode(for: data, using: key))
                }
            }
        }
    }

    static func generate(
        secret: String,
        algorithm: Algorithm = .sha1,
        digits: Int = 6,
        period: TimeInterval = 30
    ) -> String? {
        guard let secretData = base32Decode(secret.replacingOccurrences(of: " ", with: "")) else {
            return nil
        }

        let counter = UInt64(Date().timeIntervalSince1970 / period)
        let counterData = withUnsafeBytes(of: counter.bigEndian) { Data($0) }

        let key = SymmetricKey(data: secretData)
        let hmac = algorithm.hmacFunction(key, counterData)

        // Dynamic truncation
        let offset = Int(hmac[hmac.count - 1] & 0x0f)
        let truncatedHash = hmac[offset..<offset + 4]

        var code = truncatedHash.withUnsafeBytes { bytes in
            var value: UInt32 = 0
            for (index, byte) in bytes.enumerated() {
                value |= UInt32(byte) << UInt32((3 - index) * 8)
            }
            return Int(value & 0x7fffffff)
        }

        let divisor = Int(pow(10.0, Double(digits)))
        code = code % divisor

        return String(format: "%0\(digits)d", code)
    }

    static func timeRemaining(period: TimeInterval = 30) -> TimeInterval {
        let currentTime = Date().timeIntervalSince1970
        return period - (currentTime.truncatingRemainder(dividingBy: period))
    }

    static func progress(period: TimeInterval = 30) -> Double {
        let remaining = timeRemaining(period: period)
        return (period - remaining) / period
    }

    // Base32 decoder
    private static func base32Decode(_ string: String) -> Data? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let cleaned = string.uppercased().replacingOccurrences(of: "=", with: "")

        var bits = ""
        for char in cleaned {
            guard let index = alphabet.firstIndex(of: char) else {
                return nil
            }
            let value = alphabet.distance(from: alphabet.startIndex, to: index)
            bits += String(value, radix: 2).padLeft(toLength: 5, withPad: "0")
        }

        var data = Data()
        for i in stride(from: 0, to: bits.count - 7, by: 8) {
            let startIndex = bits.index(bits.startIndex, offsetBy: i)
            let endIndex = bits.index(startIndex, offsetBy: 8)
            let byteBits = String(bits[startIndex..<endIndex])
            if let byte = UInt8(byteBits, radix: 2) {
                data.append(byte)
            }
        }

        return data
    }
}

extension String {
    func padLeft(toLength: Int, withPad: String) -> String {
        let padding = String(repeating: withPad, count: max(0, toLength - self.count))
        return padding + self
    }
}