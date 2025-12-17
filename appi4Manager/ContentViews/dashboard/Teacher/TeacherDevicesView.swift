//
//  TeacherDevicesView.swift
//  appi4Manager
//
//  Device management views for the teacher dashboard.
//  Includes TeacherDevicesView, SelectableDeviceCard, and DeviceDetailView.
//

import SwiftUI

// MARK: - Teacher Devices View

struct TeacherDevicesView: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    let teacherClasses: [TeacherClassInfo]
    
    @State private var selectedDevices: Set<String> = [] // Set of UDIDs
    @State private var isMultiSelectMode = false
    @State private var showMultiDeviceLockSheet = false
    
    // Restriction profiles: studentId -> hasActiveRestrictions
    @State private var restrictionStatus: [Int: Bool] = [:]
    @State private var isLoadingProfiles = false
    
    /// All devices flattened from all classes
    private var allDevices: [TheDevice] {
        teacherClasses.flatMap { $0.devices }
    }
    
    /// Selected devices as array for multi-device lock
    private var selectedDevicesArray: [TheDevice] {
        allDevices.filter { selectedDevices.contains($0.UDID) }
    }
    
    /// All students from all classes (for owner assignment)
    private var allStudents: [Student] {
        teacherClasses.flatMap { $0.students }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header subtitle
            Text("Choose an iPad to manage")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            // Loading indicator for profiles
            if isLoadingProfiles {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading device status...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }
            
            // Devices Grid
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
            MultiDeviceAppLockView(
                devices: selectedDevicesArray,
                allStudents: allStudents,
                onActionsCompleted: {
                    // Action completed, but server may not have updated yet
                }
            )
        }
        .onChange(of: showMultiDeviceLockSheet) { oldValue, newValue in
            // Refresh when multi-device sheet is dismissed
            if oldValue == true && newValue == false {
                Task {
                    // Small delay to allow server to process the action
                    try? await Task.sleep(for: .milliseconds(500))
                    await loadRestrictionProfiles()
                }
            }
        }
        .task {
            await loadRestrictionProfiles()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if a device is locked based on its owner's restriction status
    private func isDeviceLocked(_ device: TheDevice) -> Bool {
        guard let ownerId = device.owner?.id else { return false }
        return restrictionStatus[ownerId] ?? false
    }
    
    /// Load restriction profiles for each device's owner (student)
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
        
        // Fetch profile for each student individually
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
                
                // The API returns an array, but for a single student there should be 0 or 1 profile
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
                    // No profile returned means no restrictions
                    newStatus[studentId] = false
                    #if DEBUG
                    print("✅ Student \(studentId): No restrictions (empty response)")
                    #endif
                }
            } catch {
                #if DEBUG
                print("❌ Failed to load profile for student \(studentId): \(error)")
                #endif
                // On error, assume no restrictions to avoid false positives
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
                    Text("Manage Devices")
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
    @Environment(AuthenticationManager.self) private var authManager
    
    let device: TheDevice
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let isLocked: Bool
    let allStudents: [Student]
    let onRefreshNeeded: () async -> Void
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
            VStack(spacing: 6) {
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
                    
                    // Lock status indicator (top-left)
                    ZStack {
                        Circle()
                            .fill(isLocked ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isLocked ? .red : .green)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .offset(x: -8, y: -8)
                    .zIndex(1)
                    
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
                
                // Owner info
                if let owner = device.owner {
                    Text(owner.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.caption2)
                        Text("No owner")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }
            .frame(width: 150, height: 160)
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
            DeviceAppLockView(
                device: device,
                allStudents: allStudents,
                onActionsCompleted: {
                    // Action completed, but server may not have updated yet
                }
            )
        }
        .onChange(of: showingDetail) { oldValue, newValue in
            // Refresh when returning from device detail view
            if oldValue == true && newValue == false {
                Task {
                    // Small delay to allow server to process the action
                    try? await Task.sleep(for: .milliseconds(500))
                    await onRefreshNeeded()
                }
            }
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
