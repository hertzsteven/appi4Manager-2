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
    
    /// Selected app bundle ID (single selection per timeslot)
    var selectedBundleId: String?
    
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
        selectedBundleId != nil
    }
    
    /// Human-readable summary showing actual student names, days, and timeslots.
    ///
    /// Displays up to 3 student first names, abbreviated day names, timeslot labels,
    /// and the selected app count so teachers see exactly what they're about to apply.
    var summaryText: String {
        let studentCount = selectedStudentIds.count
        
        if studentCount == 0 {
            return "Select students to configure"
        }
        
        var parts: [String] = []
        
        // Student names — show up to 3, then "+N more"
        let selectedNames = allStudents
            .filter { selectedStudentIds.contains($0.id) }
            .map(\.firstName)
        if selectedNames.count <= 3 {
            parts.append(selectedNames.joined(separator: ", "))
        } else {
            let first3 = selectedNames.prefix(3).joined(separator: ", ")
            parts.append("\(first3) +\(selectedNames.count - 3) more")
        }
        
        // Day abbreviations
        if !selectedDays.isEmpty {
            let dayOrder: [DayOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday]
            let sorted = dayOrder.filter { selectedDays.contains($0) }
            let abbreviations = sorted.map { day in
                switch day {
                case .monday: "Mon"
                case .tuesday: "Tue"
                case .wednesday: "Wed"
                case .thursday: "Thu"
                case .friday: "Fri"
                case .saturday: "Sat"
                case .sunday: "Sun"
                }
            }
            parts.append(abbreviations.joined(separator: ", "))
        }
        
        // Timeslot labels — sorted in natural display order
        if !selectedTimeslots.isEmpty {
            let timeslotOrder: [TimeOfDay] = [.am, .pm, .home, .blocked]
            let sorted = timeslotOrder.filter { selectedTimeslots.contains($0) }
            let labels = sorted.map(\.displayName)
            parts.append(labels.joined(separator: ", "))
        }
        
        // Duration
        parts.append("\(Int(sessionLength)) min")
        
        return parts.joined(separator: " · ")
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
    
    func selectAllTimeslots() {
        selectedTimeslots = Set(Self.allTimeslots)
    }
    
    func deselectAllTimeslots() {
        selectedTimeslots.removeAll()
    }
    
    var allTimeslotsSelected: Bool {
        Self.allTimeslots.allSatisfy { selectedTimeslots.contains($0) }
    }
    
    // MARK: - App Selection (Single)
    
    /// Selects a single app. Tapping the already-selected app deselects it.
    func toggleApp(_ bundleId: String) {
        if selectedBundleId == bundleId {
            selectedBundleId = nil
        } else {
            selectedBundleId = bundleId
        }
    }
    
    func isAppSelected(_ bundleId: String) -> Bool {
        selectedBundleId == bundleId
    }
    
    // MARK: - Apply Configuration
    
    /// Applies the selected configuration to all selected students, days, and timeslots
    /// - Parameter dataProvider: The data provider to use for saving to Firebase
    func applyConfiguration(using dataProvider: StudentAppProfileDataProvider) async {
        guard canApply else { return }
        
        isSaving = true
        saveError = nil
        
        guard let bundleId = selectedBundleId else { return }
        let appsList = [bundleId]
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
    
    /// Resets transient state after a successful save so the view can be reused inline.
    func resetAfterSave() {
        didSaveSuccessfully = false
        selectedBundleId = nil
        saveError = nil
    }
}

// MARK: - TimeOfDay Hashable Extension

extension TimeOfDay: Hashable {}
