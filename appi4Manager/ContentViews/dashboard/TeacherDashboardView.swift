//
//  TeacherDashboardView.swift
//  appi4Manager
//
//  Dashboard for teachers - shows their classes, students, and devices
//

import SwiftUI

struct TeacherDashboardView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @EnvironmentObject var teacherItems: TeacherItems
    
    @State private var isLoading = false
    @State private var teacherClasses: [TeacherClassInfo] = []
    @State private var errorMessage: String?
    @State private var hasAttemptedLoad = false
    @State private var selectedClass: TeacherClassInfo?
    @State private var showClassSelector = false
    @State private var showBulkSetup = false
    
    /// Data provider for bulk profile setup
    @State private var bulkSetupDataProvider = StudentAppProfileDataProvider()
    
    /// The currently active class (selected or default first class)
    private var activeClass: TeacherClassInfo? {
        selectedClass ?? teacherClasses.first
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
            .navigationTitle("Teacher Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showBulkSetup = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .disabled(activeClass == nil)
                    
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
                    students: activeClass.students,
                    devices: activeClass.devices,
                    dataProvider: bulkSetupDataProvider
                )
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
    }
    
    // MARK: - Login Prompt View
    
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
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your classes...")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Error View
    
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
    
    private var emptyClassesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Classes Found")
                .font(.headline)
            
            Text("You don't have any classes assigned yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Class Selection Prompt View
    
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
    
    // MARK: - Classes Content View (now shows category tiles)
    
    private var classesContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Welcome Header
                welcomeHeader
                
                // MARK: - Class Info Card
                classInfoCard
                
                // MARK: - Category Cards
                categoryCards
            }
            .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        }
        .background(Color(.systemGray5))
        .refreshable {
            await loadTeacherData()
        }
    }
    
    // MARK: - Welcome Header
    
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
    
    private var classInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.accentColor)
                Text("Current Class")
                    .font(.headline)
            }
            
            if let classInfo = activeClass {
                VStack(alignment: .leading, spacing: 8) {
                    Text(classInfo.className)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let groupName = classInfo.userGroupName {
                        Text(groupName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        Label("\(classInfo.students.count) Students", systemImage: "person.2.fill")
                        Label("\(classInfo.devices.count) Devices", systemImage: "ipad.landscape")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var categoryCards: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 20) {
            // Students Category - only pass the active class
            if let currentClass = activeClass {
                NavigationLink(destination: TeacherStudentsView(teacherClasses: [currentClass])) {
                    TeacherCategoryCard(
                        name: "Students",
                        color: .blue,
                        iconName: "person.crop.square.fill",
                        count: totalStudents
                    )
                }
                .buttonStyle(.plain)
                
                // Devices Category - only pass the active class
                NavigationLink(destination: TeacherDevicesView(teacherClasses: [currentClass])) {
                    TeacherCategoryCard(
                        name: "Devices",
                        color: .green,
                        iconName: "ipad.landscape",
                        count: totalDevices
                    )
                }
                .buttonStyle(.plain)
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
}

// MARK: - Student Card

struct StudentCard: View {
    let student: Student
    
    var body: some View {
        VStack(spacing: 8) {
            // Student Photo
            AsyncImage(url: student.photo) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                @unknown default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.accentColor, lineWidth: 3)
            )
            
            // Student Name
            Text(student.firstName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(width: 100)
        .padding(.vertical, 8)
    }
}

// MARK: - Device Card

struct DeviceCard: View {
    let device: TheDevice
    
    /// Determines the ring color based on the device name
    private var ringColor: Color {
        let lowercasedName = device.name.lowercased()
        if lowercasedName.contains("blue") {
            return .blue
        } else if lowercasedName.contains("silver") || lowercasedName.contains("gray") || lowercasedName.contains("grey") {
            return Color(white: 0.6)
        } else if lowercasedName.contains("gold") {
            return Color.yellow
        } else if lowercasedName.contains("pink") || lowercasedName.contains("rose") {
            return .pink
        } else if lowercasedName.contains("purple") {
            return .purple
        } else if lowercasedName.contains("green") {
            return .green
        } else if lowercasedName.contains("red") {
            return .red
        } else if lowercasedName.contains("orange") {
            return .orange
        } else {
            return .gray
        }
    }
    
    /// Extract model info from the device
    private var modelInfo: String {
        // Using assetTag or any other available model info
        "iPad"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Device Icon with colored ring
            ZStack {
                Circle()
                    .stroke(ringColor, lineWidth: 4)
                    .frame(width: 70, height: 70)
                
                Image(systemName: "ipad.landscape")
                    .font(.system(size: 28))
                    .foregroundColor(.primary)
            }
            
            // Device Name
            Text(device.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            // Model Info
            Text(modelInfo)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 140, height: 120)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Teacher Category Card

struct TeacherCategoryCard: View {
    let name: String
    let color: Color
    let iconName: String
    let count: Int
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .frame(width: 150, height: 80)
                .shadow(radius: 5)
                .overlay(
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            ZStack {
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 15)
                                    .foregroundColor(.white)
                            }
                            .padding([.bottom], 8)
                            
                            Text(name)
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundColor(.secondary)
                        }
                        .padding([.leading], 4)
                        
                        Spacer()
                        
                        VStack {
                            Text("\(count)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                                .padding([.top], 4)
                                .padding([.trailing], 18)
                            Spacer()
                        }
                    }
                    .padding(.leading, 10)
                )
        }
    }
}

// MARK: - Teacher Students View

struct TeacherStudentsView: View {
    let teacherClasses: [TeacherClassInfo]
    
    /// Data provider for real Firebase student profiles
    @State private var dataProvider = StudentAppProfileDataProvider()
    
    /// Selected timeslot for viewing app profiles
    @State private var selectedTimeslot: TimeOfDay = StudentAppProfileDataProvider.currentTimeslot()
    
    /// Current day string for profile lookup
    private var currentDayString: String {
        StudentAppProfileDataProvider.currentDayString()
    }
    
    /// All students flattened from all classes
    private var allStudents: [Student] {
        teacherClasses.flatMap { $0.students }
    }
    
    /// All devices flattened from all classes (for accessing installed apps)
    private var allDevices: [TheDevice] {
        teacherClasses.flatMap { $0.devices }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Timeslot Picker
            timeslotPicker
            
            // Header subtitle
            Text("Student App Profiles for \(currentDayString)")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            // Content based on loading state
            if dataProvider.isLoading {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading student profiles...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if let error = dataProvider.errorMessage {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Error Loading Profiles")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task {
                            await dataProvider.loadProfiles(for: allStudents.map { $0.id })
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else {
                // Students Grid with Profile Cards
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 16)
                    ], spacing: 16) {
                        ForEach(allStudents, id: \.id) { student in
                            StudentProfileCard(
                                student: student,
                                timeslot: selectedTimeslot,
                                dayString: currentDayString,
                                dataProvider: dataProvider,
                                classDevices: allDevices
                            )
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
            }
        }
        .navigationTitle("Students")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Load profiles when view appears
            await dataProvider.loadProfiles(for: allStudents.map { $0.id })
        }
    }
    
    // MARK: - Timeslot Picker
    
    private var timeslotPicker: some View {
        VStack(spacing: 4) {
            Picker("Timeslot", selection: $selectedTimeslot) {
                Text("AM").tag(TimeOfDay.am)
                Text("PM").tag(TimeOfDay.pm)
                Text("Home").tag(TimeOfDay.home)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Timeslot time range label
            Text(timeslotTimeRange)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .background(Color(.systemBackground))
    }
    
    private var timeslotTimeRange: String {
        switch selectedTimeslot {
        case .am:
            return "9:00 AM - 11:59 AM"
        case .pm:
            return "12:00 PM - 4:59 PM"
        case .home:
            return "5:00 PM onwards"
        }
    }
}


// MARK: - Selectable Student Card

struct SelectableStudentCard: View {
    let student: Student
    
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 8) {
                // Student Photo
                AsyncImage(url: student.photo) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 70, height: 70)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.gray)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 3)
                )
                
                // Student Name
                Text(student.firstName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Last Name
                Text(student.lastName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 120, height: 130)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .navigationDestination(isPresented: $showingDetail) {
            StudentDetailView(student: student)
        }
    }
}

// MARK: - Student Detail View (Placeholder)

struct StudentDetailView: View {
    let student: Student
    
    var body: some View {
        VStack(spacing: 24) {
            // Student Photo
            AsyncImage(url: student.photo) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 120, height: 120)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 4)
                        )
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                @unknown default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }
            }
            
            // Student Info
            VStack(spacing: 8) {
                Text(student.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(student.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Username: \(student.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Placeholder for future actions
            VStack(spacing: 16) {
                Text("Student Actions")
                    .font(.headline)
                
                Text("Future actions like viewing app schedules or device assignments will go here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Student Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Teacher Devices View

struct TeacherDevicesView: View {
    let teacherClasses: [TeacherClassInfo]
    
    @State private var selectedDevices: Set<String> = [] // Set of UDIDs
    @State private var isMultiSelectMode = false
    @State private var showMultiDeviceLockSheet = false
    
    /// All devices flattened from all classes
    private var allDevices: [TheDevice] {
        teacherClasses.flatMap { $0.devices }
    }
    
    /// Selected devices as array for multi-device lock
    private var selectedDevicesArray: [TheDevice] {
        allDevices.filter { selectedDevices.contains($0.UDID) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header subtitle
            Text("Choose an iPad to manage")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            // Devices Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150), spacing: 16)
                ], spacing: 16) {
                    ForEach(allDevices, id: \.UDID) { device in
                        SelectableDeviceCard(
                            device: device,
                            isSelected: selectedDevices.contains(device.UDID),
                            isMultiSelectMode: isMultiSelectMode
                        ) {
                            if isMultiSelectMode {
                                // Toggle selection
                                if selectedDevices.contains(device.UDID) {
                                    selectedDevices.remove(device.UDID)
                                } else {
                                    selectedDevices.insert(device.UDID)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))
            
            // Bottom action bar (visible when devices are selected)
            if !selectedDevices.isEmpty {
                selectedDevicesActionBar
            }
        }
        .navigationTitle("Select Device")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isMultiSelectMode.toggle()
                    if !isMultiSelectMode {
                        selectedDevices.removeAll()
                    }
                } label: {
                    Text(isMultiSelectMode ? "Done" : "Select")
                }
            }
        }
        .sheet(isPresented: $showMultiDeviceLockSheet) {
            MultiDeviceAppLockView(devices: selectedDevicesArray)
        }
    }
    
    // MARK: - Selected Devices Action Bar
    
    private var selectedDevicesActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("\(selectedDevices.count) iPad\(selectedDevices.count == 1 ? "" : "s") selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    showMultiDeviceLockSheet = true
                } label: {
                    Text("Lock to App")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Selectable Device Card

struct SelectableDeviceCard: View {
    let device: TheDevice
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: () -> Void
    
    @State private var showingDetail = false
    
    /// Determines the ring color based on the device name
    private var ringColor: Color {
        let lowercasedName = device.name.lowercased()
        if lowercasedName.contains("blue") {
            return .blue
        } else if lowercasedName.contains("silver") || lowercasedName.contains("gray") || lowercasedName.contains("grey") {
            return Color(white: 0.6)
        } else if lowercasedName.contains("gold") {
            return Color.yellow
        } else if lowercasedName.contains("pink") || lowercasedName.contains("rose") {
            return .pink
        } else if lowercasedName.contains("purple") {
            return .purple
        } else if lowercasedName.contains("green") {
            return .green
        } else if lowercasedName.contains("red") {
            return .red
        } else if lowercasedName.contains("orange") {
            return .orange
        } else {
            return .gray
        }
    }
    
    var body: some View {
        Button {
            if isMultiSelectMode {
                onTap()
            } else {
                showingDetail = true
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    // Selection indicator (checkmark circle)
                    if isMultiSelectMode {
                        Circle()
                            .fill(isSelected ? Color.accentColor : Color.clear)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? Color.accentColor : Color.gray, lineWidth: 2)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .opacity(isSelected ? 1 : 0)
                            )
                            .offset(x: 50, y: -35)
                            .zIndex(1)
                    }
                    
                    // Device Icon with colored ring
                    Circle()
                        .stroke(ringColor, lineWidth: 4)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "ipad.landscape")
                        .font(.system(size: 28))
                        .foregroundColor(.primary)
                    
                    // Battery indicator
                    HStack(spacing: 2) {
                        Image(systemName: "battery.100.bolt")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                    .offset(y: 45)
                }
                .frame(height: 90)
                
                // Device Name
                Text(device.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Model Info
                Text("iPad")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 150, height: 150)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .navigationDestination(isPresented: $showingDetail) {
            DeviceAppLockView(device: device)
        }
    }
}

// MARK: - Device Detail View (Placeholder)

struct DeviceDetailView: View {
    let device: TheDevice
    
    var body: some View {
        VStack(spacing: 24) {
            // Device Icon
            ZStack {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 4)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "ipad.landscape")
                    .font(.system(size: 48))
                    .foregroundColor(.primary)
            }
            
            // Device Info
            VStack(spacing: 8) {
                Text(device.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Serial: \(device.serialNumber)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("UDID: \(device.UDID)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Actions
            VStack(spacing: 16) {
                Text("Device Actions")
                    .font(.headline)
                
                Button {
                    // TODO: Lock to app
                } label: {
                    Label("Lock to App", systemImage: "lock.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button {
                    // TODO: Unlock device
                } label: {
                    Label("Unlock Device", systemImage: "lock.open.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Class Selector Sheet

struct ClassSelectorSheet: View {
    let classes: [TeacherClassInfo]
    @Binding var selectedClass: TeacherClassInfo?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(classes) { classInfo in
                    Button {
                        selectedClass = classInfo
                        isPresented = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(classInfo.className)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                HStack(spacing: 12) {
                                    Label("\(classInfo.students.count) students", systemImage: "person.2.fill")
                                    Label("\(classInfo.devices.count) devices", systemImage: "ipad.landscape")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedClass?.id == classInfo.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title2)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Switch Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
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

