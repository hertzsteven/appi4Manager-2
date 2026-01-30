//
//  ObservableSession.swift
//  appi4Manager
//
//  Represents a record from the Observables collection in Firestore.
//  Each document captures a single student login/app lock event.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

/// Represents a student's login event from the Observables collection.
/// Each time a student logs in and gets locked to an app, a new document is created.
/// This provides a complete history of all student app usage for reporting.
struct ObservableSession: Codable, Identifiable {
    @DocumentID var id: String?
    
    // MARK: - Core Identification Fields
    
    /// Student identifier
    var studentID: Int
    
    /// Company/school ID
    var companyId: Int
    
    /// Location identifier
    var locationID: Int
    
    /// Device UUID where the session occurred
    var deviceUUID: String
    
    /// Student's display name
    var name: String
    
    // MARK: - Session Fields
    
    /// When the login request was created
    var creationDT: Date?
    
    /// Bundle ID of the app the student was locked into
    var appBundleId: String?
    
    /// Duration of the session in minutes
    var sessionLengthMin: Int?
    
    /// Time of day: "morning", "afternoon", or "evening"
    var timeslot: String?
    
    /// Date in YYYYMMDD format
    var date: String?
    
    /// Status message (e.g., "mssg: success - session completed")
    var mssg: String?
    
    /// Whether this record has been processed
    var processed: Bool?
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case studentID
        case companyId
        case locationID
        case deviceUUID
        case name
        case creationDT
        case appBundleId
        case sessionLengthMin
        case timeslot
        case date
        case mssg
        case processed
    }
    
    // MARK: - Computed Properties
    
    /// Whether this session was completed successfully
    var isCompleted: Bool {
        mssg?.localizedStandardContains("success") ?? false
    }
    
    /// Display-friendly timeslot name
    var timeslotDisplayName: String {
        switch timeslot {
        case "morning": return "Morning"
        case "afternoon": return "Afternoon"
        case "evening": return "Evening"
        default: return timeslot ?? "Unknown"
        }
    }
    
    /// Parses the date string (YYYYMMDD) to a Date object
    var parsedDate: Date? {
        guard let dateString = date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date()) == dateString ? Date() : formatter.date(from: dateString)
    }
    
    /// Formatted date string for display (e.g., "Jan 29, 2026")
    var formattedDate: String {
        guard let dateString = date else { return "Unknown Date" }
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyyMMdd"
        
        guard let parsedDate = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        return outputFormatter.string(from: parsedDate)
    }
    
    /// Formatted time string from creationDT (e.g., "9:15 AM")
    var formattedTime: String? {
        guard let creation = creationDT else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: creation)
    }
    
    /// Session duration as a formatted string (e.g., "20 min")
    var durationString: String {
        guard let minutes = sessionLengthMin else { return "-- min" }
        return "\(minutes) min"
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
