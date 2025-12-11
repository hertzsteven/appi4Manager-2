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
    @State private var selectedClass: TeacherClassInfo?
    
    var body: some View {
        NavigationStack {
            Group {
                if !authManager.isAuthenticated {
                    // Not logged in - show login prompt
                    loginPromptView
                } else if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if teacherClasses.isEmpty {
                    emptyClassesView
                } else {
                    // Main content - show classes with students and devices
                    classesContentView
                }
            }
            .navigationTitle("Teacher Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
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
    
    // MARK: - Classes Content View (now shows category tiles)
    
    private var classesContentView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 20) {
                // Students Category
                NavigationLink(destination: TeacherStudentsView(teacherClasses: teacherClasses)) {
                    TeacherCategoryCard(
                        name: "Students",
                        color: .blue,
                        iconName: "person.crop.square.fill",
                        count: totalStudents
                    )
                }
                .buttonStyle(.plain)
                
                // Devices Category
                NavigationLink(destination: TeacherDevicesView(teacherClasses: teacherClasses)) {
                    TeacherCategoryCard(
                        name: "Devices",
                        color: .green,
                        iconName: "ipad.landscape",
                        count: totalDevices
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        }
        .background(Color(.systemGray5))
        .refreshable {
            await loadTeacherData()
        }
    }
    
    // MARK: - Computed Properties for Counts
    
    private var totalStudents: Int {
        teacherClasses.reduce(0) { $0 + $1.students.count }
    }
    
    private var totalDevices: Int {
        teacherClasses.reduce(0) { $0 + $1.devices.count }
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
                
                // Fetch devices for this class
                var devices: [TheDevice] = []
                do {
                    let deviceResponse: DeviceListResponse = try await ApiManager.shared.getData(
                        from: .getDevices(assettag: String(schoolClass.userGroupId))
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
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load class info: \(error.localizedDescription)"
                isLoading = false
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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(teacherClasses) { classInfo in
                    if !classInfo.students.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // Class Header
                            HStack {
                                Image(systemName: "book.closed.fill")
                                    .foregroundColor(.accentColor)
                                Text(classInfo.className)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(classInfo.students.count) students")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            // Students Grid
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 100), spacing: 16)
                            ], spacing: 16) {
                                ForEach(classInfo.students, id: \.id) { student in
                                    StudentCard(student: student)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Students")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Teacher Devices View

struct TeacherDevicesView: View {
    let teacherClasses: [TeacherClassInfo]
    
    @State private var selectedDevices: Set<String> = [] // Set of UDIDs
    @State private var isMultiSelectMode = false
    
    /// All devices flattened from all classes
    private var allDevices: [TheDevice] {
        teacherClasses.flatMap { $0.devices }
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
                    // TODO: Navigate to lock app screen
                    print("Lock \(selectedDevices.count) devices")
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
            DeviceDetailView(device: device)
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

#Preview {
    TeacherDashboardView()
        .environment(AuthenticationManager())
        .environmentObject(TeacherItems())
}
