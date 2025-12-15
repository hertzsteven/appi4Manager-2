//
//  StudentProfileCard.swift
//  appi4Manager
//
//  Enhanced student card that shows app profile information from Firebase
//

import SwiftUI

/// Card component that displays student info along with their app profile for a given timeslot
struct StudentProfileCard: View {
    let student: Student
    let timeslot: TimeOfDay
    let dayString: String
    let dataProvider: StudentAppProfileDataProvider
    let classDevices: [TheDevice]  // Devices in the class (for accessing installed apps)
    let dashboardMode: DashboardMode  // Determines what pickers to show in edit sheet
    
    @State private var apps: [DeviceApp] = []
    @State private var isLoadingApps = false
    
    // MARK: - Computed Properties
    
    private var session: Session? {
        dataProvider.getSession(for: student.id, day: dayString, timeslot: timeslot)
    }
    
    private var hasProfile: Bool {
        dataProvider.hasProfile(for: student.id)
    }
    
    private var sessionLengthMinutes: Int {
        Int(session?.sessionLength ?? 0)
    }
    
    /// Calculate fill percentage (5-60 minute range)
    private var sessionFillPercentage: CGFloat {
        let minValue: CGFloat = 5
        let maxValue: CGFloat = 60
        let value = CGFloat(session?.sessionLength ?? 0)
        return max(0, min(1, (value - minValue) / (maxValue - minValue)))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationLink {
            StudentProfileEditView(
                student: student,
                initialTimeslot: timeslot,
                initialDayString: dayString,
                dataProvider: dataProvider,
                classDevices: classDevices,
                dashboardMode: dashboardMode
            )
        } label: {
            VStack(spacing: 10) {
                // Student Photo
                studentPhotoView
                
                // Student Name
                VStack(spacing: 2) {
                    Text(student.firstName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(student.lastName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Divider()
                    .padding(.horizontal, 8)
                
                // App Icons Row or No Profile Placeholder
                if hasProfile {
                    appIconsRow
                    sessionLengthBar
                } else {
                    noProfileView
                }
            }
            .frame(width: 140, height: 200)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .onAppear {
            loadApps()
        }
        .onChange(of: timeslot) { _, _ in
            loadApps()
        }
    }
    
    // MARK: - Load Apps
    
    /// All device apps from the first device in the class
    private var allDeviceApps: [DeviceApp] {
        classDevices.first?.apps ?? []
    }
    
    private func loadApps() {
        guard let session = session else {
            apps = []
            return
        }
        // Match bundle IDs to device apps
        apps = session.apps.compactMap { bundleId in
            allDeviceApps.first { $0.identifier == bundleId }
        }
    }
    
    // MARK: - Subviews
    
    private var studentPhotoView: some View {
        AsyncImage(url: student.photo) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 60, height: 60)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            case .failure:
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            @unknown default:
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            }
        }
        .overlay(
            Circle()
                .stroke(hasProfile ? Color.accentColor : Color.gray, lineWidth: 2)
        )
    }
    
    private var noProfileView: some View {
        VStack(spacing: 4) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            Text("No profile")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 60)
    }
    
    private var appIconsRow: some View {
        HStack(spacing: 6) {
            if apps.isEmpty {
                // No apps configured
                Image(systemName: "app.dashed")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                Text("No apps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if apps.count == 1 {
                // Single app - show icon and name
                AsyncImage(url: apps[0].iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        Image(systemName: "app.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)
                            .frame(width: 36, height: 36)
                    }
                }
                Text(apps[0].displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } else {
                // Multiple apps - show first icon with "+" indicator
                AsyncImage(url: apps[0].iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        Image(systemName: "app.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)
                            .frame(width: 36, height: 36)
                    }
                }
                Text("+\(apps.count - 1)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 40)
    }
    
    private var sessionLengthBar: some View {
        VStack(spacing: 2) {
            // Session length label
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(sessionLengthMinutes) min")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            // Visual bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray4))
                        .frame(height: 6)
                    
                    // Filled portion
                    RoundedRectangle(cornerRadius: 3)
                        .fill(sessionBarColor)
                        .frame(width: geometry.size.width * sessionFillPercentage, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 8)
        }
    }
    
    /// Color for session bar based on fill percentage
    private var sessionBarColor: Color {
        if sessionFillPercentage < 0.33 {
            return .green
        } else if sessionFillPercentage < 0.66 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Student Profile Edit View

struct StudentProfileEditView: View {
    let student: Student
    let initialTimeslot: TimeOfDay
    let initialDayString: String
    let dataProvider: StudentAppProfileDataProvider
    let classDevices: [TheDevice]  // Devices in the class (for accessing installed apps)
    let dashboardMode: DashboardMode  // Determines what pickers to show
    
    /// Selected timeslot - editable in both modes
    @State private var selectedTimeslot: TimeOfDay
    
    /// Selected day - only editable in Planning mode
    @State private var selectedDay: DayOfWeek
    
    @State private var apps: [DeviceApp] = []
    @State private var isLoadingApps = false
    @State private var showEditSheet = false
    
    /// Whether to show the week view (only available in Planning mode)
    @State private var showWeekView = false
    
    /// For editing apps from week view - stores day/timeslot to edit
    @State private var weeklyEditDayString: String = ""
    @State private var weeklyEditTimeslot: TimeOfDay = .am
    @State private var showWeeklyEditSheet = false
    
    init(student: Student, initialTimeslot: TimeOfDay, initialDayString: String, 
         dataProvider: StudentAppProfileDataProvider, classDevices: [TheDevice], dashboardMode: DashboardMode) {
        self.student = student
        self.initialTimeslot = initialTimeslot
        self.initialDayString = initialDayString
        self.dataProvider = dataProvider
        self.classDevices = classDevices
        self.dashboardMode = dashboardMode
        
        // Initialize state
        _selectedTimeslot = State(initialValue: initialTimeslot)
        
        // Convert day string to DayOfWeek (default to current day if parsing fails)
        let day = Self.dayOfWeek(from: initialDayString) ?? DayOfWeek.current()
        _selectedDay = State(initialValue: day)
    }
    
    /// Convert day string like "Mon", "Tues" to DayOfWeek
    private static func dayOfWeek(from string: String) -> DayOfWeek? {
        switch string.lowercased() {
        case "mon": return .monday
        case "tues", "tue": return .tuesday
        case "wed": return .wednesday
        case "thurs", "thu": return .thursday
        case "fri": return .friday
        case "sat": return .saturday
        case "sun": return .sunday
        default: return nil
        }
    }
    
    /// Current day string based on selected day
    private var currentDayString: String {
        selectedDay.asAString
    }
    
    private var session: Session? {
        dataProvider.getSession(for: student.id, day: currentDayString, timeslot: selectedTimeslot)
    }
    
    private var hasProfile: Bool {
        dataProvider.hasProfile(for: student.id)
    }
    
    private var timeslotLabel: String {
        switch selectedTimeslot {
        case .am: return "AM (9:00-11:59)"
        case .pm: return "PM (12:00-4:59)"
        case .home: return "Home (5:00+)"
        }
    }
    
    /// First device in class (all devices have same apps installed)
    private var firstDevice: TheDevice? {
        classDevices.first
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Student Photo
                AsyncImage(url: student.photo) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(hasProfile ? Color.accentColor : Color.gray, lineWidth: 4)
                            )
                    default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                }
                
                // Student Name
                Text(student.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Week View Toggle (Planning mode only)
                if dashboardMode == .planning {
                    weekViewToggle
                }
                
                // Week View or Day View content
                if showWeekView && dashboardMode == .planning {
                    WeeklyProfileView(
                        student: student,
                        dataProvider: dataProvider,
                        deviceApps: firstDevice?.apps ?? []
                    ) { dayString, timeslot in
                        // Handle "Change" button tap from week view
                        weeklyEditDayString = dayString
                        weeklyEditTimeslot = timeslot
                        showWeeklyEditSheet = true
                    }
                } else {
                    // Mode-specific pickers (existing day view)
                    modeSpecificPickers
                
                Divider()
                
                if !hasProfile {
                    // No Profile Section
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        Text("No Profile Found")
                            .font(.headline)
                        Text("This student doesn't have an app profile yet. Tap \"Add Profile\" below to create one.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else {
                    // Current Apps Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assigned Apps")
                            .font(.headline)
                        
                        if isLoadingApps {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else if apps.isEmpty {
                            Text("No apps configured for this timeslot")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            ForEach(apps) { app in
                                HStack {
                                    AsyncImage(url: app.iconURL) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 44, height: 44)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        default:
                                            Image(systemName: "app.fill")
                                                .font(.title2)
                                                .foregroundColor(.accentColor)
                                                .frame(width: 44, height: 44)
                                                .background(Color.accentColor.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(app.displayName)
                                            .font(.body)
                                        if let vendor = app.vendor, !vendor.isEmpty {
                                            Text(vendor)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Session Length Section
                    if let session = session {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Session Length")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "clock")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                
                                Text("\(Int(session.sessionLength)) minutes")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
                } // End of else block for day view
                
                // Edit/Add Profile Button
                Button {
                    showEditSheet = true
                } label: {
                    Text(hasProfile ? "Edit Profile" : "Add Profile")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle("Student Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadApps()
        }
        .onChange(of: selectedTimeslot) { _, _ in
            loadApps()
        }
        .onChange(of: selectedDay) { _, _ in
            loadApps()
        }
        .sheet(isPresented: $showEditSheet) {
            // Refresh apps after edit
            loadApps()
        } content: {
            EditStudentProfileSheet(
                student: student,
                timeslot: selectedTimeslot,
                dayString: currentDayString,
                dataProvider: dataProvider,
                deviceApps: firstDevice?.apps ?? []
            )
        }
        .sheet(isPresented: $showWeeklyEditSheet) {
            // Refresh after weekly edit
            loadApps()
        } content: {
            EditStudentProfileSheet(
                student: student,
                timeslot: weeklyEditTimeslot,
                dayString: weeklyEditDayString,
                dataProvider: dataProvider,
                deviceApps: firstDevice?.apps ?? []
            )
        }
    }
    
    // MARK: - Mode-Specific Pickers
    
    /// Shows timeslot picker (Now mode) or day+timeslot pickers (Planning mode)
    @ViewBuilder
    private var modeSpecificPickers: some View {
        VStack(spacing: 16) {
            if dashboardMode == .now {
                // Now mode: Just timeslot picker, today's date is fixed
                VStack(spacing: 8) {
                    Text("Today's Session")
                        .font(.headline)
                    
                    Picker("Timeslot", selection: $selectedTimeslot) {
                        Text("AM").tag(TimeOfDay.am)
                        Text("PM").tag(TimeOfDay.pm)
                        Text("Home").tag(TimeOfDay.home)
                    }
                    .pickerStyle(.segmented)
                    
                    Text(timeslotLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Planning mode: Day picker + Timeslot picker
                VStack(spacing: 12) {
                    Text("Select Day & Timeslot")
                        .font(.headline)
                    
                    // Day picker
                    HStack(spacing: 6) {
                        ForEach(BulkProfileSetupViewModel.weekdays, id: \.self) { day in
                            Button {
                                selectedDay = day
                            } label: {
                                Text(dayShortName(day))
                                    .font(.subheadline)
                                    .fontWeight(selectedDay == day ? .semibold : .regular)
                                    .foregroundColor(selectedDay == day ? .white : .primary)
                                    .frame(width: 44, height: 36)
                                    .background(selectedDay == day ? Color.accentColor : Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Timeslot picker
                    Picker("Timeslot", selection: $selectedTimeslot) {
                        Text("AM").tag(TimeOfDay.am)
                        Text("PM").tag(TimeOfDay.pm)
                        Text("Home").tag(TimeOfDay.home)
                    }
                    .pickerStyle(.segmented)
                    
                    Text("\(currentDayString) • \(timeslotLabel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Week View Toggle
    
    /// Toggle button to switch between Day View and Week View (Planning mode only)
    private var weekViewToggle: some View {
        HStack {
            Text("View Mode")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Picker("View Mode", selection: $showWeekView) {
                Text("Day").tag(false)
                Text("Week").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .sensoryFeedback(.selection, trigger: showWeekView)
    }
    
    private func dayShortName(_ day: DayOfWeek) -> String {
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
    
    /// All device apps from the first device in the class
    private var allDeviceApps: [DeviceApp] {
        classDevices.first?.apps ?? []
    }
    
    private func loadApps() {
        guard let session = session else {
            apps = []
            return
        }
        // Match bundle IDs to device apps
        apps = session.apps.compactMap { bundleId in
            allDeviceApps.first { $0.identifier == bundleId }
        }
    }
}

// MARK: - Edit Student Profile Sheet

struct EditStudentProfileSheet: View {
    let student: Student
    let timeslot: TimeOfDay
    let dayString: String
    let dataProvider: StudentAppProfileDataProvider
    let deviceApps: [DeviceApp]
    
    @Environment(\.dismiss) private var dismiss
    
    /// Selected app bundle IDs
    @State private var selectedBundleIds: Set<String> = []
    
    /// Session duration in minutes
    @State private var sessionLength: Double = 30
    
    /// Saving state
    @State private var isSaving = false
    @State private var saveError: String?
    
    /// Current filter category for app list
    @State private var selectedCategory: AppFilterCategory = .all
    
    /// Whether this student has an existing profile
    private var hasProfile: Bool {
        dataProvider.hasProfile(for: student.id)
    }
    
    private var timeslotLabel: String {
        switch timeslot {
        case .am: return "AM Session"
        case .pm: return "PM Session"
        case .home: return "Home Session"
        }
    }
    
    private var navigationTitle: String {
        hasProfile ? "Edit \(timeslotLabel)" : "Add Profile - \(timeslotLabel)"
    }
    
    /// Apps filtered by the selected category
    private var filteredApps: [DeviceApp] {
        guard selectedCategory != .all else { return deviceApps }
        return deviceApps.filter { app in
            selectedCategory.matches(appName: app.displayName)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Session Duration Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Session Duration")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        
                        Text("\(Int(sessionLength)) minutes")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(width: 100, alignment: .leading)
                        
                        Slider(value: $sessionLength, in: 5...60, step: 5)
                            .tint(.accentColor)
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
                
                Divider()
                
                // App Selection Header
                HStack {
                    Text("Select Apps")
                        .font(.headline)
                    Spacer()
                    Text("\(selectedBundleIds.count) selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Category Filter Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Filter by Category", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AppFilterCategory.allCases) { category in
                                CategoryPillButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // App List
                if deviceApps.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Apps Available")
                            .font(.headline)
                        Text("Device apps not loaded.\nMake sure the class has devices with apps.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else if filteredApps.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Matching Apps")
                            .font(.headline)
                        Text("No apps match the \"\(selectedCategory.rawValue)\" category.\nTry selecting a different category.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(filteredApps) { app in
                                appRow(for: app)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(Color(.systemGray6))
                }
                
                // Error message if save failed
                if let error = saveError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(hasProfile ? "Save" : "Create") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView(hasProfile ? "Saving..." : "Creating profile...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                }
            }
        }
        .onAppear {
            loadCurrentValues()
        }
    }
    
    // MARK: - App Row
    
    @ViewBuilder
    private func appRow(for app: DeviceApp) -> some View {
        let bundleId = app.identifier ?? ""
        let isSelected = selectedBundleIds.contains(bundleId)
        
        Button {
            if isSelected {
                selectedBundleIds.remove(bundleId)
            } else {
                selectedBundleIds.insert(bundleId)
            }
        } label: {
            HStack(spacing: 12) {
                // App Icon
                AsyncImage(url: app.iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "app.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                
                // App Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let vendor = app.vendor {
                        Text(vendor)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .gray)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Methods
    
    /// Load current session values
    private func loadCurrentValues() {
        // Start with no apps selected - user will select apps fresh each time
        selectedBundleIds = []
        
        // Get current session to load session length (if profile exists)
        if let session = dataProvider.getSession(for: student.id, day: dayString, timeslot: timeslot) {
            // Only load the session length, not the previously selected apps
            sessionLength = session.sessionLength > 0 ? session.sessionLength : 30
        } else {
            // Default values for new profiles
            sessionLength = 30
        }
    }
    
    /// Save the profile to Firestore
    private func saveProfile() async {
        isSaving = true
        saveError = nil
        
        do {
            // Update the session in the data provider and save
            try await dataProvider.updateAndSaveSession(
                for: student.id,
                day: dayString,
                timeslot: timeslot,
                apps: Array(selectedBundleIds),
                sessionLength: sessionLength
            )
            
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                saveError = "Failed to save: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}

// MARK: - Previews


struct StudentProfileCard_Previews: PreviewProvider {
    static let placeholderPhoto = URL(string: "https://via.placeholder.com/100")!
    
    static var mockStudent: Student {
        Student(
            id: 123,
            name: "John Doe",
            email: "john.doe@school.edu",
            username: "johndoe",
            firstName: "John",
            lastName: "Doe",
            photo: placeholderPhoto
        )
    }
    
    static var previews: some View {
        Group {
            // Single card preview
            StudentProfileCard(
                student: mockStudent,
                timeslot: .am,
                dayString: "Mon",
                dataProvider: StudentAppProfileDataProvider(),
                classDevices: [],
                dashboardMode: .now
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("AM Timeslot")
        }
    }
}

struct StudentProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StudentProfileEditView(
                student: StudentProfileCard_Previews.mockStudent,
                initialTimeslot: .am,
                initialDayString: "Mon",
                dataProvider: StudentAppProfileDataProvider(),
                classDevices: [],
                dashboardMode: .now
            )
        }
    }
}
