//
//  StudentAppProfileDataProvider.swift
//  appi4Manager
//
//  Real data provider for student app profiles in the Teacher Dashboard
//  Fetches data from Firebase and caches it for efficient timeslot switching
//

import SwiftUI

/// Provides real app profile data for students from Firebase
@Observable
class StudentAppProfileDataProvider {
    
    // MARK: - Published State
    
    /// Loading state for the spinner
    var isLoading = false
    
    /// Error message if loading fails
    var errorMessage: String?
    
    // MARK: - Cached Data
    
    /// Cached student profiles keyed by student ID
    private var profileCache: [Int: StudentAppProfilex] = [:]
    
    /// Cached app metadata keyed by app ID
    private var appCache: [Int: Appx] = [:]
    
    /// Set of student IDs that have no profile in Firestore
    private var studentsWithNoProfile: Set<Int> = []
    
    // MARK: - Load Profiles
    
    /// Batch load profiles for a list of student IDs
    /// - Parameter studentIds: Array of student IDs to load profiles for
    @MainActor
    func loadProfiles(for studentIds: [Int]) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all profiles from Firestore
            let allProfiles = await StudentAppProfileManager.loadProfilesx()
            
            // Cache the profiles we need
            for profile in allProfiles {
                profileCache[profile.id] = profile
            }
            
            // Identify students without profiles
            for studentId in studentIds {
                if profileCache[studentId] == nil {
                    studentsWithNoProfile.insert(studentId)
                }
            }
            
            #if DEBUG
            print("📱 Loaded \(profileCache.count) student profiles from Firebase")
            print("📱 Students without profiles: \(studentsWithNoProfile.count)")
            #endif
            
        } catch {
            errorMessage = "Failed to load profiles: \(error.localizedDescription)"
            #if DEBUG
            print("❌ Error loading profiles: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - Get Session Data
    
    /// Gets the session for a student at a specific day and timeslot
    /// - Parameters:
    ///   - studentId: The student's ID
    ///   - day: The day string (e.g., "Mon", "Tues")
    ///   - timeslot: The time of day (am, pm, home)
    /// - Returns: The Session if available, nil if student has no profile
    func getSession(for studentId: Int, day: String, timeslot: TimeOfDay) -> Session? {
        guard let profile = profileCache[studentId],
              let dailySessions = profile.sessions[day] else {
            return nil
        }
        
        switch timeslot {
        case .am:
            return dailySessions.amSession
        case .pm:
            return dailySessions.pmSession
        case .home:
            return dailySessions.homeSession
        }
    }
    
    /// Checks if a student has a profile in Firestore
    /// - Parameter studentId: The student's ID
    /// - Returns: true if the student has a profile, false otherwise
    func hasProfile(for studentId: Int) -> Bool {
        return profileCache[studentId] != nil
    }
    
    // MARK: - Get App Metadata
    
    /// Gets app info by ID, fetching from API if not cached
    /// - Parameter appId: The app ID to look up
    /// - Returns: The Appx if found, nil otherwise
    func getAppInfo(byId appId: Int) async -> Appx? {
        // Check cache first
        if let cachedApp = appCache[appId] {
            return cachedApp
        }
        
        // Fetch from API
        do {
            let app: Appx = try await ApiManager.shared.getData(from: .getanApp(appId: appId))
            appCache[appId] = app
            return app
        } catch {
            #if DEBUG
            print("⚠️ Failed to fetch app info for ID \(appId): \(error)")
            #endif
            return nil
        }
    }
    
    /// Gets multiple apps by their IDs (uses cache when available)
    /// - Parameter appIds: Array of app IDs
    /// - Returns: Array of Appx objects for found apps
    func getApps(byIds appIds: [Int]) async -> [Appx] {
        var apps: [Appx] = []
        for appId in appIds {
            if let app = await getAppInfo(byId: appId) {
                apps.append(app)
            }
        }
        return apps
    }
    
    // MARK: - Helper Methods
    
    /// Determines the current timeslot based on the current time
    /// - Returns: The appropriate TimeOfDay based on current hour
    static func currentTimeslot() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 9 && hour < 12 {
            return .am
        } else if hour >= 12 && hour < 17 {
            return .pm
        } else {
            return .home
        }
    }
    
    /// Gets the current day abbreviation string
    /// - Returns: Day abbreviation like "Mon", "Tues", etc.
    static func currentDayString() -> String {
        let dayNumber = Calendar.current.component(.weekday, from: Date())
        guard let day = DayOfWeek(rawValue: dayNumber) else {
            return "Mon"
        }
        return day.asAString
    }
}
