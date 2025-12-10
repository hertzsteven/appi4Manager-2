//
//  AuthenticationManager.swift
//  appi4Manager
//
//  Manages teacher authentication state and token persistence
//

import Foundation

/// Manages teacher authentication state and secure token storage
@Observable
final class AuthenticationManager {
    
    // MARK: - Observable Properties
    
    var token: String?
    var isAuthenticated: Bool = false
    var authenticatedUser: AuthenticateReturnObjct.AuthenticatedAs?
    var isValidating: Bool = false
    
    // MARK: - Keychain Keys
    
    private let tokenKey = "teacherAuthToken"
    private let userKey = "teacherAuthUser"
    
    // MARK: - Initialization
    
    init() {
        loadPersistedAuth()
    }
    
    // MARK: - Public Methods
    
    /// Authenticate teacher with credentials
    /// - Parameters:
    ///   - company: Company ID
    ///   - username: Teacher username
    ///   - password: Teacher password
    func authenticate(company: String, username: String, password: String) async throws {
        let response: AuthenticateReturnObjct = try await ApiManager.shared.getData(
            from: .authenticateTeacher(company: company, username: username, password: password)
        )
        
        // Update state on main thread
        await MainActor.run {
            self.token = response.token
            self.authenticatedUser = response.authenticatedAs
            self.isAuthenticated = true
            
            // Persist to Keychain
            saveToKeychain()
        }
        
        #if DEBUG
        print("✅ Teacher authenticated: \(response.authenticatedAs.name)")
        #endif
    }
    
    /// Validate the current token with the server
    /// - Returns: True if token is valid, false otherwise
    func validateCurrentToken() async -> Bool {
        guard let token = token else {
            return false
        }
        
        await MainActor.run {
            isValidating = true
        }
        
        defer {
            Task { @MainActor in
                isValidating = false
            }
        }
        
        // For now, we trust the cached token if it exists
        // A more robust implementation would call a /teacher/validate endpoint
        // but the existing ApiEndpoint doesn't have one yet
        
        #if DEBUG
        print("🔍 Token validation: using cached token for \(authenticatedUser?.name ?? "unknown")")
        #endif
        
        return true
    }
    
    /// Logout and clear stored credentials
    func logout() {
        token = nil
        authenticatedUser = nil
        isAuthenticated = false
        isValidating = false
        
        clearKeychain()
        
        #if DEBUG
        print("🚪 Teacher logged out")
        #endif
    }
    
    // MARK: - Private Methods
    
    /// Save authentication data to Keychain
    private func saveToKeychain() {
        guard let token = token,
              let authenticatedUser = authenticatedUser else { return }
        
        // Save token
        KeychainHelper.save(key: tokenKey, value: token)
        
        // Save user data as JSON
        KeychainHelper.save(key: userKey, object: authenticatedUser)
        
        #if DEBUG
        print("💾 Auth data saved to Keychain")
        #endif
    }
    
    /// Load authentication data from Keychain
    private func loadPersistedAuth() {
        // Load token
        guard let token = KeychainHelper.load(key: tokenKey) else {
            isAuthenticated = false
            return
        }
        
        // Load user data
        guard let user = KeychainHelper.load(key: userKey, as: AuthenticateReturnObjct.AuthenticatedAs.self) else {
            // Token exists but user data is corrupted, clear everything
            clearKeychain()
            isAuthenticated = false
            return
        }
        
        // Set token, user, and authenticated immediately (trust cached credentials)
        self.token = token
        self.authenticatedUser = user
        self.isAuthenticated = true
        
        #if DEBUG
        print("✅ Loaded persisted authentication for: \(user.name)")
        #endif
        
        // Optionally validate token in background
        Task {
            let isValid = await validateCurrentToken()
            if !isValid {
                await MainActor.run {
                    self.logout()
                }
            }
        }
    }
    
    /// Clear all authentication data from Keychain
    private func clearKeychain() {
        KeychainHelper.delete(key: tokenKey)
        KeychainHelper.delete(key: userKey)
        
        #if DEBUG
        print("🗑️ Keychain cleared")
        #endif
    }
}
