//
//  PlanningSheet.swift
//  appi4Manager
//
//  Sheet for weekly schedule planning - accessible via toolbar calendar button.
//  Allows teachers to set up student app profiles for specific days of the week.
//

import SwiftUI

/// Sheet view for weekly schedule planning.
/// Teachers can select a day of the week and configure student profiles.
struct PlanningSheet: View {
    
    // MARK: - Properties
    
    let students: [Student]
    let devices: [TheDevice]
    let locationId: Int
    let dataProvider: StudentAppProfileDataProvider
    let bulkSetupDataProvider: StudentAppProfileDataProvider
    let onDismiss: () -> Void
    
    // MARK: - State
    
    /// Selected day for planning
    @State private var selectedDay: DayOfWeek = DayOfWeek.current()
    
    /// Selected timeslot for planning
    @State private var selectedTimeslot: TimeOfDay = .am
    
    /// Controls bulk setup sheet visibility
    @State private var showBulkSetup = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Day picker
                dayPicker
                
                // Timeslot picker
                timeslotPicker
                
                // Students grid
                studentsGrid
            }
            .background(Color(.systemGray6))
            .navigationTitle("Weekly Planning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showBulkSetup = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Bulk Setup")
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .sheet(isPresented: $showBulkSetup) {
            BulkProfileSetupView(
                students: students,
                devices: devices,
                dataProvider: bulkSetupDataProvider,
                onProfilesUpdated: {
                    // Refresh the main dataProvider so views show updated data
                    Task {
                        await dataProvider.loadProfiles(for: students.map { $0.id })
                    }
                }
            )
        }
    }
    
    // MARK: - Day Picker
    
    private var dayPicker: some View {
        VStack(spacing: 8) {
            Text("Select Day")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Day", selection: $selectedDay) {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    Text(day.shortName).tag(day)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Timeslot Picker
    
    private var timeslotPicker: some View {
        VStack(spacing: 4) {
            Picker("Timeslot", selection: $selectedTimeslot) {
                Text("A.M.").tag(TimeOfDay.am)
                Text("P.M.").tag(TimeOfDay.pm)
                Text("After School").tag(TimeOfDay.home)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            
            Text(TimeslotSettings.timeRangeString(for: selectedTimeslot))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Students Grid
    
    private var studentsGrid: some View {
        Group {
            if students.isEmpty {
                ContentUnavailableView(
                    "No Students",
                    systemImage: "person.3.fill",
                    description: Text("No students found in this class.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 16)
                    ], spacing: 16) {
                        ForEach(students, id: \.id) { student in
                            StudentProfileCard(
                                student: student,
                                timeslot: selectedTimeslot,
                                dayString: selectedDay.asAString,
                                dataProvider: dataProvider,
                                classDevices: devices,
                                dashboardMode: .planning,
                                locationId: locationId,
                                activeSession: nil  // Planning mode doesn't use real-time sessions
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - DayOfWeek Extension

extension DayOfWeek {
    /// Short display name for the day picker
    var shortName: String {
        switch self {
        case .sunday: return "Su"
        case .monday: return "Mo"
        case .tuesday: return "Tu"
        case .wednesday: return "We"
        case .thursday: return "Th"
        case .friday: return "Fr"
        case .saturday: return "Sa"
        }
    }
}
