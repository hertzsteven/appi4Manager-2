//
//  StudentRestrictionProfile.swift
//  appi4Manager
//
//  Response model for /teacher/profiles endpoint
//  Shows which students have active device restrictions
//

import Foundation

/// A student's current restriction profile from the teacher API
/// Based on actual API response format:
/// - If `appWhitelist` is empty or nil, the student has no app lock
/// - If `appWhitelist` contains bundle IDs, the student is locked into those apps
struct StudentRestrictionProfile: Codable, Identifiable {
    let studentId: Int
    let appWhitelist: [String]?       // Array of app bundle IDs the device is locked into
    let restrictions: [String]?        // Array of restriction identifiers
    let startDate: String?             // Unix timestamp as string
    let endDate: String?               // Unix timestamp as string
    let genresBlacklist: [String]?     // Blocked app genres
    let lessonId: Int?                 // Associated lesson ID if part of a lesson
    let materials: MaterialsInfo?      // Safari/web restrictions
    
    var id: Int { studentId }
    
    /// Returns true if the student has any active app lock restrictions
    var hasActiveRestrictions: Bool {
        if let apps = appWhitelist, !apps.isEmpty {
            return true
        }
        return false
    }
    
    /// Returns the first locked app bundle ID, if any
    var lockedAppBundleId: String? {
        appWhitelist?.first
    }
    
    /// Returns a user-friendly description of the lock status
    var lockStatusDescription: String {
        if let apps = appWhitelist, !apps.isEmpty {
            return "Locked into: \(apps.joined(separator: ", "))"
        }
        return "Unlocked"
    }
}

/// Materials/Safari restrictions
struct MaterialsInfo: Codable {
    let lockInSafari: Bool?
    let weblock: Bool?
    let sites: [String]?   // Array of allowed/blocked site URLs
}

/// Response type alias for the profiles array
typealias TeacherProfilesResponse = [StudentRestrictionProfile]

