//
//  RoleManager.swift
//  appi4Manager
//
//  Manages the current user role and persists selection
//

import Foundation
import SwiftUI

/// Manages the current user role selection and persistence
@Observable
class RoleManager {
    
    // MARK: - Properties
    
    /// The currently selected role, nil if none selected yet
    var currentRole: UserRole? {
        didSet {
            if let role = currentRole {
                UserDefaults.standard.set(role.rawValue, forKey: Self.roleKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.roleKey)
            }
        }
    }
    
    /// Whether a role has been selected
    var hasSelectedRole: Bool {
        currentRole != nil
    }
    
    // MARK: - Private Properties
    
    private static let roleKey = "selectedUserRole"
    
    // MARK: - Initialization
    
    init() {
        // Load saved role from UserDefaults
        if let savedRole = UserDefaults.standard.string(forKey: Self.roleKey),
           let role = UserRole(rawValue: savedRole) {
            self.currentRole = role
        }
    }
    
    // MARK: - Methods
    
    /// Select a role
    func selectRole(_ role: UserRole) {
        currentRole = role
    }
    
    /// Clear the selected role (for switching roles)
    func clearRole() {
        currentRole = nil
    }
    
    /// Check if current role is admin
    var isAdmin: Bool {
        currentRole == .admin
    }
    
    /// Check if current role is teacher
    var isTeacher: Bool {
        currentRole == .teacher
    }
}
