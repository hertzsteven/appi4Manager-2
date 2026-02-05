//
//  StudentProfileDocumentId.swift
//  appi4Manager
//
//  Helper for constructing composite document IDs for student profiles.
//  Format: {companyId}_{studentId}
//

import Foundation

/// Constructs composite document IDs for student profiles in Firestore
/// Format: {companyId}_{studentId}
enum StudentProfileDocumentId {
    
    /// Creates a composite document ID from explicit company and student IDs
    /// - Parameters:
    ///   - companyId: The company/school ID
    ///   - studentId: The student ID
    /// - Returns: A string in format "{companyId}_{studentId}"
    static func make(companyId: Int, studentId: Int) -> String {
        return "\(companyId)_\(studentId)"
    }
    
    /// Creates a composite document ID using the current company from APISchoolInfo
    /// - Parameter studentId: The student ID
    /// - Returns: A string in format "{currentCompanyId}_{studentId}"
    static func makeWithCurrentCompany(studentId: Int) -> String {
        return "\(APISchoolInfo.shared.companyId)_\(studentId)"
    }
}
