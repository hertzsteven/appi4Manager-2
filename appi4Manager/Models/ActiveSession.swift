//
//  ActiveSession.swift
//  appi4Manager
//
//  Represents an active student login session in Firestore
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

/// Represents a student's active login session in Firestore.
/// Document ID format: {companyId}_{locationId}_{studentId}_{date}_{timeslot}
/// Example: 2001128_1_9_20241216_afternoon
struct ActiveSession: Codable, Identifiable {
    @DocumentID var id: String?
    var deviceUUID: String
    var studentId: Int
    var companyId: Int
    var locationId: Int
    var date: String           // YYYYMMDD format
    var timeslot: String       // "morning", "afternoon", "evening"
    var allowRelogin: Bool
    
    /// Generates the document ID for an active session
    /// - Parameters:
    ///   - companyId: The company/school ID
    ///   - locationId: The location ID
    ///   - studentId: The student ID
    ///   - date: Date in YYYYMMDD format
    ///   - timeslot: The timeslot string (morning/afternoon/evening)
    /// - Returns: The composite document ID
    static func makeDocumentId(companyId: Int, locationId: Int, studentId: Int, date: String, timeslot: String) -> String {
        return "\(companyId)_\(locationId)_\(studentId)_\(date)_\(timeslot)"
    }
    
    /// Converts TimeOfDay enum to the timeslot string used in Firestore
    static func timeslotString(from timeOfDay: TimeOfDay) -> String {
        switch timeOfDay {
        case .am:
            return "morning"
        case .pm:
            return "afternoon"
        case .home:
            return "evening"
        case .blocked:
            return "blocked"
        }
    }
    
    /// Returns today's date in YYYYMMDD format
    static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }
}

