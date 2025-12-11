//
//  MockStudentAppProfileProvider.swift
//  appi4Manager
//
//  Mock data provider for student app profiles in the Teacher Dashboard
//

import Foundation

/// Provides mock app profile data for students in the Teacher Dashboard
struct MockStudentAppProfileProvider {
    
    // MARK: - Mock App Data
    
    /// Represents a mock app with display info
    struct MockApp: Identifiable {
        let id: Int
        let name: String
        let iconSystemName: String  // SF Symbol name for mock icons
    }
    
    /// Sample apps that can be assigned to students
    static let sampleApps: [MockApp] = [
        MockApp(id: 11, name: "Elmo Loves ABCs", iconSystemName: "textformat.abc"),
        MockApp(id: 27, name: "BusyShapes", iconSystemName: "square.on.circle"),
        MockApp(id: 34, name: "Reading Eggs", iconSystemName: "book.fill"),
        MockApp(id: 45, name: "Math Kids", iconSystemName: "function"),
        MockApp(id: 56, name: "Khan Academy Kids", iconSystemName: "graduationcap.fill"),
        MockApp(id: 67, name: "PBS Kids Games", iconSystemName: "gamecontroller.fill"),
        MockApp(id: 78, name: "Starfall Learn", iconSystemName: "star.fill"),
        MockApp(id: 89, name: "Homer Reading", iconSystemName: "text.book.closed.fill")
    ]
    
    // MARK: - Mock Profile Generator
    
    /// Generates a mock profile for a student
    /// - Parameter studentId: The student's ID
    /// - Returns: A mock StudentAppProfilex with randomized but consistent data
    static func getMockProfile(for studentId: Int) -> StudentAppProfilex {
        // Use student ID as seed for consistent mock data
        let seed = studentId
        
        // Generate sessions for each day
        var sessions: [String: DailySessions] = [:]
        let daysOfWeek = ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"]
        
        for day in daysOfWeek {
            sessions[day] = generateDailySessions(seed: seed, dayOffset: daysOfWeek.firstIndex(of: day) ?? 0)
        }
        
        return StudentAppProfilex(id: studentId, locationId: 0, sessions: sessions)
    }
    
    /// Generates daily sessions with mock data
    private static func generateDailySessions(seed: Int, dayOffset: Int) -> DailySessions {
        let amApps = generateAppIds(seed: seed + dayOffset * 100, count: (seed + dayOffset) % 3 + 1)
        let pmApps = generateAppIds(seed: seed + dayOffset * 200, count: (seed + dayOffset + 1) % 4 + 1)
        let homeApps = generateAppIds(seed: seed + dayOffset * 300, count: (seed + dayOffset + 2) % 2 + 1)
        
        let amLength = Double(((seed + dayOffset) % 12 + 1) * 5)  // 5-60 in steps of 5
        let pmLength = Double(((seed + dayOffset + 3) % 12 + 1) * 5)
        let homeLength = Double(((seed + dayOffset + 7) % 12 + 1) * 5)
        
        return DailySessions(
            amSession: Session(apps: amApps, sessionLength: amLength, oneAppLock: amApps.count == 1),
            pmSession: Session(apps: pmApps, sessionLength: pmLength, oneAppLock: pmApps.count == 1),
            homeSession: Session(apps: homeApps, sessionLength: homeLength, oneAppLock: homeApps.count == 1)
        )
    }
    
    /// Generates an array of app IDs based on seed
    private static func generateAppIds(seed: Int, count: Int) -> [Int] {
        var result: [Int] = []
        for i in 0..<count {
            let index = (seed + i * 13) % sampleApps.count
            result.append(sampleApps[index].id)
        }
        return result
    }
    
    /// Gets the mock app info for a given app ID
    /// - Parameter appId: The app ID to look up
    /// - Returns: The MockApp if found, nil otherwise
    static func getApp(byId appId: Int) -> MockApp? {
        sampleApps.first { $0.id == appId }
    }
    
    /// Gets mock apps for an array of app IDs
    /// - Parameter appIds: Array of app IDs
    /// - Returns: Array of MockApp objects
    static func getApps(byIds appIds: [Int]) -> [MockApp] {
        appIds.compactMap { getApp(byId: $0) }
    }
    
    // MARK: - Current Timeslot Helper
    
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
    
    /// Gets the session for a student at a specific day and timeslot
    /// - Parameters:
    ///   - studentId: The student's ID
    ///   - day: The day string (e.g., "Mon")
    ///   - timeslot: The time of day
    /// - Returns: The Session for that day/timeslot
    static func getSession(for studentId: Int, day: String, timeslot: TimeOfDay) -> Session {
        let profile = getMockProfile(for: studentId)
        guard let dailySessions = profile.sessions[day] else {
            return Session(apps: [], sessionLength: 0, oneAppLock: false)
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
}
