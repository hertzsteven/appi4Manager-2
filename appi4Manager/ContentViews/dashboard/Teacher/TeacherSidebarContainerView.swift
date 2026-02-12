//
//  TeacherSidebarContainerView.swift
//  appi4Manager
//
//  Container view that combines the sidebar navigation with the main content area.
//  Switches content based on the selected sidebar section.
//

import SwiftUI

/// Container view that displays the sidebar alongside the main content area.
/// Content switches based on which sidebar section is selected.
struct TeacherSidebarContainerView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @EnvironmentObject var teacherItems: TeacherItems
    
    /// Currently selected sidebar section
    @State private var selectedSection: SidebarSection = .home
    
    /// Teacher class data, shared across sections
    @State private var teacherClasses: [TeacherClassInfo] = []
    @State private var isLoading = false
    @State private var hasAttemptedLoad = false
    @State private var errorMessage: String?
    // NOTE: selectedClass is shared via teacherItems.selectedClass for sync with dashboard
    
    /// The currently active class - uses shared state from teacherItems
    private var activeClass: TeacherClassInfo? {
        teacherItems.selectedClass ?? teacherClasses.first
    }
    
    /// Filtered students (excludes dummy students)
    private var filteredStudents: [Student] {
        guard let activeClass = activeClass else { return [] }
        return activeClass.students.filter { $0.lastName != activeClass.classUUID }
    }
    
    /// All device apps from the active class
    private var deviceApps: [DeviceApp] {
        activeClass?.devices.flatMap { $0.apps ?? [] } ?? []
    }
    
    /// Classes that have devices assigned
    private var classesWithDevices: [TeacherClassInfo] {
        teacherClasses.filter { !$0.devices.isEmpty }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            TeacherSidebarView(selectedSection: $selectedSection)
            
            // Divider between sidebar and content
            Divider()
            
            // Main content area
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    // MARK: - Content View Switching
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedSection {
        case .home:
            // Use the existing TeacherDashboardView for Live Class
            TeacherDashboardView()
            
        case .activity:
            NavigationStack {
                if !authManager.isAuthenticated {
                    loginPromptView
                } else if isLoading || !hasAttemptedLoad {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if activeClass != nil {
                    StudentActivityReportView(
                        students: filteredStudents,
                        deviceApps: deviceApps,
                        activeClass: activeClass,
                        classesWithDevices: classesWithDevices
                    )
                } else {
                    noClassView
                }
            }
            
        case .students:
            NavigationStack {
                if !authManager.isAuthenticated {
                    loginPromptView
                } else if isLoading || !hasAttemptedLoad {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if let activeClass = activeClass {
                    // Student management for the active class (add/edit/delete)
                    TeacherStudentManagementSheet(
                        classInfo: activeClass,
                        classesWithDevices: classesWithDevices,
                        onStudentChanged: {
                            // Refresh teacher data when a student is added/edited/deleted
                            Task {
                                await loadTeacherData()
                            }
                        }
                    )
                } else {
                    noClassView
                }
            }
            
        case .devices:
            NavigationStack {
                if !authManager.isAuthenticated {
                    loginPromptView
                } else if isLoading || !hasAttemptedLoad {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if let activeClass = activeClass {
                    // Show devices for the active class only (same as old toolbar button)
                    TeacherDevicesView(
                        teacherClasses: [activeClass],
                        classesWithDevices: classesWithDevices
                    )
                } else {
                    noClassView
                }
            }
            
        case .calendar:
            NavigationStack {
                if !authManager.isAuthenticated {
                    loginPromptView
                } else if isLoading || !hasAttemptedLoad {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if let activeClass = activeClass {
                    // Planning view for the active class (same as old toolbar button)
                    PlanningSheet(
                        students: filteredStudents,
                        devices: activeClass.devices,
                        locationId: activeClass.locationId,
                        activeClass: activeClass,
                        classesWithDevices: classesWithDevices,
                        dataProvider: StudentAppProfileDataProvider(),
                        bulkSetupDataProvider: StudentAppProfileDataProvider(),
                        onDismiss: nil  // No dismiss action needed for embedded view
                    )
                } else {
                    noClassView
                }
            }
            
        case .setup:
            NavigationStack {
                TeacherSetupView(
                    activeClass: activeClass,
                    classesWithDevices: classesWithDevices
                )
            }
        }
    }
    
    // MARK: - State Views
    
    private var loginPromptView: some View {
        ContentUnavailableView(
            "Sign In Required",
            systemImage: "person.crop.circle.badge.questionmark",
            description: Text("Please sign in to view this section.")
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .foregroundStyle(.secondary)
        }
    }
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") {
                Task {
                    await loadTeacherData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var noClassView: some View {
        ContentUnavailableView(
            "No Classes",
            systemImage: "person.3.fill",
            description: Text("No classes found for your account.")
        )
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
                
                // Fetch devices for this class
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
                    userGroupName: groupName,
                    locationId: schoolClass.locationId
                )
                info.students = students
                info.devices = devices
                
                classInfos.append(info)
            }
            
            classInfos.sort { $0.className < $1.className }
            
            await MainActor.run {
                teacherClasses = classInfos
                
                // Keep selectedClass in sync with freshly fetched data
                if let current = teacherItems.selectedClass {
                    teacherItems.selectedClass = classInfos.first(where: { $0.id == current.id }) ?? classInfos.first
                } else {
                    teacherItems.selectedClass = classInfos.first
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
}

#Preview {
    TeacherSidebarContainerView()
        .environment(AuthenticationManager())
        .environmentObject(TeacherItems())
}
