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
    
    // Session status fields (written by CaptureFBNotifications)
    var status: String?        // "active" or "completed"
    var creationDT: Date?      // When session started (server timestamp)
    var completedAt: Date?     // When session ended (server timestamp)
    var sessionLengthMin: Int? // Duration in minutes
    var appBundleId: String?   // The app the student is locked to
    var loginCount: Int?       // Number of times student logged in this timeslot
    
    // MARK: - Computed Properties
    
    /// Whether this session is currently active
    var isActive: Bool {
        status == "active"
    }
    
    /// Whether this session has been completed
    var isCompleted: Bool {
        status == "completed"
    }
    
    /// Estimated end time based on creationDT + sessionLengthMin
    var estimatedEndTime: Date? {
        guard let creation = creationDT, let length = sessionLengthMin else { return nil }
        return creation.addingTimeInterval(TimeInterval(length * 60))
    }
    
    /// Formatted start time string (e.g., "9:15 AM")
    var startTimeString: String? {
        guard let creation = creationDT else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: creation)
    }
    
    /// Formatted end time string (actual if completed, estimated if active)
    var endTimeString: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        if isCompleted, let completed = completedAt {
            return formatter.string(from: completed)
        } else if let estimated = estimatedEndTime {
            return formatter.string(from: estimated)
        }
        return nil
    }
    
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
    
    /// Returns date string in YYYYMMDD format from a Date object
    static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
}


