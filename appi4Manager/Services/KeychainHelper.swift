//
//  KeychainHelper.swift
//  appi4Manager
//
//  Reusable helper for secure Keychain storage operations
//

import Foundation
import Security

/// A reusable helper for Keychain operations
enum KeychainHelper {
    
    // MARK: - Constants
    
    private static let service = "com.appi4manager.teacher"
    
    // MARK: - Public Methods
    
    /// Save a string value to Keychain
    /// - Parameters:
    ///   - key: The key to store the value under
    ///   - value: The string value to store
    /// - Returns: True if save was successful
    @discardableResult
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete any existing item first
        delete(key: key)
        
        // Create new keychain item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        #if DEBUG
        if status != errSecSuccess {
            print("⚠️ KeychainHelper: Failed to save '\(key)' - status: \(status)")
        }
        #endif
        
        return status == errSecSuccess
    }
    
    /// Load a string value from Keychain
    /// - Parameter key: The key to retrieve
    /// - Returns: The stored string value, or nil if not found
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    /// Delete a value from Keychain
    /// - Parameter key: The key to delete
    /// - Returns: True if deletion was successful (or item didn't exist)
    @discardableResult
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Save an Encodable object to Keychain as JSON
    /// - Parameters:
    ///   - key: The key to store the value under
    ///   - value: The Encodable object to store
    /// - Returns: True if save was successful
    @discardableResult
    static func save<T: Encodable>(key: String, object: T) -> Bool {
        guard let data = try? JSONEncoder().encode(object),
              let jsonString = String(data: data, encoding: .utf8) else {
            return false
        }
        return save(key: key, value: jsonString)
    }
    
    /// Load a Decodable object from Keychain
    /// - Parameters:
    ///   - key: The key to retrieve
    ///   - type: The type to decode to
    /// - Returns: The decoded object, or nil if not found or decoding failed
    static func load<T: Decodable>(key: String, as type: T.Type) -> T? {
        guard let jsonString = load(key: key),
              let data = jsonString.data(using: .utf8),
              let object = try? JSONDecoder().decode(type, from: data) else {
            return nil
        }
        return object
    }
}
