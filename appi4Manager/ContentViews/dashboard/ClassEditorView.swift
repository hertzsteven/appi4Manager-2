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
    
    // MARK: - Body
    
    var body: some View {
        Form {
            // Section 1: Class Details
            classDetailsSection
            
            // Section 2: Teachers
            teachersSection
            
            // Section 3: Devices
            devicesSection
            
            // Section 4: Delete (only for existing classes)
            if !isNew {
                deleteSection
            }
        }
        .navigationTitle(isNew ? "New Class" : "Edit Class")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .disabled(isSaving)
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button(isNew ? "Create" : "Save") {
                    Task {
                        await saveClass()
                    }
                }
                .fontWeight(.semibold)
                .disabled(className.isEmpty || isSaving)
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
                        // Convert User to Student for display
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
                    }
                )
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
    
    private var classDetailsSection: some View {
        Section {
            TextField("Class Name", text: $className)
                .textContentType(.organizationName)
            
            TextField("Description", text: $classDescription, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Class Details")
        } footer: {
            if isNew {
                Text("A dummy student will be automatically created for device management purposes.")
            }
        }
    }
    
    private var teachersSection: some View {
        Section {
            if isLoadingData {
                HStack {
                    ProgressView()
                    Text("Loading teachers...")
                        .foregroundColor(.secondary)
                }
            } else if assignedTeachers.isEmpty {
                Text("No teachers assigned")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(assignedTeachers, id: \.id) { teacher in
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text("\(teacher.firstName) \(teacher.lastName)")
                                .font(.body)
                            Text(teacher.username)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Button {
                showCreateTeacher = true
            } label: {
                Label("Create New Teacher", systemImage: "person.badge.plus")
            }
        } header: {
            Text("Assigned Teachers (\(assignedTeachers.count))")
        } footer: {
            Text("Teachers assigned to this class can manage students and devices.")
        }
    }
    
    private var devicesSection: some View {
        Section {
            if isLoadingData {
                HStack {
                    ProgressView()
                    Text("Loading devices...")
                        .foregroundColor(.secondary)
                }
            } else if assignedDevices.isEmpty {
                Text("No devices assigned")
                    .foregroundColor(.secondary)
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
            
            Button {
                showDevicePicker = true
            } label: {
                Label("Add Device", systemImage: "plus.circle")
            }
        } header: {
            Text("Assigned Devices (\(assignedDevices.count))")
        } footer: {
            if !isNew {
                Text("Tap the remove button or swipe left to unassign a device from this class.")
            }
        }
    }
    
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Label("Delete Class", systemImage: "trash")
                    Spacer()
                }
            }
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
                assignedTeachers = response.class.teachers
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
                }
                
                // Load devices to show the section
                await loadClassData()
                
            } else {
                // Update existing class
                try await classesViewModel.updateSchoolClass2(schoolClass: schoolClass)
                
                #if DEBUG
                print("✅ Updated class: \(schoolClass.name)")
                #endif
                
                onSave?()
                await MainActor.run { dismiss() }
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
            try await ApiManager.shared.getDataNoDecode(from: .deleteaClass(uuid: schoolClass.uuid))
            classesViewModel.delete(schoolClass)
            
            #if DEBUG
            print("✅ Deleted class: \(schoolClass.name)")
            #endif
            
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
    
    // MARK: - Device Actions
    
    private func assignDevices(_ devices: [TheDevice]) async {
        for device in devices {
            do {
                _ = try await ApiManager.shared.getDataNoDecode(
                    from: .updateDevice(uuid: device.UDID, assetTag: String(schoolClass.userGroupId))
                )
                
                await MainActor.run {
                    assignedDevices.append(device)
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
        do {
            _ = try await ApiManager.shared.getDataNoDecode(
                from: .updateDevice(uuid: device.UDID, assetTag: "None")
            )
            
            await MainActor.run {
                assignedDevices.removeAll { $0.UDID == device.UDID }
                deviceToUnassign = nil
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
                userGroupId: 100
            ),
            isNew: false
        )
        .environmentObject(ClassesViewModel())
        .environmentObject(DevicesViewModel())
        .environmentObject(UsersViewModel())
        .environmentObject(TeacherItems())
    }
}
