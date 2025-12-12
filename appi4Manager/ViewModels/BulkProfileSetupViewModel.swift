//
//  BulkProfileSetupViewModel.swift
//  appi4Manager
//
//  ViewModel for the Bulk Profile Setup feature
//  Handles state management and business logic for configuring multiple student profiles
//

import SwiftUI

/// ViewModel for bulk student profile configuration
@Observable
@MainActor
final class BulkProfileSetupViewModel {
    
    // MARK: - Selection State
    
    /// Selected student IDs
    var selectedStudentIds: Set<Int> = []
    
    /// Selected days of the week
    var selectedDays: Set<DayOfWeek> = []
    
    /// Selected timeslots
    var selectedTimeslots: Set<TimeOfDay> = []
    
    /// Selected app bundle IDs
    var selectedBundleIds: Set<String> = []
    
    /// Current filter category
    var selectedCategory: AppFilterCategory = .all
    
    /// Session duration in minutes (5-60)
    var sessionLength: Double = 30
    
    // MARK: - UI State
    
    /// Whether a save operation is in progress
    var isSaving = false
    
    /// Error message if save fails
    var saveError: String?
    
    /// Success state for dismissing sheet
    var didSaveSuccessfully = false
    
    // MARK: - Data Sources (set during initialization)
    
    /// All available students
    private(set) var allStudents: [Student] = []
    
    /// All available apps from devices
    private(set) var allApps: [DeviceApp] = []
    
    // MARK: - Initialization
    
    /// Initialize the ViewModel with students and device apps
    /// - Parameters:
    ///   - students: Array of students to display
    ///   - deviceApps: Array of apps from class devices
    func configure(students: [Student], deviceApps: [DeviceApp]) {
        self.allStudents = students
        self.allApps = deviceApps
    }
    
    // MARK: - Computed Properties
    
    /// Apps filtered by the selected category
    var filteredApps: [DeviceApp] {
        guard selectedCategory != .all else {
            return allApps
        }
        return allApps.filter { app in
            selectedCategory.matches(appName: app.displayName)
        }
    }
    
    /// Whether the Apply button should be enabled
    var canApply: Bool {
        !selectedStudentIds.isEmpty &&
        !selectedDays.isEmpty &&
        !selectedTimeslots.isEmpty &&
        !selectedBundleIds.isEmpty
    }
    
    /// Human-readable summary of the current selection
    var summaryText: String {
        let studentCount = selectedStudentIds.count
        let dayCount = selectedDays.count
        let timeslotCount = selectedTimeslots.count
        let appCount = selectedBundleIds.count
        
        if studentCount == 0 {
            return "Select students to configure"
        }
        
        var parts: [String] = []
        parts.append("\(studentCount) student\(studentCount == 1 ? "" : "s")")
        
        if dayCount > 0 {
            parts.append("\(dayCount) day\(dayCount == 1 ? "" : "s")")
        }
        
        if timeslotCount > 0 {
            parts.append("\(timeslotCount) timeslot\(timeslotCount == 1 ? "" : "s")")
        }
        
        if appCount > 0 {
            parts.append("\(appCount) app\(appCount == 1 ? "" : "s")")
        }
        
        return parts.joined(separator: " • ")
    }
    
    // MARK: - Student Selection
    
    func toggleStudent(_ studentId: Int) {
        if selectedStudentIds.contains(studentId) {
            selectedStudentIds.remove(studentId)
        } else {
            selectedStudentIds.insert(studentId)
        }
    }
    
    func isStudentSelected(_ studentId: Int) -> Bool {
        selectedStudentIds.contains(studentId)
    }
    
    func selectAllStudents() {
        selectedStudentIds = Set(allStudents.map { $0.id })
    }
    
    func deselectAllStudents() {
        selectedStudentIds.removeAll()
    }
    
    var allStudentsSelected: Bool {
        selectedStudentIds.count == allStudents.count && !allStudents.isEmpty
    }
    
    // MARK: - Day Selection
    
    /// Weekdays only (Mon-Fri)
    static let weekdays: [DayOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday]
    
    func toggleDay(_ day: DayOfWeek) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    func isDaySelected(_ day: DayOfWeek) -> Bool {
        selectedDays.contains(day)
    }
    
    func selectAllWeekdays() {
        selectedDays = Set(Self.weekdays)
    }
    
    func deselectAllDays() {
        selectedDays.removeAll()
    }
    
    var allWeekdaysSelected: Bool {
        Self.weekdays.allSatisfy { selectedDays.contains($0) }
    }
    
    // MARK: - Timeslot Selection
    
    static let allTimeslots: [TimeOfDay] = [.am, .pm, .home]
    
    func toggleTimeslot(_ timeslot: TimeOfDay) {
        if selectedTimeslots.contains(timeslot) {
            selectedTimeslots.remove(timeslot)
        } else {
            selectedTimeslots.insert(timeslot)
        }
    }
    
    func isTimeslotSelected(_ timeslot: TimeOfDay) -> Bool {
        selectedTimeslots.contains(timeslot)
    }
    
    // MARK: - App Selection
    
    func toggleApp(_ bundleId: String) {
        if selectedBundleIds.contains(bundleId) {
            selectedBundleIds.remove(bundleId)
        } else {
            selectedBundleIds.insert(bundleId)
        }
    }
    
    func isAppSelected(_ bundleId: String) -> Bool {
        selectedBundleIds.contains(bundleId)
    }
    
    // MARK: - Apply Configuration
    
    /// Applies the selected configuration to all selected students, days, and timeslots
    /// - Parameter dataProvider: The data provider to use for saving to Firebase
    func applyConfiguration(using dataProvider: StudentAppProfileDataProvider) async {
        guard canApply else { return }
        
        isSaving = true
        saveError = nil
        
        let appsList = Array(selectedBundleIds)
        var successCount = 0
        var totalOperations = selectedStudentIds.count * selectedDays.count * selectedTimeslots.count
        
        do {
            for studentId in selectedStudentIds {
                for day in selectedDays {
                    for timeslot in selectedTimeslots {
                        try await dataProvider.updateAndSaveSession(
                            for: studentId,
                            day: day.asAString,
                            timeslot: timeslot,
                            apps: appsList,
                            sessionLength: sessionLength
                        )
                        successCount += 1
                    }
                }
            }
            
            #if DEBUG
            print("✅ Successfully applied profile to \(successCount)/\(totalOperations) combinations")
            #endif
            
            didSaveSuccessfully = true
            
        } catch {
            saveError = "Failed to save: \(error.localizedDescription)"
            #if DEBUG
            print("❌ Error applying bulk profile: \(error)")
            #endif
        }
        
        isSaving = false
    }
}

// MARK: - TimeOfDay Hashable Extension

extension TimeOfDay: Hashable {}
