//
//  ClassEditorView.swift
//  appi4Manager
//
//  Editor view for creating and editing a class.
//  Handles name/description editing, teacher assignment, and device management.
//

import SwiftUI

// MARK: - ClassEditorView

/// Editor for creating or editing a school class.
/// - Edit class name and description
/// - Manage assigned teachers
/// - Manage assigned devices via asset tag
struct ClassEditorView: View {
    
    // MARK: - Environment & State
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var devicesViewModel: DevicesViewModel
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var teacherItems: TeacherItems
    
    @State var schoolClass: SchoolClass
    @State var isNew: Bool
    var onSave: (() -> Void)?
    
    // Form state
    @State private var className: String = ""
    @State private var classDescription: String = ""
    
    // Original values for dirty state tracking
    @State private var originalClassName: String = ""
    @State private var originalDescription: String = ""
    
    // Loading/Error state
    @State private var isSaving = false
    @State private var isLoadingData = false
    @State private var hasError = false
    @State private var errorMessage: String?
    
    // Device management
    @State private var assignedDevices: [TheDevice] = []
    @State private var showDevicePicker = false
    @State private var deviceToUnassign: TheDevice?
    @State private var showUnassignConfirmation = false
    
    // Teacher management
    @State private var assignedTeachers: [Student] = []  // API returns teachers as Student type
    @State private var showTeacherPicker = false
    @State private var showCreateTeacher = false
    
    // Delete confirmation
    @State private var showDeleteConfirmation = false
    
    // Success message after class creation
    @State private var showSuccessMessage = false
    
    // MARK: - Computed Properties
    
    /// Whether name or description have unsaved changes
    private var hasUnsavedChanges: Bool {
        className != originalClassName || classDescription != originalDescription
    }
    
    /// Whether this class is "active" (has at least one teacher AND one device assigned)
    private var isClassActive: Bool {
        !assignedTeachers.isEmpty && !assignedDevices.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        Form {
            // Success message section (shown after class creation)
            if showSuccessMessage {
                successMessageSection
            }
            
            // Section 1: Class Details
            classDetailsSection
            
            // Section 2: Teachers (only after class is created)
            if !isNew {
                teachersSection
            }
            
            // Section 3: Devices (only after class is created)
            if !isNew {
                devicesSection
            }
        }
        // Delete button pinned to bottom of sheet (only for existing classes)
        .safeAreaInset(edge: .bottom) {
            if !isNew {
                deleteButtonView
            }
        }
        .navigationTitle(isNew ? "New Class" : "Edit Class")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                // Only show Cancel button when creating a new class
                if isNew {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
            
            // Only show Save button when there are changes to save (or when creating)
            if isNew || hasUnsavedChanges {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Create" : "Save") {
                        Task {
                            await saveClass()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled((isNew && className.isEmpty) || isSaving)
                }
            }
        }
        .overlay {
            if isSaving || isLoadingData {
                loadingOverlay
            }
        }
        .sheet(isPresented: $showDevicePicker) {
            NavigationStack {
                DevicePickerSheet(
                    classGroupId: schoolClass.userGroupId,
                    onDevicesSelected: { selectedDevices in
                        Task {
                            await assignDevices(selectedDevices)
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showCreateTeacher) {
            NavigationStack {
                TeacherCreationSheet(
                    locationId: teacherItems.currentLocation.id,
                    classGroupId: schoolClass.userGroupId,
                    onTeacherCreated: { newTeacher in
                        // Convert User to Student for display and assign to class
                        let teacherAsStudent = Student(
                            id: newTeacher.id,
                            name: "\(newTeacher.firstName) \(newTeacher.lastName)",
                            email: newTeacher.email,
                            username: newTeacher.username,
                            firstName: newTeacher.firstName,
                            lastName: newTeacher.lastName,
                            photo: URL(string: "https://via.placeholder.com/100")!
                        )
                        assignedTeachers.append(teacherAsStudent)
                        
                        // Assign new teacher to the class
                        Task {
                            await assignTeachersToClass([newTeacher.id])
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showTeacherPicker) {
            NavigationStack {
                TeacherPickerSheet(
                    classUUID: schoolClass.uuid,
                    currentlyAssignedTeacherIds: Set(assignedTeachers.map { $0.id }),
                    onTeachersSelected: { selectedTeachers in
                        // Convert User to Student and add to list
                        for teacher in selectedTeachers {
                            let teacherAsStudent = Student(
                                id: teacher.id,
                                name: "\(teacher.firstName) \(teacher.lastName)",
                                email: teacher.email,
                                username: teacher.username,
                                firstName: teacher.firstName,
                                lastName: teacher.lastName,
                                photo: URL(string: "https://via.placeholder.com/100")!
                            )
                            assignedTeachers.append(teacherAsStudent)
                        }
                        
                        // Assign selected teachers to the class
                        Task {
                            await assignTeachersToClass(selectedTeachers.map { $0.id })
                        }
                    }
                )
            }
        }
        .alert("Error", isPresented: $hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .onAppear {
            setupInitialValues()
        }
        .task {
            if !isNew {
                await loadClassData()
            }
        }
    }
    
    // MARK: - Sections
    
    /// Success message shown after class creation to guide user to next steps
    private var successMessageSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Class Created Successfully!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
                
                Text("Now assign a teacher and device to activate this class.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var classDetailsSection: some View {
        Section {
            TextField("Class Name", text: $className)
                .textContentType(.organizationName)
            
            TextField("Description", text: $classDescription, axis: .vertical)
                .lineLimit(3...6)
            
            // Active/Inactive status indicator (only for existing classes)
            // Styled with background tint to visually distinguish from editable fields
            if !isNew {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: isClassActive ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundStyle(isClassActive ? .green : .orange)
                        Text("Status")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(isClassActive ? "Active" : "Inactive")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(isClassActive ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
                            .foregroundStyle(isClassActive ? .green : .secondary)
                            .clipShape(.capsule)
                    }
                    
                    // Activation guidance directly below status (when inactive)
                    if !isClassActive {
                        Text("Assign at least one teacher and one device to activate this class.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isClassActive ? Color.green.opacity(0.04) : Color.orange.opacity(0.04))
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        } header: {
            Text("Class Details")
        }
    }
    
    private var teachersSection: some View {
        Section {
            if isNew {
                // Class must be created before teachers can be assigned
                Text("Create the class first to assign teachers.")
                    .foregroundStyle(.secondary)
                    .italic()
            } else if isLoadingData {
                HStack {
                    ProgressView()
                    Text("Loading teachers...")
                        .foregroundStyle(.secondary)
                }
            } else if assignedTeachers.isEmpty {
                Text("No teachers assigned")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ForEach(assignedTeachers, id: \.id) { teacher in
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.tint)
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text("\(teacher.firstName) \(teacher.lastName)")
                                .font(.body)
                            Text(teacher.username)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                await removeTeacher(teacher)
                            }
                        } label: {
                            Label("Remove", systemImage: "minus.circle")
                        }
                    }
                }
            }
            
            // Only show add buttons when class exists on server
            if !isNew {
                // Button to select existing teachers from teacher group
                Button {
                    showTeacherPicker = true
                } label: {
                    Label("Assign Existing Teacher", systemImage: "person.fill.badge.plus")
                }
                
                // Button to create a new teacher
                Button {
                    showCreateTeacher = true
                } label: {
                    Label("Create New Teacher", systemImage: "person.badge.plus")
                }
            }
        } header: {
            Text("Assigned Teachers (\(assignedTeachers.count))")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if isNew {
                    Text("Tap 'Create' to save the class, then you can assign teachers.")
                } else if assignedTeachers.isEmpty {
                    Text("Teachers assigned to this class can manage students.")
                    + Text(" · Required to activate class")
                        .foregroundColor(.orange)
                } else {
                    Text("Swipe left on a teacher to remove them from this class.")
                }
            }
            .padding(.bottom, 12)
        }
    }
    
    private var devicesSection: some View {
        Section {
            if isNew {
                // Class must be created before devices can be assigned
                Text("Create the class first to assign devices.")
                    .foregroundStyle(.secondary)
                    .italic()
            } else if isLoadingData {
                HStack {
                    ProgressView()
                    Text("Loading devices...")
                        .foregroundStyle(.secondary)
                }
            } else if assignedDevices.isEmpty {
                Text("No devices assigned")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ForEach(assignedDevices, id: \.UDID) { device in
                    DeviceRowWithUnassign(
                        device: device,
                        onUnassign: {
                            deviceToUnassign = device
                            showUnassignConfirmation = true
                        }
                    )
                }
            }
            
            // Only show add button when class exists on server
            if !isNew {
                Button {
                    showDevicePicker = true
                } label: {
                    Label("Assign Device", systemImage: "rectangle.badge.plus")
                }
            }
        } header: {
            Text("Assigned Devices (\(assignedDevices.count))")
        } footer: {
            if isNew {
                Text("Tap 'Create' to save the class, then you can assign devices.")
            } else if assignedDevices.isEmpty {
                Text("Devices assigned to this class can be used by its students.")
                + Text(" Required to activate class")
                    .foregroundColor(.orange)
            } else {
                Text("Tap the remove button or swipe left to unassign a device from this class.")
            }
        }
        .confirmationDialog(
            "Unassign Device",
            isPresented: $showUnassignConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unassign", role: .destructive) {
                if let device = deviceToUnassign {
                    Task {
                        await unassignDevice(device)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                deviceToUnassign = nil
            }
        } message: {
            if let device = deviceToUnassign {
                Text("Unassign \"\(device.name)\" from this class? The device will become available for other classes.")
            }
        }
    }
    
    /// Delete button that floats at the bottom of the sheet
    private var deleteButtonView: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Spacer()
                Label("Delete Class", systemImage: "trash")
                Spacer()
            }
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .confirmationDialog(
            "Delete Class",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Class", role: .destructive) {
                Task {
                    await deleteClass()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(schoolClass.name)\"? This action cannot be undone.")
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text(isSaving ? (isNew ? "Creating class..." : "Saving...") : "Loading...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Setup
    
    private func setupInitialValues() {
        className = schoolClass.name
        classDescription = schoolClass.description
        
        // Store original values for dirty state tracking
        originalClassName = schoolClass.name
        originalDescription = schoolClass.description
        
        if isNew {
            // Set location for new classes
            schoolClass.locationId = teacherItems.currentLocation.id
        }
    }
    
    // MARK: - Data Loading
    
    private func loadClassData() async {
        await MainActor.run { isLoadingData = true }
        defer { Task { await MainActor.run { isLoadingData = false } } }
        
        // Load teachers and devices in parallel
        async let teachersTask: () = loadAssignedTeachers()
        async let devicesTask: () = loadAssignedDevices()
        
        _ = await (teachersTask, devicesTask)
    }
    
    private func loadAssignedTeachers() async {
        do {
            let response: ClassDetailResponse = try await ApiManager.shared.getData(
                from: .getStudents(uuid: schoolClass.uuid)
            )
            await MainActor.run {
                // Filter out internal/hidden teachers (names starting with **)
                assignedTeachers = response.class.teachers.filter { teacher in
                    !teacher.firstName.hasPrefix("**")
                }
            }
            
            #if DEBUG
            print("👩‍🏫 Loaded \(response.class.teachers.count) teachers for class")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to load teachers: \(error)")
            #endif
        }
    }
    
    private func loadAssignedDevices() async {
        do {
            let response: DeviceListResponse = try await ApiManager.shared.getData(
                from: .getDevices(assettag: String(schoolClass.userGroupId))
            )
            await MainActor.run {
                assignedDevices = response.devices
            }
            
            #if DEBUG
            print("📱 Loaded \(response.devices.count) assigned devices for class")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to load devices: \(error)")
            #endif
        }
    }
    
    // MARK: - Save Actions
    
    private func saveClass() async {
        await MainActor.run { isSaving = true }
        defer { Task { await MainActor.run { isSaving = false } } }
        
        // Update class object
        schoolClass.name = className
        schoolClass.description = classDescription
        
        do {
            if isNew {
                // Create the class
                let newUUID = try await classesViewModel.addClass(schoolClass: schoolClass)
                schoolClass.uuid = newUUID
                
                // Get the created class to retrieve userGroupId
                try await classesViewModel.loadData2()
                if let createdClass = classesViewModel.schoolClasses.first(where: { $0.uuid == newUUID }) {
                    schoolClass = createdClass
                }
                
                // Auto-create dummy student
                await createDummyStudent()
                
                #if DEBUG
                print("✅ Created class: \(schoolClass.name) with UUID: \(schoolClass.uuid)")
                #endif
                
                // Switch to edit mode to allow adding teachers & devices
                await MainActor.run {
                    isNew = false
                    // Update original values so button shows "Done" not "Save"
                    originalClassName = className
                    originalDescription = classDescription
                    // Show success message to confirm creation and guide user
                    showSuccessMessage = true
                }
                
                // Load devices to show the section
                await loadClassData()
                
            } else {
                // Update existing class
                try await classesViewModel.updateSchoolClass2(schoolClass: schoolClass)
                
                #if DEBUG
                print("✅ Updated class: \(schoolClass.name)")
                #endif
                
                // Stay in sheet, update original values so Save button disappears
                await MainActor.run {
                    originalClassName = className
                    originalDescription = classDescription
                }
                onSave?()
            }
            
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = error.localizedDescription
            }
            #if DEBUG
            print("❌ Failed to save class: \(error)")
            #endif
        }
    }
    
    private func createDummyStudent() async {
        // Generate unique username
        let username = String(Array(UUID().uuidString.split(separator: "-")).last!)
        
        // Create dummy user
        var newUser = User.makeDefault()
        newUser.username = username
        newUser.firstName = "dummy"
        newUser.lastName = schoolClass.uuid
        newUser.locationId = schoolClass.locationId
        newUser.groupIds = [schoolClass.userGroupId]
        
        do {
            let _: AddAUserResponse = try await ApiManager.shared.getData(
                from: .addUsr(user: newUser)
            )
            
            #if DEBUG
            print("✅ Created dummy student for class with lastName: \(schoolClass.uuid)")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to create dummy student: \(error)")
            #endif
        }
    }
    
    // MARK: - Delete Action
    
    private func deleteClass() async {
        await MainActor.run { isSaving = true }
        defer { Task { await MainActor.run { isSaving = false } } }
        
        do {
            try await classesViewModel.deleteClass(schoolClass, devicesViewModel: devicesViewModel)
            onSave?()
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = "Failed to delete class: \(error.localizedDescription)"
            }
            #if DEBUG
            print("❌ Failed to delete class: \(error)")
            #endif
        }
    }
    
    // MARK: - Teacher Actions
    
    private func assignTeachersToClass(_ teacherIds: [Int]) async {
        guard !teacherIds.isEmpty else { return }
        
        do {
            // Get current students to preserve them
            let currentStudentIds = assignedTeachers.map { $0.id }
            let allTeacherIds = Set(currentStudentIds + teacherIds).map { $0 }
            
            _ = try await ApiManager.shared.getDataNoDecode(
                from: .assignToClass(uuid: schoolClass.uuid, students: [], teachers: allTeacherIds)
            )
            
            // Sync classesViewModel to update teacherCount for list view
            await MainActor.run {
                if let index = classesViewModel.schoolClasses.firstIndex(where: { $0.uuid == schoolClass.uuid }) {
                    classesViewModel.schoolClasses[index].teacherCount = allTeacherIds.count
                }
            }
            
            #if DEBUG
            print("✅ Assigned \(teacherIds.count) teacher(s) to class")
            #endif
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = "Failed to assign teacher(s): \(error.localizedDescription)"
            }
            #if DEBUG
            print("❌ Failed to assign teachers: \(error)")
            #endif
        }
    }
    
    private func removeTeacher(_ teacher: Student) async {
        do {
            // 1. Fetch the teacher's current data
            let userResponse: UserDetailResponse = try await ApiManager.shared.getData(
                from: .getaUser(id: teacher.id)
            )
            
            // 2. Remove the class's userGroupId from their teacherGroups
            var updatedTeacherGroups = userResponse.user.teacherGroups.removingDuplicates()
            
            guard let idx = updatedTeacherGroups.firstIndex(of: schoolClass.userGroupId) else {
                #if DEBUG
                print("⚠️ Teacher \(teacher.id) not in group \(schoolClass.userGroupId), skipping")
                #endif
                return
            }
            updatedTeacherGroups.remove(at: idx)
            
            // 3. Update the user with the modified teacherGroups
            _ = try await ApiManager.shared.getDataNoDecode(
                from: .updateaUser(
                    id: userResponse.user.id,
                    username: userResponse.user.username,
                    password: AppConstants.defaultUserPwd,
                    email: userResponse.user.email,
                    firstName: userResponse.user.firstName,
                    lastName: userResponse.user.lastName,
                    notes: userResponse.user.notes,
                    locationId: userResponse.user.locationId,
                    groupIds: userResponse.user.groupIds,
                    teacherGroups: updatedTeacherGroups
                )
            )
            
            await MainActor.run {
                assignedTeachers.removeAll { $0.id == teacher.id }
                
                // Sync classesViewModel to update teacherCount for list view
                if let index = classesViewModel.schoolClasses.firstIndex(where: { $0.uuid == schoolClass.uuid }) {
                    classesViewModel.schoolClasses[index].teacherCount = assignedTeachers.count
                }
            }
            
            #if DEBUG
            print("✅ Removed teacher \(teacher.firstName) \(teacher.lastName) from class")
            #endif
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = "Failed to remove teacher: \(error.localizedDescription)"
            }
            #if DEBUG
            print("❌ Failed to remove teacher: \(error)")
            #endif
        }
    }
    
    // MARK: - Device Actions
    
    private func assignDevices(_ devices: [TheDevice]) async {
        for device in devices {
            do {
                _ = try await ApiManager.shared.getDataNoDecode(
                    from: .updateDevice(uuid: device.UDID, assetTag: String(schoolClass.userGroupId))
                )
                
                await MainActor.run {
                    assignedDevices.append(device)
                    
                    // Sync devicesViewModel to keep it in sync
                    if let index = devicesViewModel.devices.firstIndex(where: { $0.UDID == device.UDID }) {
                        devicesViewModel.devices[index].assetTag = String(schoolClass.userGroupId)
                    }
                }
                do {
                    try await DeviceMockStudentService.getOrCreate(
                        deviceUDID: device.UDID,
                        classUUID: schoolClass.uuid,
                        locationId: schoolClass.locationId,
                        classGroupId: schoolClass.userGroupId
                    )
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to create device mock student for \(device.name): \(error)")
                    #endif
                }
                #if DEBUG
                print("✅ Assigned device \(device.name) to class")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to assign device \(device.name): \(error)")
                #endif
            }
        }
    }
    
    private func unassignDevice(_ device: TheDevice) async {
        await DeviceMockStudentService.deleteIfExists(
            deviceUDID: device.UDID,
            classGroupId: schoolClass.userGroupId
        )
        do {
            _ = try await ApiManager.shared.getDataNoDecode(
                from: .updateDevice(uuid: device.UDID, assetTag: "None")
            )
            
            await MainActor.run {
                assignedDevices.removeAll { $0.UDID == device.UDID }
                deviceToUnassign = nil
                
                // Sync devicesViewModel to keep it in sync
                if let index = devicesViewModel.devices.firstIndex(where: { $0.UDID == device.UDID }) {
                    devicesViewModel.devices[index].assetTag = "None"
                }
            }
            
            #if DEBUG
            print("✅ Unassigned device \(device.name) from class")
            #endif
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = "Failed to unassign device: \(error.localizedDescription)"
            }
            #if DEBUG
            print("❌ Failed to unassign device: \(error)")
            #endif
        }
    }
}

// MARK: - DeviceRowWithUnassign

/// Device row with visible unassign button
private struct DeviceRowWithUnassign: View {
    let device: TheDevice
    var onUnassign: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "ipad.landscape")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(device.serialNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Battery indicator
            HStack(spacing: 4) {
                Image(systemName: batteryIcon)
                    .foregroundColor(batteryColor)
                Text("\(Int(device.batteryLevel * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Visible unassign button
            Button(role: .destructive) {
                onUnassign?()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onUnassign?()
            } label: {
                Label("Unassign", systemImage: "minus.circle")
            }
        }
    }
    
    private var batteryIcon: String {
        let level = device.batteryLevel
        switch level {
        case 0..<0.2: return "battery.0"
        case 0.2..<0.5: return "battery.25"
        case 0.5..<0.75: return "battery.50"
        case 0.75..<1.0: return "battery.75"
        default: return "battery.100"
        }
    }
    
    private var batteryColor: Color {
        device.batteryLevel < 0.2 ? .red : .green
    }
}

// MARK: - Preview

#Preview("New Class") {
    NavigationStack {
        ClassEditorView(
            schoolClass: SchoolClass.makeDefault(),
            isNew: true
        )
        .environmentObject(ClassesViewModel())
        .environmentObject(DevicesViewModel())
        .environmentObject(UsersViewModel())
        .environmentObject(TeacherItems())
    }
}

#Preview("Edit Class") {
    NavigationStack {
        ClassEditorView(
            schoolClass: SchoolClass(
                uuid: "test-uuid",
                name: "Grade 3A",
                description: "Mrs. Smith's class",
                locationId: 1,
                userGroupId: 100,
                teacherCount: 1
            ),
            isNew: false
        )
        .environmentObject(ClassesViewModel())
        .environmentObject(DevicesViewModel())
        .environmentObject(UsersViewModel())
        .environmentObject(TeacherItems())
    }
}

