//
//  ActiveSessionListener.swift
//  appi4Manager
//
//  Real-time Firestore listener for ActiveSessions collection.
//  Provides session status for students in a given location/date/timeslot.
//

import Foundation
import FirebaseFirestore
import Observation

/// Listens to ActiveSessions collection in Firestore and provides real-time session data.
/// Uses @Observable for SwiftUI integration (per user preference).
@Observable
@MainActor
final class ActiveSessionListener {
    
    // MARK: - Properties
    
    /// Dictionary of sessions keyed by studentId for O(1) lookup
    private(set) var sessions: [Int: ActiveSession] = [:]
    
    /// Whether the listener is currently active
    private(set) var isListening = false
    
    /// Error message if listener fails
    private(set) var error: String?
    
    /// Current listener registration (used to stop listening)
    private var listenerRegistration: ListenerRegistration?
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Collection name in Firestore
    private static let collectionName = "ActiveSessions"
    
    // MARK: - Current Query Parameters
    
    private var currentCompanyId: Int?
    private var currentLocationId: Int?
    private var currentDate: String?
    private var currentTimeslot: String?
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        // Note: deinit won't be called on MainActor, but we set up cleanup in stopListening
    }
    
    // MARK: - Public Methods
    
    /// Get session for a specific student (O(1) lookup)
    /// - Parameter studentId: The student's ID
    /// - Returns: ActiveSession if one exists for this student, nil otherwise
    func session(for studentId: Int) -> ActiveSession? {
        sessions[studentId]
    }
    
    /// Start listening for sessions matching the given criteria.
    /// Automatically stops any existing listener before starting a new one.
    /// - Parameters:
    ///   - companyId: The company/school ID
    ///   - locationId: The location ID
    ///   - date: Date in YYYYMMDD format
    ///   - timeslot: Timeslot string (morning/afternoon/evening)
    func startListening(companyId: Int, locationId: Int, date: String, timeslot: String) {
        // Check if we're already listening with the same parameters
        if isListening,
           currentCompanyId == companyId,
           currentLocationId == locationId,
           currentDate == date,
           currentTimeslot == timeslot {
            // Already listening with same parameters, no need to restart
            return
        }
        
        // Stop existing listener
        stopListening()
        
        // Store current parameters
        currentCompanyId = companyId
        currentLocationId = locationId
        currentDate = date
        currentTimeslot = timeslot
        
        print("📡 ActiveSessionListener: Starting listener")
        print("   Company: \(companyId), Location: \(locationId)")
        print("   Date: \(date), Timeslot: \(timeslot)")
        
        // Build query for sessions matching criteria
        let query = db.collection(Self.collectionName)
            .whereField("companyId", isEqualTo: companyId)
            .whereField("locationId", isEqualTo: locationId)
            .whereField("date", isEqualTo: date)
            .whereField("timeslot", isEqualTo: timeslot)
        
        // Add snapshot listener
        listenerRegistration = query.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                self?.handleSnapshot(snapshot, error: error)
            }
        }
        
        isListening = true
        self.error = nil
    }
    
    /// Start listening for a specific date (convenience method)
    /// - Parameters:
    ///   - companyId: The company/school ID
    ///   - locationId: The location ID
    ///   - date: The date to query
    ///   - timeOfDay: TimeOfDay enum value
    func startListening(companyId: Int, locationId: Int, date: Date, timeOfDay: TimeOfDay) {
        let dateString = ActiveSession.dateString(from: date)
        let timeslotString = ActiveSession.timeslotString(from: timeOfDay)
        startListening(companyId: companyId, locationId: locationId, date: dateString, timeslot: timeslotString)
    }
    
    /// Stop listening and clean up
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        isListening = false
        sessions = [:]
        
        currentCompanyId = nil
        currentLocationId = nil
        currentDate = nil
        currentTimeslot = nil
        
        print("📡 ActiveSessionListener: Stopped listening")
    }
    
    // MARK: - Private Methods
    
    /// Handle Firestore snapshot updates
    private func handleSnapshot(_ snapshot: QuerySnapshot?, error: Error?) {
        if let error = error {
            print("❌ ActiveSessionListener: Error - \(error.localizedDescription)")
            self.error = error.localizedDescription
            return
        }
        
        guard let documents = snapshot?.documents else {
            print("⚠️ ActiveSessionListener: No documents in snapshot")
            sessions = [:]
            return
        }
        
        print("📡 ActiveSessionListener: Received \(documents.count) session(s)")
        
        // Parse documents into sessions dictionary
        var newSessions: [Int: ActiveSession] = [:]
        
        for document in documents {
            do {
                let session = try document.data(as: ActiveSession.self)
                newSessions[session.studentId] = session
                
                #if DEBUG
                print("   └─ Student \(session.studentId): \(session.status ?? "unknown") | App: \(session.appBundleId ?? "none")")
                #endif
            } catch {
                print("⚠️ ActiveSessionListener: Failed to decode document \(document.documentID): \(error)")
            }
        }
        
        sessions = newSessions
        self.error = nil
    }
}

// MARK: - Preview/Testing Support

#if DEBUG
extension ActiveSessionListener {
    /// Create a listener with mock data for previews
    static func preview(with mockSessions: [ActiveSession]) -> ActiveSessionListener {
        let listener = ActiveSessionListener()
        for session in mockSessions {
            listener.sessions[session.studentId] = session
        }
        return listener
    }
}
#endif


