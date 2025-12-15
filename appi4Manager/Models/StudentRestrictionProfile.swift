//
//  StudentRestrictionProfile.swift
//  appi4Manager
//
//  Response model for /teacher/profiles endpoint
//  Shows which students have active restrictions
//

import Foundation

/// A student's current restriction profile from the teacher API
/// If only `studentId` is present, the student has no active restrictions (unlocked)
/// If additional fields are present (appWhitelist, restrictions, etc.), the student has active restrictions (locked)
struct StudentRestrictionProfile: Codable, Identifiable {
    let studentId: Int
    let appWhitelist: String?
    let restrictions: StudentRestrictions?
    let startDate: String?
    let endDate: String?
    let genresBlacklist: [String]?
    let attention: AttentionInfo?
    let materials: MaterialsInfo?
    
    var id: Int { studentId }
    
    /// Returns true if the student has any active restrictions
    var hasActiveRestrictions: Bool {
        appWhitelist != nil ||
        restrictions != nil ||
        startDate != nil ||
        genresBlacklist != nil ||
        attention != nil ||
        materials != nil
    }
}

/// Specific feature restrictions applied to a student
struct StudentRestrictions: Codable {
    let allowAirDrop: Bool?
    let allowGamecenter: Bool?
    let allowChat: Bool?
}

/// Attention mode info
struct AttentionInfo: Codable {
    let endDate: String?
    let message: String?
    let startDate: String?
}

/// Materials/Safari restrictions
struct MaterialsInfo: Codable {
    let lockInSafari: Bool?
    let weblock: Bool?
    let sites: [SiteInfo]?
}

/// Individual site info for materials
struct SiteInfo: Codable {
    let title: String?
    let url: String?
}

/// Response type alias for the profiles array
typealias TeacherProfilesResponse = [StudentRestrictionProfile]

