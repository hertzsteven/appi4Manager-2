//
//  StudentActivityReportViewModel.swift
//  appi4Manager
//
//  ViewModel for the Student Activity Report feature.
//  Manages fetching and filtering student activity data from the Observables collection.
//

import Foundation
import SwiftUI

/// Date filter presets for the activity report
enum ActivityDateFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case all = "All Time"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    /// Returns the start date for this filter preset
    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now)
        case .all:
            return nil
        case .custom:
            return nil // Custom uses the customStartDate
        }
    }
    
    /// Returns the end date for this filter preset (always now for presets)
    var endDate: Date? {
        switch self {
        case .all:
            return nil
        default:
            return Date()
        }
    }
}

/// Summary of a student's activity for display in the report list
struct StudentActivitySummary: Identifiable {
    let student: Student
    let totalSessions: Int
    let recentApps: [String] // Bundle IDs of recently used apps
    let latestSessionDate: Date?
    let sessions: [ObservableSession]
    
    var id: Int { student.id }
}

/// ViewModel for managing student activity report data
@MainActor
@Observable
class StudentActivityReportViewModel {
    
    // MARK: - Published State
    
    /// All fetched activity sessions
    var allSessions: [ObservableSession] = []
    
    /// Activity grouped by student
    var studentSummaries: [StudentActivitySummary] = []
    
    /// Selected date filter preset
    var selectedFilter: ActivityDateFilter = .today
    
    /// Custom date range (when filter is .custom)
    var customStartDate: Date = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
    var customEndDate: Date = Date()
    
    /// Loading state
    var isLoading = false
    
    /// Error message if loading fails
    var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let firestoreManager = FirestoreManager()
    
    // MARK: - Computed Properties
    
    /// Effective start date based on current filter
    var effectiveStartDate: Date? {
        if selectedFilter == .custom {
            return customStartDate
        }
        return selectedFilter.startDate
    }
    
    /// Effective end date based on current filter
    var effectiveEndDate: Date? {
        if selectedFilter == .custom {
            return customEndDate
        }
        return selectedFilter.endDate
    }
    
    /// Total session count across all students
    var totalSessionCount: Int {
        allSessions.count
    }
    
    // MARK: - Methods
    
    /// Loads activity data for a single student
    /// - Parameters:
    ///   - studentId: The student ID to fetch activity for
    ///   - companyId: Optional company ID
    func loadActivityForStudent(studentId: Int, companyId: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        
        let sessions = await firestoreManager.fetchStudentActivity(
            studentId: studentId,
            companyId: companyId,
            startDate: effectiveStartDate,
            endDate: effectiveEndDate
        )
        
        allSessions = sessions
        isLoading = false
    }
    
    /// Loads activity data for multiple students and creates summaries
    /// - Parameters:
    ///   - students: Array of Student objects
    ///   - companyId: Optional company ID
    func loadActivityForStudents(_ students: [Student], companyId: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        
        let studentIds = students.map { $0.id }
        let activityByStudent = await firestoreManager.fetchActivityForStudents(
            studentIds: studentIds,
            companyId: companyId,
            startDate: effectiveStartDate,
            endDate: effectiveEndDate
        )
        
        // Build summaries for each student
        var summaries: [StudentActivitySummary] = []
        var allFetchedSessions: [ObservableSession] = []
        
        for student in students {
            let sessions = activityByStudent[student.id] ?? []
            allFetchedSessions.append(contentsOf: sessions)
            
            // Get unique recent app bundle IDs (up to 3)
            let recentApps = Array(Set(sessions.compactMap { $0.appBundleId })).prefix(3)
            
            let summary = StudentActivitySummary(
                student: student,
                totalSessions: sessions.count,
                recentApps: Array(recentApps),
                latestSessionDate: sessions.first?.creationDT,
                sessions: sessions
            )
            summaries.append(summary)
        }
        
        // Sort by total sessions (most active first), then by name
        summaries.sort { first, second in
            if first.totalSessions != second.totalSessions {
                return first.totalSessions > second.totalSessions
            }
            return first.student.lastName < second.student.lastName
        }
        
        studentSummaries = summaries
        allSessions = allFetchedSessions
        isLoading = false
    }
    
    /// Loads activity for all students at a location
    /// - Parameters:
    ///   - locationId: The location ID
    ///   - companyId: Optional company ID
    func loadActivityForLocation(locationId: Int, companyId: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        
        let sessions = await firestoreManager.fetchAllStudentActivity(
            companyId: companyId,
            locationId: locationId,
            startDate: effectiveStartDate,
            endDate: effectiveEndDate
        )
        
        allSessions = sessions
        isLoading = false
    }
    
    /// Filters sessions for a specific student
    /// - Parameter studentId: The student ID to filter by
    /// - Returns: Array of sessions for that student
    func sessions(for studentId: Int) -> [ObservableSession] {
        allSessions.filter { $0.studentID == studentId }
    }
    
    /// Groups sessions by date for display
    /// - Parameter sessions: Sessions to group
    /// - Returns: Dictionary with date string keys and session arrays
    func sessionsByDate(_ sessions: [ObservableSession]) -> [String: [ObservableSession]] {
        Dictionary(grouping: sessions) { session in
            session.date ?? "Unknown"
        }
    }
    
    /// Returns sorted date keys for grouped sessions (newest first)
    /// - Parameter grouped: Grouped sessions dictionary
    /// - Returns: Sorted array of date strings
    func sortedDateKeys(_ grouped: [String: [ObservableSession]]) -> [String] {
        grouped.keys.sorted { $0 > $1 }
    }
    
    /// Formats a date string (YYYYMMDD) for section headers
    /// - Parameter dateString: Date string in YYYYMMDD format
    /// - Returns: Formatted date string (e.g., "January 29, 2026")
    func formatDateHeader(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyyMMdd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        return outputFormatter.string(from: date)
    }
    
    /// Reloads data with the current filter settings
    /// - Parameters:
    ///   - students: Students to reload for (summary view)
    ///   - companyId: Optional company ID
    func reloadWithFilter(_ students: [Student], companyId: Int? = nil) async {
        await loadActivityForStudents(students, companyId: companyId)
    }
    
    /// Reloads data for a single student with the current filter settings
    /// - Parameters:
    ///   - studentId: Student ID to reload for
    ///   - companyId: Optional company ID
    func reloadWithFilter(studentId: Int, companyId: Int? = nil) async {
        await loadActivityForStudent(studentId: studentId, companyId: companyId)
    }
}
