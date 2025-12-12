//
//  BulkProfileSetupView.swift
//  appi4Manager
//
//  Sheet for bulk configuration of student app profiles.
//  Allows teachers to set app permissions for multiple students at once,
//  across multiple days and timeslots.
//

import SwiftUI

// MARK: - BulkProfileSetupView

/// Main sheet for bulk configuration of student app profiles.
///
/// **Workflow:**
/// 1. Select one or more students from horizontal scroll
/// 2. Select which days of the week to apply to
/// 3. Select which timeslots (AM, PM, Home)
/// 4. Set session duration (5-60 minutes)
/// 5. Filter and select apps from the list
/// 6. Tap "Apply" to save profiles to Firebase
///
/// **Sections:**
/// - Student Selection: Horizontal avatar picker
/// - Day Selection: Mon-Fri pills with select all
/// - Timeslot Selection: AM/PM/Home pills
/// - Session Duration: Slider from 5-60 minutes  
/// - Category Filter: Filter apps by type
/// - App List: Scrollable list of selectable apps
struct BulkProfileSetupView: View {
    
    // MARK: - Properties
    
    let students: [Student]
    let devices: [TheDevice]
    let dataProvider: StudentAppProfileDataProvider
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BulkProfileSetupViewModel()
    
    /// All device apps from the first device in the class
    private var deviceApps: [DeviceApp] {
        devices.first?.apps ?? []
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Student Selection Section
                    studentSelectionSection
                    
                    // Day Selection Section
                    daySelectionSection
                    
                    // Timeslot Selection Section
                    timeslotSelectionSection
                    
                    // Session Duration Section
                    sessionDurationSection
                    
                    // Category Filter Section
                    categoryFilterSection
                    
                    // App List Section
                    appListSection
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .navigationTitle("Profile Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                applyButton
            }
            .overlay {
                if viewModel.isSaving {
                    savingOverlay
                }
            }
        }
        .onAppear {
            viewModel.configure(students: students, deviceApps: deviceApps)
        }
        .onChange(of: viewModel.didSaveSuccessfully) { _, success in
            if success {
                dismiss()
            }
        }
    }
    
    // MARK: - Student Selection Section
    
    /// Horizontal scrolling list of student avatars with checkmarks.
    /// Tapping toggles selection, and there's a Select/Deselect All button.
    private var studentSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Select Students", systemImage: "person.2")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    if viewModel.allStudentsSelected {
                        viewModel.deselectAllStudents()
                    } else {
                        viewModel.selectAllStudents()
                    }
                } label: {
                    Text(viewModel.allStudentsSelected ? "Deselect All" : "Select All")
                        .font(.subheadline)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(students, id: \.id) { student in
                        SelectableStudentAvatar(
                            student: student,
                            isSelected: viewModel.isStudentSelected(student.id)
                        ) {
                            viewModel.toggleStudent(student.id)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollTargetLayout()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Day Selection Section
    
    /// Row of weekday pills (Mon-Fri). Tap to toggle each day.
    /// Select All button toggles all weekdays at once.
    private var daySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Select Days", systemImage: "calendar")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    if viewModel.allWeekdaysSelected {
                        viewModel.deselectAllDays()
                    } else {
                        viewModel.selectAllWeekdays()
                    }
                } label: {
                    Text(viewModel.allWeekdaysSelected ? "Deselect All" : "Select All")
                        .font(.subheadline)
                }
            }
            
            HStack(spacing: 8) {
                ForEach(BulkProfileSetupViewModel.weekdays, id: \.self) { day in
                    DayPillButton(
                        day: day,
                        isSelected: viewModel.isDaySelected(day)
                    ) {
                        viewModel.toggleDay(day)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Timeslot Selection Section
    
    /// Row of timeslot pills (AM, PM, Home). Multiple can be selected.
    /// Each timeslot shows its time range below the label.
    private var timeslotSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Select Timeslots", systemImage: "clock")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(BulkProfileSetupViewModel.allTimeslots, id: \.self) { timeslot in
                    TimeslotPillButton(
                        timeslot: timeslot,
                        isSelected: viewModel.isTimeslotSelected(timeslot)
                    ) {
                        viewModel.toggleTimeslot(timeslot)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Session Duration Section
    
    /// Slider to set session length from 5-60 minutes.
    /// This duration applies to all selected apps.
    private var sessionDurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Session Duration", systemImage: "timer")
                .font(.headline)
            
            HStack(spacing: 16) {
                Slider(value: $viewModel.sessionLength, in: 5...60, step: 5)
                    .tint(.accentColor)
                
                Text("\(Int(viewModel.sessionLength)) min")
                    .font(.headline)
                    .monospacedDigit()
                    .frame(width: 60, alignment: .trailing)
                    .contentTransition(.numericText())
            }
            
            HStack {
                Text("5 min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("60 min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Category Filter Section
    
    /// Horizontal scroll of category pills to filter the app list.
    /// Categories include: All, Education, Productivity, Creativity, Games, Utilities.
    private var categoryFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Filter by Category", systemImage: "line.3.horizontal.decrease.circle")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AppFilterCategory.allCases) { category in
                        CategoryPillButton(
                            category: category,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - App List Section
    
    /// Scrollable list of apps from the class devices.
    /// Shows app icon, name, vendor, and selection checkmark.
    /// Filtered by the currently selected category.
    private var appListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Select Apps", systemImage: "app.badge")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.selectedBundleIds.count) selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.filteredApps.isEmpty {
                emptyAppsView
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.filteredApps) { app in
                        AppSelectionRow(
                            app: app,
                            isSelected: viewModel.isAppSelected(app.identifier ?? "")
                        ) {
                            if let bundleId = app.identifier {
                                viewModel.toggleApp(bundleId)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var emptyAppsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "app.dashed")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(viewModel.selectedCategory == .all ? "No apps available" : "No apps match this category")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Apply Button
    
    /// Bottom action bar with summary text and "Apply" button.
    /// Disabled until at least one student, day, timeslot, and app are selected.
    private var applyButton: some View {
        VStack(spacing: 8) {
            // Summary text
            Text(viewModel.summaryText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Apply button
            Button {
                Task {
                    await viewModel.applyConfiguration(using: dataProvider)
                }
            } label: {
                Text("Apply to Selected Students")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canApply ? Color.accentColor : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!viewModel.canApply)
            
            // Error message
            if let error = viewModel.saveError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Saving Overlay
    
    /// Full-screen overlay with spinner shown while saving profiles to Firebase.
    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Applying profiles...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(Color.gray.opacity(0.9))
            .cornerRadius(16)
        }
    }
}

// MARK: - Selectable Student Avatar

private struct SelectableStudentAvatar: View {
    let student: Student
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: student.photo) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 56, height: 56)
                                .foregroundColor(.gray)
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 3)
                    )
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.accentColor)
                            .background(Circle().fill(.white).frame(width: 16, height: 16))
                    }
                }
                
                Text(student.firstName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Day Pill Button

private struct DayPillButton: View {
    let day: DayOfWeek
    let isSelected: Bool
    let action: () -> Void
    
    private var shortName: String {
        switch day {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(shortName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Timeslot Pill Button

private struct TimeslotPillButton: View {
    let timeslot: TimeOfDay
    let isSelected: Bool
    let action: () -> Void
    
    private var label: String {
        switch timeslot {
        case .am: return "AM"
        case .pm: return "PM"
        case .home: return "Home"
        }
    }
    
    private var timeRange: String {
        switch timeslot {
        case .am: return "9:00-11:59"
        case .pm: return "12:00-4:59"
        case .home: return "5:00+"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text(timeRange)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Category Pill Button

private struct CategoryPillButton: View {
    let category: AppFilterCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.system(size: 14))
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : category.accentColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? category.accentColor : category.accentColor.opacity(0.15))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Selection Row

private struct AppSelectionRow: View {
    let app: DeviceApp
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // App Icon
                AsyncImage(url: app.iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    default:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "app.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                
                // App Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let vendor = app.vendor, !vendor.isEmpty {
                        Text(vendor)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .gray.opacity(0.5))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Preview

#Preview {
    BulkProfileSetupView(
        students: [],
        devices: [],
        dataProvider: StudentAppProfileDataProvider()
    )
}
