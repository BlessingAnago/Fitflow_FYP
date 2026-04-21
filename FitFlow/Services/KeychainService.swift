//
//  KeychainService.swift
//  FitFlow
//
//  Secure on-device credential storage using iOS Keychain.
//  Passwords are hashed with SHA256 before storage.
//

import Foundation
import Security
import CryptoKit

enum KeychainError: Error, LocalizedError {
    case duplicateEntry
    case itemNotFound
    case unexpectedStatus(OSStatus)
    case invalidData
    case wrongPassword

    var errorDescription: String? {
        switch self {
        case .duplicateEntry: return "An account with this email already exists."
        case .itemNotFound: return "No account found with that email."
        case .unexpectedStatus(let s): return "Keychain error: \(s)"
        case .invalidData: return "Could not read stored data."
        case .wrongPassword: return "Current password is incorrect."
        }
    }
}

struct KeychainService {
    private static let service = "com.fitflow.auth"

    // MARK: - Password hashing

    static func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Save credentials

    static func saveCredentials(email: String, passwordHash: String) throws {
        let account = email.lowercased()
        let data = Data(passwordHash.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            throw KeychainError.duplicateEntry
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Retrieve stored hash

    static func retrievePasswordHash(for email: String) throws -> String {
        let account = email.lowercased()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data, let hash = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return hash
    }

    // MARK: - Validate credentials

    static func validateCredentials(email: String, password: String) -> Bool {
        do {
            let storedHash = try retrievePasswordHash(for: email)
            return storedHash == hashPassword(password)
        } catch {
            return false
        }
    }

    // MARK: - Check if account exists

    static func accountExists(email: String) -> Bool {
        do {
            _ = try retrievePasswordHash(for: email)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Update password

    static func updatePassword(for email: String, currentPassword: String, newPassword: String) throws {
        let account = email.lowercased()
        let currentHash = hashPassword(currentPassword)
        let newHash = hashPassword(newPassword)

        do {
            let storedHash = try retrievePasswordHash(for: email)
            guard storedHash == currentHash else {
                throw KeychainError.wrongPassword
            }
            try deleteCredentials(for: email)
            try saveCredentials(email: account, passwordHash: newHash)
        } catch let e as KeychainError {
            throw e
        } catch {
            throw KeychainError.itemNotFound
        }
    }
    
    // MARK: - Delete credentials

    static func deleteCredentials(for email: String) throws {
        let account = email.lowercased()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Store logged-in email in UserDefaults (not sensitive)

    static func saveLoggedInEmail(_ email: String) {
        UserDefaults.standard.set(email.lowercased(), forKey: "loggedInEmail")
    }

    static func getLoggedInEmail() -> String? {
        UserDefaults.standard.string(forKey: "loggedInEmail")
    }

    static func clearLoggedInEmail() {
        UserDefaults.standard.removeObject(forKey: "loggedInEmail")
    }
}
