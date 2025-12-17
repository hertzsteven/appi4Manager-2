//
//  WeeklyProfileView.swift
//  appi4Manager
//
//  Main week view component for viewing a student's entire weekly schedule.
//  Features a segmented control for day selection and collapsible disclosure groups.
//

import SwiftUI

// MARK: - WeeklyProfileView

/// A view for displaying and editing a student's weekly app profile schedule.
///
/// **Features:**
/// - Segmented control: Mon | Tue | Wed | Thu | Fri | All
/// - Single day view: Shows 3 timeslots (AM, PM, Home)
/// - All days view: Each day as a collapsible DisclosureGroup
/// - Inline session editing via TimeslotRowView
/// - Quick app reassignment via "Change" button
struct WeeklyProfileView: View {
    
    // MARK: - Properties
    
    let student: Student
    let dataProvider: StudentAppProfileDataProvider
    let deviceApps: [DeviceApp]
    
    /// Callback when user wants to edit apps for a specific day/timeslot
    var onEditApps: ((_ dayString: String, _ timeslot: TimeOfDay) -> Void)? = nil
    
    @State private var selectedMode: WeeklyViewMode = .monday
    @State private var expandedDays: Set<WeeklyViewMode> = []
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Segmented control for day selection
            daySegmentedControl
            
            // Content based on selected mode
            if selectedMode == .all {
                allDaysView
            } else {
                singleDayView
            }
        }
    }
    
    // MARK: - Day Segmented Control
    
    private var daySegmentedControl: some View {
        Picker("Day", selection: $selectedMode) {
            ForEach(WeeklyViewMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    // MARK: - Single Day View
    
    /// Shows the 3 timeslots for a single selected day
    private var singleDayView: some View {
        VStack(spacing: 12) {
            if let dayString = selectedMode.toDayString {
                ForEach([TimeOfDay.am, .pm, .home], id: \.self) { timeslot in
                    TimeslotRowView(
                        studentId: student.id,
                        timeslot: timeslot,
                        dayString: dayString,
                        dataProvider: dataProvider,
                        deviceApps: deviceApps
                    ) {
                        onEditApps?(dayString, timeslot)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - All Days View
    
    /// Shows all weekdays as collapsible disclosure groups
    private var allDaysView: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(WeeklyViewMode.weekdays) { day in
                    dayDisclosureGroup(for: day)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Day Disclosure Group
    
    /// A collapsible section for one day showing all 3 timeslots when expanded
    private func dayDisclosureGroup(for day: WeeklyViewMode) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedDays.contains(day) },
                set: { isExpanded in
                    if isExpanded {
                        expandedDays.insert(day)
                    } else {
                        expandedDays.remove(day)
                    }
                }
            )
        ) {
            // Expanded content: 3 timeslots
            if let dayString = day.toDayString {
                VStack(spacing: 8) {
                    ForEach([TimeOfDay.am, .pm, .home], id: \.self) { timeslot in
                        TimeslotRowView(
                            studentId: student.id,
                            timeslot: timeslot,
                            dayString: dayString,
                            dataProvider: dataProvider,
                            deviceApps: deviceApps
                        ) {
                            onEditApps?(dayString, timeslot)
                        }
                    }
                }
                .padding(.top, 8)
            }
        } label: {
            // Collapsed header: Day name + summary
            dayHeaderLabel(for: day)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .sensoryFeedback(.selection, trigger: expandedDays.contains(day))
    }
    
    // MARK: - Day Header Label
    
    /// Header shown for collapsed day: Day name + app count + configured status
    private func dayHeaderLabel(for day: WeeklyViewMode) -> some View {
        HStack {
            Text(dayFullName(for: day))
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Summary: app count and configured status
            let summary = daySummary(for: day)
            
            HStack(spacing: 8) {
                Label("\(summary.appCount) apps", systemImage: "app.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Image(systemName: summary.isConfigured ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                    .foregroundColor(summary.isConfigured ? .green : .secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func dayFullName(for day: WeeklyViewMode) -> String {
        switch day {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .all: return "All Days"
        }
    }
    
    /// Returns app count and configured status for a day
    private func daySummary(for day: WeeklyViewMode) -> (appCount: Int, isConfigured: Bool) {
        guard let dayString = day.toDayString else {
            return (0, false)
        }
        
        var totalApps = 0
        var configuredSlots = 0
        
        for timeslot in [TimeOfDay.am, .pm, .home] {
            if let session = dataProvider.getSession(for: student.id, day: dayString, timeslot: timeslot) {
                totalApps += session.apps.count
                if !session.apps.isEmpty {
                    configuredSlots += 1
                }
            }
        }
        
        // Consider "configured" if at least one timeslot has apps
        return (totalApps, configuredSlots > 0)
    }
}

// MARK: - Preview

#Preview {
    WeeklyProfileView(
        student: Student(
            id: 1,
            name: "John Smith",
            email: "john@test.com",
            username: "jsmith",
            firstName: "John",
            lastName: "Smith",
            photo: URL(string: "https://example.com/photo.jpg")!
        ),
        dataProvider: StudentAppProfileDataProvider(),
        deviceApps: []
    )
    .padding()
    .background(Color(.systemGray6))
}
