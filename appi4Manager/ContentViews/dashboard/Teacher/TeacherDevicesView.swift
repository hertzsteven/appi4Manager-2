//
//  TeacherDevicesView.swift
//  appi4Manager
//
//  Device management view for the teacher dashboard sidebar.
//  Displays device cards in a grid with multi-select and inline device actions
//  (Lock, Unlock, Restart) via a bottom action bar — matching the Live Class
//  selection UX pattern.
//

import SwiftUI

// MARK: - Teacher Devices View

/// Displays devices for the active class with a toolbar matching the Live Class screen.
///
/// **Header:** Select button (leading), static class name with stats (center),
/// greeting + settings gear (trailing).
///
/// **Selection:** Tap "Select" to enter multi-select mode. A bottom action bar
/// with Lock, Unlock, and Restart buttons appears, matching the student selection pattern.
///
/// **Single tap:** Opens `DeviceAppLockView` for the tapped device.
struct TeacherDevicesView: View {
    // MARK: - Environment & Dependencies
    
    @Environment(AuthenticationManager.self) private var authManager
    
    /// The classes this teacher manages — typically a single active class from the sidebar container
    let teacherClasses: [TeacherClassInfo]
    
    // MARK: - Selection State
    
    /// UDIDs of currently selected devices
    @State private var selectedDevices: Set<String> = []
    
    /// Whether multi-select mode is active
    @State private var isMultiSelectMode = false
    
    // MARK: - Device Actions State
    
    /// Manages device lock/unlock/restart API calls
    @State private var actionsManager = DeviceActionsManager()
    
    /// Controls the result alert after an action completes
    @State private var showActionAlert = false
    
    /// Title for the action result alert
    @State private var actionAlertTitle = ""
    
    /// Message for the action result alert
    @State private var actionAlertMessage = ""
    
    /// Controls the restart confirmation dialog
    @State private var showRestartConfirmation = false
    
    // MARK: - Restriction Profiles State
    
    /// Maps studentId -> hasActiveRestrictions for lock status display
    @State private var restrictionStatus: [Int: Bool] = [:]
    
    /// True while fetching restriction profiles from the server
    @State private var isLoadingProfiles = false
    
    // MARK: - Computed Properties
    
    /// The active class (first in the array, since the container passes a single-element array)
    private var activeClass: TeacherClassInfo? {
        teacherClasses.first
    }
    
    /// All devices flattened from all classes
    private var allDevices: [TheDevice] {
        teacherClasses.flatMap { $0.devices }
    }
    
    /// Selected devices resolved to their model objects
    private var selectedDevicesArray: [TheDevice] {
        allDevices.filter { selectedDevices.contains($0.UDID) }
    }
    
    /// Selected devices that have valid owners (required for lock/unlock)
    private var selectedDevicesWithOwners: [TheDevice] {
        selectedDevicesArray.filter { $0.owner != nil }
    }
    
    /// All students from all classes (for owner assignment in detail views)
    private var allStudents: [Student] {
        teacherClasses.flatMap { $0.students }
    }
    
    /// Filtered student count excluding dummy students (whose lastName matches the class UUID)
    private var filteredStudentCount: Int {
        guard let activeClass else { return 0 }
        return activeClass.students.filter { $0.lastName != activeClass.classUUID }.count
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Loading indicator for restriction profiles
                if isLoadingProfiles {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading device status...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // Devices grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 16)
                    ], spacing: 16) {
                        ForEach(allDevices, id: \.UDID) { device in
                            SelectableDeviceCard(
                                device: device,
                                isSelected: selectedDevices.contains(device.UDID),
                                isMultiSelectMode: isMultiSelectMode,
                                isLocked: isDeviceLocked(device),
                                allStudents: allStudents,
                                onRefreshNeeded: {
                                    await loadRestrictionProfiles()
                                }
                            ) {
                                toggleDeviceSelection(device.UDID)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
                
                // Bottom action bar — visible whenever selection mode is active
                if isMultiSelectMode {
                    DeviceSelectionActionBar(
                        selectedCount: selectedDevices.count,
                        onLock: { Task { await lockSelectedDevices() } },
                        onUnlock: { Task { await unlockSelectedDevices() } },
                        onRestart: { showRestartConfirmation = true }
                    )
                }
            }
            
            // Processing overlay — shown while device actions are in flight
            if actionsManager.isProcessing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text(actionsManager.progressMessage)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(40)
                .background(Color.gray.opacity(0.9))
                .clipShape(.rect(cornerRadius: 16))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Left side — Select / Cancel button
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    isMultiSelectMode.toggle()
                    if !isMultiSelectMode {
                        selectedDevices.removeAll()
                    }
                } label: {
                    Text(isMultiSelectMode ? "Cancel" : "Select")
                }
            }
            
            // Center — Static class name with student/device counts
            ToolbarItem(placement: .principal) {
                if let classInfo = activeClass {
                    HStack(spacing: 12) {
                        // Class name (static label, no dropdown)
                        Text(classInfo.className)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        // Stats: student count + device count
                        HStack(spacing: 8) {
                            HStack(spacing: 3) {
                                Image(systemName: "person.2.fill")
                                Text("\(filteredStudentCount)")
                            }
                            
                            HStack(spacing: 3) {
                                Image(systemName: "ipad.landscape")
                                Text("\(classInfo.devices.count)")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(.capsule)
                }
            }
            
            // Right side — Greeting + Settings gear
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Text("Hi \(authManager.authenticatedUser?.firstName ?? "Teacher")")
                    .font(.subheadline)
                    .bold()
                
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .alert(actionAlertTitle, isPresented: $showActionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(actionAlertMessage)
        }
        .confirmationDialog(
            "Restart Devices",
            isPresented: $showRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restart \(selectedDevices.count) Device\(selectedDevices.count == 1 ? "" : "s")", role: .destructive) {
                Task {
                    await restartSelectedDevices()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to restart \(selectedDevices.count) device\(selectedDevices.count == 1 ? "" : "s")? This will interrupt any work on the devices.")
        }
        .onAppear {
            actionsManager.setAuthToken(authManager.token)
        }
        .task {
            await loadRestrictionProfiles()
        }
    }
    
    // MARK: - Selection Helpers
    
    /// Toggle selection for a device UDID
    private func toggleDeviceSelection(_ udid: String) {
        guard isMultiSelectMode else { return }
        if selectedDevices.contains(udid) {
            selectedDevices.remove(udid)
        } else {
            selectedDevices.insert(udid)
        }
    }
    
    // MARK: - Device Actions
    
    /// Lock selected devices to the Student Login app
    private func lockSelectedDevices() async {
        let devices = selectedDevicesWithOwners
        guard !devices.isEmpty else {
            actionAlertTitle = "No Eligible Devices"
            actionAlertMessage = "None of the selected devices have an assigned owner. Lock requires a device owner."
            showActionAlert = true
            return
        }
        
        let result = await actionsManager.lockDevicesToApp(
            devices,
            appBundleId: AppConstants.studentLoginBundleId
        )
        
        await MainActor.run {
            if result.isFullSuccess {
                actionAlertTitle = "Success"
                actionAlertMessage = "All \(result.successCount) device\(result.successCount == 1 ? "" : "s") will be locked to the Student Login app in a few seconds."
            } else if result.isPartialSuccess {
                actionAlertTitle = "Partial Success"
                actionAlertMessage = "\(result.successCount) device\(result.successCount == 1 ? "" : "s") locked. \(result.failCount) failed."
            } else {
                actionAlertTitle = "Error"
                actionAlertMessage = "Failed to lock devices. Please try again."
            }
            showActionAlert = true
        }
        
        // Refresh lock status after action
        try? await Task.sleep(for: .milliseconds(500))
        await loadRestrictionProfiles()
    }
    
    /// Unlock selected devices (clear restrictions)
    private func unlockSelectedDevices() async {
        let devices = selectedDevicesWithOwners
        guard !devices.isEmpty else {
            actionAlertTitle = "No Eligible Devices"
            actionAlertMessage = "None of the selected devices have an assigned owner. Unlock requires a device owner."
            showActionAlert = true
            return
        }
        
        let result = await actionsManager.unlockDevices(devices)
        
        await MainActor.run {
            if result.isFullSuccess {
                actionAlertTitle = "Devices Unlocked"
                actionAlertMessage = "All \(result.successCount) device\(result.successCount == 1 ? " has" : "s have") been unlocked."
            } else if result.isPartialSuccess {
                actionAlertTitle = "Partial Success"
                actionAlertMessage = "\(result.successCount) device\(result.successCount == 1 ? "" : "s") unlocked. \(result.failCount) failed."
            } else {
                actionAlertTitle = "Error"
                actionAlertMessage = "Failed to unlock devices. Please try again."
            }
            showActionAlert = true
        }
        
        // Refresh lock status after action
        try? await Task.sleep(for: .milliseconds(500))
        await loadRestrictionProfiles()
    }
    
    /// Restart selected devices
    private func restartSelectedDevices() async {
        let result = await actionsManager.restartDevices(selectedDevicesArray)
        
        await MainActor.run {
            if result.isFullSuccess {
                actionAlertTitle = "Restart Sent"
                actionAlertMessage = "All \(result.successCount) device\(result.successCount == 1 ? "" : "s") will restart shortly."
            } else if result.isPartialSuccess {
                actionAlertTitle = "Partial Success"
                actionAlertMessage = "\(result.successCount) device\(result.successCount == 1 ? "" : "s") will restart. \(result.failCount) failed."
            } else {
                actionAlertTitle = "Error"
                actionAlertMessage = "Failed to restart devices. Please try again."
            }
            showActionAlert = true
        }
    }
    
    // MARK: - Restriction Profile Helpers
    
    /// Check if a device is locked based on its owner's restriction status
    private func isDeviceLocked(_ device: TheDevice) -> Bool {
        guard let ownerId = device.owner?.id else { return false }
        return restrictionStatus[ownerId] ?? false
    }
    
    /// Load restriction profiles for each device's owner to determine lock status
    private func loadRestrictionProfiles() async {
        guard let token = authManager.token else {
            #if DEBUG
            print("❌ No auth token available for loading profiles")
            #endif
            return
        }
        
        await MainActor.run {
            isLoadingProfiles = true
        }
        
        var newStatus: [Int: Bool] = [:]
        
        // Get unique student IDs from device owners
        let studentIds = Set(allDevices.compactMap { $0.owner?.id })
        
        #if DEBUG
        print("🔄 Loading restriction profiles for \(studentIds.count) students")
        #endif
        
        for studentId in studentIds {
            #if DEBUG
            print("📡 Fetching profile for student \(studentId)")
            #endif
            
            do {
                let profiles: [StudentRestrictionProfile] = try await ApiManager.shared.getData(
                    from: .getTeacherProfiles(
                        scope: "student",
                        scopeId: studentId,
                        teachAuth: token
                    )
                )
                
                if let profile = profiles.first {
                    newStatus[profile.studentId] = profile.hasActiveRestrictions
                    #if DEBUG
                    print("✅ Student \(profile.studentId): hasActiveRestrictions = \(profile.hasActiveRestrictions)")
                    if profile.hasActiveRestrictions {
                        print("     - appWhitelist: \(profile.appWhitelist?.joined(separator: ", ") ?? "empty")")
                        print("     - restrictions: \(profile.restrictions != nil ? "present" : "nil")")
                        print("     - startDate: \(profile.startDate ?? "nil")")
                    }
                    #endif
                } else {
                    newStatus[studentId] = false
                    #if DEBUG
                    print("✅ Student \(studentId): No restrictions (empty response)")
                    #endif
                }
            } catch {
                #if DEBUG
                print("❌ Failed to load profile for student \(studentId): \(error)")
                #endif
                newStatus[studentId] = false
            }
        }
        
        #if DEBUG
        print("📊 Final restriction status: \(newStatus)")
        print("📱 Devices and their owners:")
        for device in allDevices {
            if let owner = device.owner {
                let isLocked = newStatus[owner.id] ?? false
                print("   \(device.name) -> Owner: \(owner.name) (ID: \(owner.id)) -> Locked: \(isLocked)")
            } else {
                print("   \(device.name) -> No owner")
            }
        }
        #endif
        
        await MainActor.run {
            restrictionStatus = newStatus
            isLoadingProfiles = false
        }
    }
}

// MARK: - Selectable Device Card

/// A device card that supports multi-select with a checkmark overlay.
///
/// Matches the selection UX of `DashboardSelectableStudentCard`:
/// - Top-trailing checkmark circle when in selection mode
/// - Blue border when selected
/// - Single tap navigates to `DeviceAppLockView` in normal mode
struct SelectableDeviceCard: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    let device: TheDevice
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let isLocked: Bool
    let allStudents: [Student]
    let onRefreshNeeded: () async -> Void
    let onTap: () -> Void
    
    @State private var showingDetail = false
    
    /// Determines the ring color by matching keywords in the device name
    private var ringColor: Color {
        let lowercasedName = device.name.lowercased()
        if lowercasedName.contains("blue") {
            return .blue
        } else if lowercasedName.contains("silver") || lowercasedName.contains("gray") || lowercasedName.contains("grey") {
            return Color(white: 0.6)
        } else if lowercasedName.contains("gold") {
            return .yellow
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
        ZStack(alignment: .topTrailing) {
            // Device card content
            Button {
                if isMultiSelectMode {
                    onTap()
                } else {
                    showingDetail = true
                }
            } label: {
                VStack(spacing: 6) {
                    // Device icon with colored ring
                    ZStack {
                        Circle()
                            .stroke(ringColor, lineWidth: 4)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "ipad.landscape")
                            .font(.system(size: 28))
                            .foregroundStyle(.primary)
                        
                        // Battery indicator
                        HStack(spacing: 2) {
                            Image(systemName: "battery.100.bolt")
                                .font(.system(size: 10))
                                .foregroundStyle(.green)
                        }
                        .offset(y: 45)
                    }
                    .frame(height: 90)
                    
                    // Device name
                    Text(device.name)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .frame(width: 150, height: 160)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(.rect(cornerRadius: 12))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            
            // Selection checkmark overlay — top-trailing, matching student card style
            if isMultiSelectMode {
                Circle()
                    .fill(isSelected ? Color.accentColor : Color(.systemGray4))
                    .frame(width: 26, height: 26)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(8)
            }
        }
        // Blue border when selected
        .overlay {
            if isMultiSelectMode && isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 3)
            }
        }
        .navigationDestination(isPresented: $showingDetail) {
            DeviceAppLockView(
                device: device,
                allStudents: allStudents,
                onActionsCompleted: {
                    // Action completed — server may not have updated yet
                }
            )
        }
        .onChange(of: showingDetail) { oldValue, newValue in
            // Refresh restriction profiles when returning from detail view
            if oldValue == true && newValue == false {
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    await onRefreshNeeded()
                }
            }
        }
    }
}

// MARK: - Device Detail View (Placeholder)

/// Placeholder detail view for a single device. The app currently uses
/// `DeviceAppLockView` for device detail; this exists for reference.
struct DeviceDetailView: View {
    let device: TheDevice
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 4)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "ipad.landscape")
                    .font(.system(size: 48))
                    .foregroundStyle(.primary)
            }
            
            VStack(spacing: 8) {
                Text(device.name)
                    .font(.title)
                    .bold()
                
                Text("Serial: \(device.serialNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("UDID: \(device.UDID)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
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
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 12))
                }
                
                Button {
                    // TODO: Unlock device
                } label: {
                    Label("Unlock Device", systemImage: "lock.open.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 12))
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
