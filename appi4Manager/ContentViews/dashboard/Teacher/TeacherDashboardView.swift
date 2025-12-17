//
//  TeacherDashboardView.swift
//  appi4Manager
//
//  Main dashboard for teachers after login.
//  Shows students in a grid with their app profiles, organized by timeslot (AM/PM/Home).
//  Teachers can tap on students to edit their profiles, or access devices via toolbar button.
//

import SwiftUI

// MARK: - TeacherDashboardView

/// The main teacher dashboard that displays students directly with their app profiles.
///
/// **Flow:**
/// 1. If not authenticated → Shows login prompt
/// 2. If loading → Shows spinner
/// 3. If error → Shows error with retry button
/// 4. If no classes → Shows empty state
/// 5. If multiple classes and none selected → Shows class picker
/// 6. Otherwise → Shows the main students grid view
///
/// **Toolbar Buttons:**
/// - iPad icon: Opens devices sheet
/// - Slider icon: Opens bulk profile setup
/// - Gear icon: Opens settings
struct TeacherDashboardView: View {
    // MARK: - Environment & State
    
    @Environment(AuthenticationManager.self) private var authManager
    @EnvironmentObject var teacherItems: TeacherItems
    
    /// True while fetching teacher data from API
    @State private var isLoading = false
    
    /// Array of classes this teacher teaches, with students and devices
    @State private var teacherClasses: [TeacherClassInfo] = []
    
    /// Error message to display if data loading fails
    @State private var errorMessage: String?
    
    /// Prevents loading animation on first render before task runs
    @State private var hasAttemptedLoad = false
    
    /// The class the teacher has explicitly selected (for multi-class teachers)
    @State private var selectedClass: TeacherClassInfo?
    
    /// Controls the class selector sheet visibility
    @State private var showClassSelector = false
    
    /// Controls the bulk profile setup sheet visibility
    @State private var showBulkSetup = false
    
    /// Currently selected timeslot for viewing student app profiles (AM/PM/Home)
    @State private var selectedTimeslot: TimeOfDay = StudentAppProfileDataProvider.currentTimeslot()
    
    /// Controls the devices sheet visibility (accessible via toolbar iPad button)
    @State private var showDevicesSheet = false
    
    /// Controls the student management sheet visibility
    @State private var showStudentManagement = false
    
    /// Controls the restrictions sheet visibility (shows current device locks)
    @State private var showRestrictionsSheet = false
    
    /// Current dashboard mode: Now (quick daily changes) or Planning (weekly scheduling)
    @State private var dashboardMode: DashboardMode = .now
    
    /// Selected day for Planning mode (defaults to today's weekday)
    @State private var selectedDayForPlanning: DayOfWeek = DayOfWeek.current()
    
    /// Provides student app profile data from Firebase
    @State private var dataProvider = StudentAppProfileDataProvider()
    
    /// Separate data provider for bulk profile setup to avoid conflicts
    @State private var bulkSetupDataProvider = StudentAppProfileDataProvider()
    
    /// Controls the dummy student creation loading state
    @State private var isCreatingDummy = false
    
    /// Controls the dummy student created success alert
    @State private var showDummyCreatedAlert = false
    
    // MARK: - Computed Properties
    
    /// The currently active class - either explicitly selected or defaults to first class
    private var activeClass: TeacherClassInfo? {
        selectedClass ?? teacherClasses.first
    }
    
    /// Students filtered to exclude dummy students (those with lastName matching the class UUID)
    private var filteredStudents: [Student] {
        guard let activeClass = activeClass else { return [] }
        return activeClass.students.filter { $0.lastName != activeClass.classUUID }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if !authManager.isAuthenticated {
                    // Not logged in - show login prompt
                    loginPromptView
                } else if isLoading || !hasAttemptedLoad {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if teacherClasses.isEmpty {
                    emptyClassesView
                } else if teacherClasses.count > 1 && selectedClass == nil {
                    // Multiple classes but none selected - show class selection prompt
                    classSelectionPromptView
                } else {
                    // Main content - show dashboard for active class
                    classesContentView
                }
            }
            .navigationTitle("My Students")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Student management button
                    Button {
                        showStudentManagement = true
                    } label: {
                        Image(systemName: "person.2.fill")
                    }
                    .disabled(activeClass == nil)
                    
                    // Devices button
                    Button {
                        showDevicesSheet = true
                    } label: {
                        Image(systemName: "ipad.landscape")
                    }
                    .disabled(activeClass == nil)
                    
                    // Restrictions button - shows current device locks
                    Button {
                        showRestrictionsSheet = true
                    } label: {
                        Image(systemName: "lock.circle")
                    }
                    .disabled(activeClass == nil)
                    
                    // Dummy student creation button
                    Button {
                        Task {
                            await createDummyStudent()
                        }
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .disabled(activeClass == nil || isCreatingDummy)
                    
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .sheet(isPresented: $showClassSelector) {
            ClassSelectorSheet(
                classes: teacherClasses,
                selectedClass: $selectedClass,
                isPresented: $showClassSelector
            )
        }
        .sheet(isPresented: $showBulkSetup) {
            if let activeClass = activeClass {
                BulkProfileSetupView(
                    students: filteredStudents,
                    devices: activeClass.devices,
                    dataProvider: bulkSetupDataProvider,
                    onProfilesUpdated: {
                        // Refresh the main dataProvider so weekly/planning views show updated data
                        Task {
                            await dataProvider.loadProfiles(for: filteredStudents.map { $0.id })
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showDevicesSheet) {
            if let activeClass = activeClass {
                NavigationStack {
                    TeacherDevicesView(teacherClasses: [activeClass])
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showDevicesSheet = false
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showStudentManagement) {
            if let activeClass = activeClass {
                NavigationStack {
                    TeacherStudentManagementSheet(
                        classInfo: activeClass,
                        onStudentChanged: {
                            // Refresh teacher data when a student is added/edited/deleted
                            Task {
                                await loadTeacherData()
                            }
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showStudentManagement = false
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showRestrictionsSheet) {
            if let activeClass = activeClass, let token = authManager.token {
                StudentRestrictionsSheet(
                    classInfo: activeClass,
                    authToken: token
                )
            }
        }
        .alert("Dummy Student Created", isPresented: $showDummyCreatedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let activeClass = activeClass {
                Text("Created dummy student with last name '\(activeClass.classUUID)' in class \(activeClass.className).")
            }
        }
        .task {
            if authManager.isAuthenticated {
                await loadTeacherData()
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                Task {
                    await loadTeacherData()
                }
            }
        }
        .onChange(of: dashboardMode) { _, newMode in
            // When switching to Now mode, reset timeslot to auto-detected current time
            if newMode == .now {
                selectedTimeslot = StudentAppProfileDataProvider.currentTimeslot()
            }
        }
    }
    
    // MARK: - Login Prompt View
    
    /// Shown when user is not authenticated.
    /// Displays a sign-in button that navigates to TeacherLoginView.
    private var loginPromptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Sign In Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please sign in to view your classes, students, and devices.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink(destination: TeacherLoginView()) {
                Text("Sign In")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Loading View
    
    /// Spinner shown while fetching teacher data from the API.
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your classes...")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Error View
    
    /// Displays an error message with a retry button when data loading fails.
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Error Loading Data")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await loadTeacherData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Empty Classes View
    
    /// Shown when the teacher has no classes assigned to them.
    private var emptyClassesView: some View {
        ContentUnavailableView(
            "No Classes Found",
            systemImage: "person.3.fill",
            description: Text("You don't have any classes assigned yet.")
        )
    }
    
    // MARK: - Class Selection Prompt View
    
    /// Shown when teacher teaches multiple classes and hasn't selected one yet.
    /// Displays a list of classes to choose from.
    private var classSelectionPromptView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            // Title
            VStack(spacing: 8) {
                Text("Select Your Class")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("You teach \(teacherClasses.count) classes. Please select which class you'd like to work with.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Class Picker
            VStack(spacing: 16) {
                ForEach(teacherClasses) { classInfo in
                    Button {
                        selectedClass = classInfo
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(classInfo.className)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                HStack(spacing: 12) {
                                    Label("\(classInfo.students.count)", systemImage: "person.2.fill")
                                    Label("\(classInfo.devices.count)", systemImage: "ipad.landscape")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Classes Content View
    
    /// Main content view showing the dashboard with:
    /// - Welcome header with teacher's name
    /// - Current class info bar
    /// - Mode picker (Now/Planning)
    /// - Mode-specific controls (timeslot only for Now, day+timeslot+bulk for Planning)
    /// - Students grid with profile cards
    private var classesContentView: some View {
        VStack(spacing: 0) {
            // Fixed header section
            ScrollView {
                VStack(spacing: 16) {
                    welcomeHeader
                    classInfoCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .frame(height: 220) // Fixed height for header section
            
            // Mode Picker (Now / Planning) + Bulk Setup button in Planning mode
            modePickerWithBulkButton
            
            // Students Grid (scrollable)
            inlineStudentsGrid
        }
        .background(Color(.systemGray5))
        .task {
            // Load student profiles when view appears
            if let activeClass = activeClass {
                await dataProvider.loadProfiles(for: activeClass.students.map { $0.id })
            }
        }
        .refreshable {
            await loadTeacherData()
            if let activeClass = activeClass {
                await dataProvider.loadProfiles(for: activeClass.students.map { $0.id })
            }
        }
    }
    
    // MARK: - Mode Picker with Bulk Button
    
    /// Mode picker segmented control + Bulk Setup button (visible only in Planning mode)
    private var modePickerWithBulkButton: some View {
        VStack(spacing: 12) {
            // Mode picker
            Picker("Mode", selection: $dashboardMode) {
                ForEach(DashboardMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            // Bulk Setup button - only visible in Planning mode
            if dashboardMode == .planning {
                Button {
                    showBulkSetup = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Bulk Setup")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Welcome Header
    
    /// Top card showing "Welcome back, [Teacher's Name]" with current date
    /// and a "Switch" button if teacher has multiple classes.
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(authManager.authenticatedUser?.firstName ?? "Teacher")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Class Switcher Button (only show if multiple classes)
                if teacherClasses.count > 1 {
                    Button {
                        showClassSelector = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up.fill")
                            Text("Switch")
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Current date and session
            HStack(spacing: 12) {
                Label(currentDateString, systemImage: "calendar")
                Label(currentSessionString, systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Class Info Card
    
    /// Compact bar showing current class name with student/device counts.
    private var classInfoCard: some View {
        Group {
            if let classInfo = activeClass {
                HStack {
                    // Class name with icon
                    HStack(spacing: 8) {
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(.accentColor)
                        Text(classInfo.className)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    // Student and device counts
                    HStack(spacing: 12) {
                        Label("\(classInfo.students.count)", systemImage: "person.2.fill")
                        Label("\(classInfo.devices.count)", systemImage: "ipad.landscape")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Inline Timeslot Picker
    
    /// Segmented control for selecting AM, PM, or Home timeslot.
    /// Changing this updates which app profiles are shown for each student.
    private var inlineTimeslotPicker: some View {
        VStack(spacing: 4) {
            Picker("Timeslot", selection: $selectedTimeslot) {
                Text("AM").tag(TimeOfDay.am)
                Text("PM").tag(TimeOfDay.pm)
                Text("Home").tag(TimeOfDay.home)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            // Timeslot time range label
            Text(inlineTimeslotTimeRange)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private var inlineTimeslotTimeRange: String {
        switch selectedTimeslot {
        case .am:
            return "9:00 AM - 11:59 AM"
        case .pm:
            return "12:00 PM - 4:59 PM"
        case .home:
            return "5:00 PM onwards"
        }
    }
    
    /// Day string for profile lookup - uses today in Now mode, selected day in Planning mode
    private var currentDayString: String {
        if dashboardMode == .now {
            return StudentAppProfileDataProvider.currentDayString()
        } else {
            return selectedDayForPlanning.asAString
        }
    }
    
    // MARK: - Inline Students Grid
    
    /// Main grid of StudentProfileCard components showing all students in the class.
    /// Handles loading, error, empty, and populated states.
    private var inlineStudentsGrid: some View {
        Group {
            if dataProvider.isLoading {
                // Loading state
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading student profiles...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = dataProvider.errorMessage {
                // Error state
                ContentUnavailableView {
                    Label("Error Loading Profiles", systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task {
                            if let activeClass = activeClass {
                                await dataProvider.loadProfiles(for: activeClass.students.map { $0.id })
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if let activeClass = activeClass, !filteredStudents.isEmpty {
                // Students Grid (filtered to exclude dummy students)
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredStudents, id: \.id) { student in
                            StudentProfileCard(
                                student: student,
                                timeslot: selectedTimeslot,
                                dayString: currentDayString,
                                dataProvider: dataProvider,
                                classDevices: activeClass.devices,
                                dashboardMode: dashboardMode
                            )
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
            } else {
                // Empty state
                ContentUnavailableView(
                    "No Students",
                    systemImage: "person.3.fill",
                    description: Text("No students found in this class.")
                )
            }
        }
    }
    
    // MARK: - Helper Computed Properties
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    private var currentSessionString: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Morning Session"
        } else if hour < 17 {
            return "Afternoon Session"
        } else {
            return "After School"
        }
    }
    
    // MARK: - Computed Properties for Counts
    
    private var totalStudents: Int {
        activeClass?.students.count ?? 0
    }
    
    private var totalDevices: Int {
        activeClass?.devices.count ?? 0
    }
    
    // MARK: - Class Section
    
    private func classSection(_ classInfo: TeacherClassInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Class Header
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.accentColor)
                Text(classInfo.className)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal)
            
            // Students Section
            if !classInfo.students.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Students")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(classInfo.students, id: \.id) { student in
                                StudentCard(student: student)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Devices Section
            if !classInfo.devices.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Devices")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 140), spacing: 16)
                    ], spacing: 16) {
                        ForEach(classInfo.devices, id: \.UDID) { device in
                            DeviceCard(device: device)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Data Loading
    
    private func loadTeacherData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            teacherClasses = []
        }
        
        guard let teacherId = authManager.authenticatedUser?.id else {
            await MainActor.run {
                errorMessage = "No authenticated teacher found."
                isLoading = false
                hasAttemptedLoad = true
            }
            return
        }
        
        do {
            // 1. Fetch the teacher's user details to get their teacherGroups
            let userDetailResponse: UserDetailResponse = try await ApiManager.shared.getData(
                from: .getaUser(id: teacherId)
            )
            let teacherGroupIds = userDetailResponse.user.teacherGroups
            
            // 2. Fetch all school classes
            let classesResponse: SchoolClassResponse = try await ApiManager.shared.getData(
                from: .getSchoolClasses
            )
            
            // 3. Filter classes where userGroupId is in the teacher's teacherGroups
            let matchingClasses = classesResponse.classes.filter { schoolClass in
                teacherGroupIds.contains(schoolClass.userGroupId)
            }
            
            // 4. Fetch all groups to get group names
            let groupsResponse: MDMGroupsResponse = try await ApiManager.shared.getData(
                from: .getGroups
            )
            
            // 5. Build the TeacherClassInfo array with students and devices
            var classInfos: [TeacherClassInfo] = []
            
            for schoolClass in matchingClasses {
                let groupName = groupsResponse.groups.first { $0.id == schoolClass.userGroupId }?.name
                
                // Fetch students for this class
                var students: [Student] = []
                do {
                    let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(
                        from: .getStudents(uuid: schoolClass.uuid)
                    )
                    students = classDetailResponse.class.students
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to fetch students for class \(schoolClass.name): \(error)")
                    #endif
                }
                
                // Fetch devices for this class (with apps included for Edit Profile functionality)
                var devices: [TheDevice] = []
                do {
                    let deviceResponse: DeviceListResponse = try await ApiManager.shared.getData(
                        from: .getDevicesWithApps(assettag: String(schoolClass.userGroupId))
                    )
                    devices = deviceResponse.devices
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to fetch devices for class \(schoolClass.name): \(error)")
                    #endif
                }
                
                var info = TeacherClassInfo(
                    id: schoolClass.uuid,
                    className: schoolClass.name,
                    classUUID: schoolClass.uuid,
                    userGroupID: schoolClass.userGroupId,
                    userGroupName: groupName
                )
                info.students = students
                info.devices = devices
                
                classInfos.append(info)
            }
            
            classInfos.sort { $0.className < $1.className }
            
            await MainActor.run {
                teacherClasses = classInfos
                
                // Keep selectedClass in sync with freshly fetched data
                if let current = selectedClass {
                    selectedClass = classInfos.first(where: { $0.id == current.id }) ?? classInfos.first
                } else {
                    selectedClass = classInfos.first
                }
                
                isLoading = false
                hasAttemptedLoad = true
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load class info: \(error.localizedDescription)"
                isLoading = false
                hasAttemptedLoad = true
            }
        }
    }
    
    // MARK: - Dummy Student Creation
    
    /// Creates a dummy student with first name "dummy" and last name as the class UUID.
    /// Used for operational purposes like assigning to unowned devices before MDM commands.
    private func createDummyStudent() async {
        guard let activeClass = activeClass else { return }
        
        await MainActor.run {
            isCreatingDummy = true
        }
        
        do {
            // Generate unique username from UUID
            let username = String(Array(UUID().uuidString.split(separator: "-")).last!)
            
            // Get location and group IDs from teacher context
            let locationId = teacherItems.currentLocation.id
            let groupId = activeClass.userGroupID
            
            // Create user object with dummy name and class UUID as last name
            var newUser = User.makeDefault()
            newUser.username = username
            newUser.firstName = "dummy"
            newUser.lastName = activeClass.classUUID
            newUser.locationId = locationId
            newUser.groupIds = [groupId]
            
            // Add to MDM system
            let _: AddAUserResponse = try await ApiManager.shared.getData(
                from: .addUsr(user: newUser)
            )
            
            #if DEBUG
            print("✅ Created dummy student with lastName: \(activeClass.classUUID)")
            #endif
            
            // Refresh teacher data to show new student
            await loadTeacherData()
            if let activeClass = self.activeClass {
                await dataProvider.loadProfiles(for: activeClass.students.map { $0.id })
            }
            
            await MainActor.run {
                isCreatingDummy = false
                showDummyCreatedAlert = true
            }
        } catch {
            await MainActor.run {
                isCreatingDummy = false
                #if DEBUG
                print("❌ Failed to create dummy student: \(error)")
                #endif
            }
        }
    }
}

// MARK: - Previews

#Preview("Teacher Dashboard") {
    TeacherDashboardView()
        .environment(AuthenticationManager())
        .environmentObject(TeacherItems())
}

#Preview("Students View with Profiles") {
    let placeholderPhoto = URL(string: "https://via.placeholder.com/100")!
    
    return NavigationStack {
        TeacherStudentsView(teacherClasses: [
            TeacherClassInfo(
                id: "class-1",
                className: "Grade 1A",
                classUUID: "uuid-1",
                userGroupID: 100,
                userGroupName: "Group 1",
                students: [
                    Student(id: 101, name: "John Smith", email: "john@school.edu",
                           username: "john", firstName: "John", lastName: "Smith",
                           photo: placeholderPhoto),
                    Student(id: 102, name: "Jane Doe", email: "jane@school.edu",
                           username: "jane", firstName: "Jane", lastName: "Doe",
                           photo: placeholderPhoto),
                    Student(id: 103, name: "Bob Wilson", email: "bob@school.edu",
                           username: "bob", firstName: "Bob", lastName: "Wilson",
                           photo: placeholderPhoto),
                    Student(id: 104, name: "Alice Brown", email: "alice@school.edu",
                           username: "alice", firstName: "Alice", lastName: "Brown",
                           photo: placeholderPhoto),
                    Student(id: 105, name: "Charlie Davis", email: "charlie@school.edu",
                           username: "charlie", firstName: "Charlie", lastName: "Davis",
                           photo: placeholderPhoto),
                    Student(id: 106, name: "Emma Taylor", email: "emma@school.edu",
                           username: "emma", firstName: "Emma", lastName: "Taylor",
                           photo: placeholderPhoto)
                ],
                devices: []
            )
        ])
    }
}
