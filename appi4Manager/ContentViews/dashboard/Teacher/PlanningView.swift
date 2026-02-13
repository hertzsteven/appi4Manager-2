//
//  PlanningView.swift
//  appi4Manager
//
//  Full-screen view for weekly schedule planning, embedded in the sidebar.
//  Allows teachers to configure student app profiles for specific days and timeslots.
//  Replaces the former sheet-based Bulk Setup flow with an inline experience.
//

import SwiftUI

/// Full-screen planning view for configuring student app profiles.
///
/// Guides the teacher through a 4-step workflow:
/// 1. Select students
/// 2. Pick a schedule (days + timeslots)
/// 3. Set session duration
/// 4. Select an app (with inline category filter)
///
/// Each section is numbered and visually distinct to reinforce the sequential flow.
struct PlanningView: View {
    
    // MARK: - Properties
    
    let students: [Student]
    let devices: [TheDevice]
    let activeClass: TeacherClassInfo?
    let classesWithDevices: [TeacherClassInfo]
    
    @State private var viewModel = BulkProfileSetupViewModel()
    @State private var dataProvider = StudentAppProfileDataProvider()
    @State private var showSuccessAlert = false
    
    /// All device apps from the first device in the class
    private var deviceApps: [DeviceApp] {
        devices.first?.apps ?? []
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                planningHeaderSection
                studentSelectionSection
                scheduleSection
                sessionDurationSection
                appListSection
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .safeAreaInset(edge: .bottom) {
            applyButton
        }
        .overlay {
            if viewModel.isSaving {
                savingOverlay
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitleDisplayMode(.inline)
        .teacherDashboardToolbar(
            activeClass: activeClass,
            classesWithDevices: classesWithDevices
        )
        .onAppear {
            viewModel.configure(students: students, deviceApps: deviceApps)
        }
        .onChange(of: viewModel.didSaveSuccessfully) { _, success in
            if success {
                // Refresh data after save, then show confirmation
                Task {
                    await dataProvider.loadProfiles(for: students.map { $0.id })
                }
                showSuccessAlert = true
                viewModel.resetAfterSave()
            }
        }
        .alert("Profiles Applied", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("The selected app has been applied to the chosen students, days, and timeslots.")
        }
    }
    
    // MARK: - Header Section
    
    /// Introductory banner that establishes the purpose of the screen.
    private var planningHeaderSection: some View {
        HStack(spacing: 16) {
            // Accent bar on the left edge
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.brandIndigo)
                .frame(width: 5)
            
            VStack(alignment: .leading, spacing: 6) {
                Label("App Planning", systemImage: "calendar.badge.clock")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(Color.brandIndigo)
                
                Text("Configure which apps students can use during specific days and timeslots.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
    
    // MARK: - Student Selection Section (Step 1)
    
    private var studentSelectionSection: some View {
        PlanningCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StepHeader(step: 1, title: "Select Students", icon: "person.2")
                    
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
                
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(students, id: \.id) { student in
                            PlanningStudentAvatar(
                                student: student,
                                isSelected: viewModel.isStudentSelected(student.id)
                            ) {
                                viewModel.toggleStudent(student.id)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
                .scrollTargetLayout()
            }
        }
    }
    
    // MARK: - Schedule Section (Step 2) — Days + Timeslots merged
    
    private var scheduleSection: some View {
        PlanningCard {
            VStack(alignment: .leading, spacing: 16) {
                StepHeader(step: 2, title: "Schedule", icon: "calendar")
                
                // Days sub-section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            if viewModel.allWeekdaysSelected {
                                viewModel.deselectAllDays()
                            } else {
                                viewModel.selectAllWeekdays()
                            }
                        } label: {
                            Text(viewModel.allWeekdaysSelected ? "Deselect All" : "Select All")
                                .font(.caption)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(BulkProfileSetupViewModel.weekdays, id: \.self) { day in
                            PlanningDayPill(
                                day: day,
                                isSelected: viewModel.isDaySelected(day)
                            ) {
                                viewModel.toggleDay(day)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Timeslots sub-section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Timeslots")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            if viewModel.allTimeslotsSelected {
                                viewModel.deselectAllTimeslots()
                            } else {
                                viewModel.selectAllTimeslots()
                            }
                        } label: {
                            Text(viewModel.allTimeslotsSelected ? "Deselect All" : "Select All")
                                .font(.caption)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(BulkProfileSetupViewModel.allTimeslots, id: \.self) { timeslot in
                            PlanningTimeslotPill(
                                timeslot: timeslot,
                                isSelected: viewModel.isTimeslotSelected(timeslot)
                            ) {
                                viewModel.toggleTimeslot(timeslot)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Session Duration Section (Step 3)
    
    private var sessionDurationSection: some View {
        PlanningCard {
            VStack(alignment: .leading, spacing: 12) {
                StepHeader(step: 3, title: "Session Duration", icon: "timer")
                
                HStack(spacing: 16) {
                    Slider(value: $viewModel.sessionLength, in: 5...60, step: 5)
                        .tint(Color.brandIndigo)
                    
                    Text(viewModel.sessionLength, format: .number.precision(.fractionLength(0)))
                        .font(.headline)
                        .monospacedDigit()
                        .frame(width: 30, alignment: .trailing)
                        .contentTransition(.numericText())
                    
                    Text("min")
                        .font(.headline)
                }
                
                HStack {
                    Text("5 min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("60 min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - App List Section (Step 4)
    
    private var appListSection: some View {
        PlanningCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StepHeader(step: 4, title: "Select App", icon: "app.badge")
                    
                    Spacer()
                    
                    Text(viewModel.selectedBundleId != nil ? "1 selected" : "None selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Inline category filter
                ScrollView(.horizontal) {
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
                .scrollIndicators(.hidden)
                
                if viewModel.filteredApps.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        
                        Text(viewModel.selectedCategory == .all ? "No apps available" : "No apps match this category")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.filteredApps) { app in
                            PlanningAppRow(
                                app: app,
                                isSelected: viewModel.selectedBundleId == app.identifier
                            ) {
                                if let bundleId = app.identifier {
                                    viewModel.toggleApp(bundleId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Apply Button
    
    private var applyButton: some View {
        VStack(spacing: 8) {
            Text(viewModel.summaryText)
                .font(.caption)
                .foregroundStyle(viewModel.canApply ? .primary : .secondary)
                .lineLimit(2)
            
            Button {
                Task {
                    await viewModel.applyConfiguration(using: dataProvider)
                }
            } label: {
                Text("Apply to Selected Students")
                    .bold()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        viewModel.canApply
                            ? AnyShapeStyle(LinearGradient(
                                colors: [.brandIndigo, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            : AnyShapeStyle(Color.gray)
                    )
                    .clipShape(.rect(cornerRadius: 12))
            }
            .disabled(!viewModel.canApply)
            
            if let error = viewModel.saveError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Saving Overlay
    
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
                    .foregroundStyle(.white)
            }
            .padding(40)
            .background(Color.gray.opacity(0.9))
            .clipShape(.rect(cornerRadius: 16))
        }
    }
}

// MARK: - Planning Card Wrapper

/// Reusable card wrapper that adds the left accent bar and consistent styling.
private struct PlanningCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack(spacing: 0) {
            // Subtle left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.brandIndigo.opacity(0.3))
                .frame(width: 4)
                .padding(.vertical, 8)
            
            content
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - Step Header

/// Numbered step header with a badge, title, and SF Symbol icon.
private struct StepHeader: View {
    let step: Int
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            // Numbered badge
            Text("\(step)")
                .font(.caption)
                .bold()
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.brandIndigo)
                .clipShape(.circle)
            
            Label(title, systemImage: icon)
                .font(.headline)
        }
    }
}

// MARK: - Selectable Student Avatar

private struct PlanningStudentAvatar: View {
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
                                .clipShape(.circle)
                        default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 56, height: 56)
                                .foregroundStyle(.gray)
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.brandIndigo : Color.gray.opacity(0.3), lineWidth: 3)
                    )
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.brandIndigo)
                            .background(Circle().fill(.white).frame(width: 16, height: 16))
                    }
                }
                
                Text(student.firstName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Day Pill Button

private struct PlanningDayPill: View {
    let day: DayOfWeek
    let isSelected: Bool
    let action: () -> Void
    
    private var shortName: String {
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
    
    var body: some View {
        Button(action: action) {
            Text(shortName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.brandIndigo : Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray3), lineWidth: 1)
                        .opacity(isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Timeslot Pill Button

private struct PlanningTimeslotPill: View {
    let timeslot: TimeOfDay
    let isSelected: Bool
    let action: () -> Void
    
    private var label: String {
        switch timeslot {
        case .am: "AM"
        case .pm: "PM"
        case .home: "Home"
        case .blocked: "Overnight"
        }
    }
    
    private var timeRange: String {
        TimeslotSettings.timeRangeString(for: timeslot)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: timeslot.symbolName)
                        .font(.caption)
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                }
                
                Text(timeRange)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? timeslot.color : Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray3), lineWidth: 1)
                    .opacity(isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - App Selection Row

private struct PlanningAppRow: View {
    let app: DeviceApp
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AsyncImage(url: app.iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(.rect(cornerRadius: 10))
                    default:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "app.fill")
                                    .foregroundStyle(.gray)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if let vendor = app.vendor, !vendor.isEmpty {
                        Text(vendor)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Radio-style indicator for single selection
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.brandIndigo : .gray.opacity(0.5))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.brandIndigo.opacity(0.08) : Color.clear)
            .clipShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Preview

#Preview {
    let sampleApps: [DeviceApp] = [
        DeviceApp(name: "ActionMatrix", identifier: "com.blooming.actionmatrix", vendor: "Blooming Kids Software LLC", version: "1.0", icon: nil),
        DeviceApp(name: "Animal Matrix", identifier: "com.blooming.animalmatrix", vendor: "Blooming Kids Software LLC", version: "1.0", icon: nil),
        DeviceApp(name: "Sentence Maker", identifier: "com.blooming.sentencemaker", vendor: "Blooming Kids Software LLC", version: "2.1", icon: nil),
        DeviceApp(name: "Talking Machine", identifier: "com.blooming.talkingmachine", vendor: "Blooming Kids Software LLC", version: "1.5", icon: nil),
        DeviceApp(name: "Album Learner", identifier: "com.blooming.albumlearner", vendor: "Blooming Kids Software LLC", version: "1.0", icon: nil)
    ]
    
    let sampleStudents: [Student] = [
        Student(id: 1, name: "David Cohen", email: "david@school.com", username: "david.c", firstName: "David", lastName: "Cohen", photo: URL(string: "https://example.com/photo1.jpg")!),
        Student(id: 2, name: "Yehuda Levy", email: "yehuda@school.com", username: "yehuda.l", firstName: "Yehuda", lastName: "Levy", photo: URL(string: "https://example.com/photo2.jpg")!)
    ]
    
    let sampleDevice = TheDevice(
        serialNumber: "ABC123",
        locationId: 1,
        UDID: "UDID-001",
        name: "iPad Classroom 1",
        assetTag: "100",
        owner: nil,
        batteryLevel: 0.85,
        totalCapacity: 64.0,
        lastCheckin: "2026-02-12",
        modified: "2026-02-12",
        notes: "",
        apps: sampleApps
    )
    
    let sampleClass = TeacherClassInfo(
        id: "class-uuid-001",
        className: "Grossman",
        classUUID: "class-uuid-001",
        userGroupID: 100,
        userGroupName: "Grossman Group",
        locationId: 1,
        students: sampleStudents,
        devices: [sampleDevice]
    )
    
    NavigationStack {
        PlanningView(
            students: sampleStudents,
            devices: [sampleDevice],
            activeClass: sampleClass,
            classesWithDevices: [sampleClass]
        )
    }
    .environment(AuthenticationManager())
    .environmentObject(TeacherItems())
}

