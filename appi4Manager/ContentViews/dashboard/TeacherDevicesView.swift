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
    @State private var showStudentPicker = false
    @State private var deviceActionsManager = DeviceActionsManager()
    
    // Alert states
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Single device action states
    @State private var singleDeviceForAction: TheDevice?
    @State private var showSingleDeviceLockSheet = false
    @State private var showSingleDeviceStudentPicker = false
    
    /// All devices flattened from all classes
    private var allDevices: [TheDevice] {
        teacherClasses.flatMap { $0.devices }
    }
    
    /// All students flattened from all classes
    private var allStudents: [Student] {
        teacherClasses.flatMap { $0.students }
    }
    
    /// Selected devices as array for multi-device lock
    private var selectedDevicesArray: [TheDevice] {
        allDevices.filter { selectedDevices.contains($0.UDID) }
    }
    
    var body: some View {
        ZStack {
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
                                isMultiSelectMode: isMultiSelectMode,
                                students: allStudents,
                                onTap: {
                                    if isMultiSelectMode {
                                        // Toggle selection
                                        if selectedDevices.contains(device.UDID) {
                                            selectedDevices.remove(device.UDID)
                                        } else {
                                            selectedDevices.insert(device.UDID)
                                        }
                                    }
                                },
                                onUnlock: {
                                    Task {
                                        await handleSingleDeviceUnlock(device)
                                    }
                                },
                                onRestart: {
                                    Task {
                                        await handleSingleDeviceRestart(device)
                                    }
                                },
                                onLockToApp: {
                                    singleDeviceForAction = device
                                    showSingleDeviceLockSheet = true
                                },
                                onAssignStudent: {
                                    singleDeviceForAction = device
                                    showSingleDeviceStudentPicker = true
                                }
                            )
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
            
            // Processing overlay
            if deviceActionsManager.isProcessing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text(deviceActionsManager.progressMessage)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(40)
                .background(Color.gray.opacity(0.9))
                .cornerRadius(16)
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
        .sheet(isPresented: $showStudentPicker) {
            StudentPickerSheet(
                students: allStudents,
                onSelect: { student in
                    Task {
                        await handleMultiDeviceAssignStudent(student)
                    }
                }
            )
        }
        .sheet(isPresented: $showSingleDeviceLockSheet) {
            if let device = singleDeviceForAction {
                NavigationStack {
                    DeviceAppLockView(device: device)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showSingleDeviceLockSheet = false
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showSingleDeviceStudentPicker) {
            StudentPickerSheet(
                students: allStudents,
                onSelect: { student in
                    if let device = singleDeviceForAction {
                        Task {
                            await handleSingleDeviceAssignStudent(device, student: student)
                        }
                    }
                }
            )
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            deviceActionsManager.setAuthToken(authManager.token)
        }
    }
    
    // MARK: - Selected Devices Action Bar
    
    private var selectedDevicesActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 12) {
                // Selection count
                Text("\(selectedDevices.count) iPad\(selectedDevices.count == 1 ? "" : "s") selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Action buttons grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // Unlock button
                    Button {
                        Task {
                            await handleMultiDeviceUnlock()
                        }
                    } label: {
                        Label("Unlock", systemImage: "lock.open.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    // Restart button
                    Button {
                        Task {
                            await handleMultiDeviceRestart()
                        }
                    } label: {
                        Label("Restart", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    // Lock to App button
                    Button {
                        showMultiDeviceLockSheet = true
                    } label: {
                        Label("Lock to App", systemImage: "lock.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    // Assign Student button
                    Button {
                        showStudentPicker = true
                    } label: {
                        Label("Assign", systemImage: "person.badge.plus")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Single Device Actions
    
    private func handleSingleDeviceUnlock(_ device: TheDevice) async {
        let result = await deviceActionsManager.unlockDevice(device)
        await showResultAlert(for: "Unlock", result: result)
    }
    
    private func handleSingleDeviceRestart(_ device: TheDevice) async {
        let result = await deviceActionsManager.restartDevice(device)
        await showResultAlert(for: "Restart", result: result)
    }
    
    private func handleSingleDeviceAssignStudent(_ device: TheDevice, student: Student) async {
        let result = await deviceActionsManager.assignStudentToDevice(device, student: student)
        await showResultAlert(for: "Assign Student", result: result, studentName: student.firstName)
    }
    
    // MARK: - Multi Device Actions
    
    private func handleMultiDeviceUnlock() async {
        let result = await deviceActionsManager.unlockDevices(selectedDevicesArray)
        await showResultAlert(for: "Unlock", result: result)
    }
    
    private func handleMultiDeviceRestart() async {
        let result = await deviceActionsManager.restartDevices(selectedDevicesArray)
        await showResultAlert(for: "Restart", result: result)
    }
    
    private func handleMultiDeviceAssignStudent(_ student: Student) async {
        let result = await deviceActionsManager.assignStudentToDevices(selectedDevicesArray, student: student)
        await showResultAlert(for: "Assign Student", result: result, studentName: student.firstName)
    }
    
    // MARK: - Alert Helper
    
    @MainActor
    private func showResultAlert(for action: String, result: DeviceActionResult, studentName: String? = nil) {
        if result.isFullSuccess {
            alertTitle = "Success"
            if let name = studentName {
                alertMessage = "\(name) has been assigned to \(result.successCount) device\(result.successCount == 1 ? "" : "s")."
            } else {
                alertMessage = "\(action) command sent to \(result.successCount) device\(result.successCount == 1 ? "" : "s")."
            }
        } else if result.isPartialSuccess {
            alertTitle = "Partial Success"
            alertMessage = "\(result.successCount) succeeded, \(result.failCount) failed."
        } else if result.isFullFailure && result.failCount > 0 {
            alertTitle = "Error"
            alertMessage = "Failed to \(action.lowercased()) device\(result.failCount == 1 ? "" : "s")."
        } else {
            alertTitle = "No Action"
            alertMessage = "No devices with owners to \(action.lowercased())."
        }
        showAlert = true
    }
}

// MARK: - Selectable Device Card

struct SelectableDeviceCard: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    let device: TheDevice
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let students: [Student]
    let onTap: () -> Void
    let onUnlock: () -> Void
    let onRestart: () -> Void
    let onLockToApp: () -> Void
    let onAssignStudent: () -> Void
    
    @State private var showingDetail = false
    @State private var showActionSheet = false
    
    /// Check if device has an owner
    private var hasOwner: Bool {
        device.owner != nil
    }
    
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
                showActionSheet = true
            }
        } label: {
            VStack(spacing: 4) {
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
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "ipad.landscape")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                }
                .frame(height: 70)
                
                // Device Name
                Text(device.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Owner Info
                if let owner = device.owner {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 9))
                        Text(owner.name)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 9))
                        Text("No owner")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }
            .frame(width: 150, height: 140)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .confirmationDialog("Device Actions", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button("Lock to App") {
                onLockToApp()
            }
            
            Button("Unlock Device") {
                onUnlock()
            }
            .disabled(!hasOwner)
            
            Button("Restart Device") {
                onRestart()
            }
            
            Button("Assign Student") {
                onAssignStudent()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(device.name)
        }
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
