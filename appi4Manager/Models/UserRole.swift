//
//  UserRole.swift
//  appi4Manager
//
//  Defines the user role types for the app
//

import Foundation

/// Represents the role a user has selected in the app
enum UserRole: String, Codable, CaseIterable {
    case admin = "admin"
    case teacher = "teacher"
    
    /// Display name for the role
    var displayName: String {
        switch self {
        case .admin:
            return "Administrator"
        case .teacher:
            return "Teacher"
        }
    }
    
    /// Description of what this role does
    var description: String {
        switch self {
        case .admin:
            return "Setup classes, students, and devices"
        case .teacher:
            return "Manage your class devices and app schedules"
        }
    }
    
    /// SF Symbol icon for the role
    var iconName: String {
        switch self {
        case .admin:
            return "gearshape.2.fill"
        case .teacher:
            return "person.fill.checkmark"
        }
    }
}
