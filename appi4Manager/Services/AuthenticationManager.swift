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
        
        // Validate that teacher has at least one active class (with devices)
        let hasActiveClasses = try await validateTeacherHasActiveClasses(teacherId: response.authenticatedAs.id)
        
        guard hasActiveClasses else {
            #if DEBUG
            print("❌ Teacher \(response.authenticatedAs.name) has no active classes")
            #endif
            throw ApiError.noActiveClasses
        }
        
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
    
    /// Validates that a teacher has at least one active class (assigned and has devices)
    /// - Parameter teacherId: The teacher's user ID
    /// - Returns: True if teacher has at least one active class, false otherwise
    private func validateTeacherHasActiveClasses(teacherId: Int) async throws -> Bool {
        // 1. Fetch the teacher's user details to get their teacherGroups
        let userDetailResponse: UserDetailResponse = try await ApiManager.shared.getData(
            from: .getaUser(id: teacherId)
        )
        let teacherGroupIds = userDetailResponse.user.teacherGroups
        
        #if DEBUG
        print("📚 Teacher's teacherGroups: \(teacherGroupIds)")
        #endif
        
        // If teacher has no assigned groups, they have no classes
        guard !teacherGroupIds.isEmpty else {
            return false
        }
        
        // 2. Fetch all school classes
        let classesResponse: SchoolClassResponse = try await ApiManager.shared.getData(
            from: .getSchoolClasses
        )
        
        // 3. Filter classes where userGroupId is in the teacher's teacherGroups
        let matchingClasses = classesResponse.classes.filter { schoolClass in
            teacherGroupIds.contains(schoolClass.userGroupId)
        }
        
        #if DEBUG
        print("📚 Found \(matchingClasses.count) classes assigned to teacher")
        #endif
        
        // If no classes match, teacher has no classes
        guard !matchingClasses.isEmpty else {
            return false
        }
        
        // 4. Check if at least one class has devices (stop early on first match)
        for schoolClass in matchingClasses {
            do {
                let deviceResponse: DeviceListResponse = try await ApiManager.shared.getData(
                    from: .getDevices(assettag: String(schoolClass.userGroupId))
                )
                
                if !deviceResponse.devices.isEmpty {
                    #if DEBUG
                    print("✅ Found active class '\(schoolClass.name)' with \(deviceResponse.devices.count) device(s)")
                    #endif
                    return true
                }
            } catch {
                #if DEBUG
                print("⚠️ Failed to fetch devices for class \(schoolClass.name): \(error)")
                #endif
                // Continue checking other classes
            }
        }
        
        #if DEBUG
        print("❌ No classes have devices assigned")
        #endif
        
        return false
    }
    
    /// Validate the current token with the server using the dedicated /teacher/validate endpoint
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
        
        do {
            // Use dedicated validation endpoint and check response
            let response: TokenValidationResponse = try await ApiManager.shared.getData(
                from: .validateTeacherToken(token: token)
            )
            
            // Check if token is valid based on response code and message
            let isValid = response.isValid
            
            #if DEBUG
            if isValid {
                print("✅ Token validation successful for \(authenticatedUser?.name ?? "unknown")")
            } else {
                print("❌ Token validation failed: \(response.message)")
            }
            #endif
            
            return isValid
            
        } catch let error as ApiError {
            switch error {
            case .clientUnauthorized, .clientForbidden:
                #if DEBUG
                print("❌ Token validation failed: unauthorized or forbidden")
                #endif
                return false
            default:
                // For other errors (network issues, etc.), we'll trust the cached token
                #if DEBUG
                print("⚠️ Token validation error (trusting cache): \(error.localizedDescription)")
                #endif
                return true
            }
        } catch {
            // For unexpected errors, trust the cached token
            #if DEBUG
            print("⚠️ Token validation unexpected error (trusting cache): \(error.localizedDescription)")
            #endif
            return true
        }
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
