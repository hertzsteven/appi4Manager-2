//
//  MultiDeviceAppLockView.swift
//  appi4Manager
//
//  View for managing multiple devices with action buttons:
//  Lock to Login, Unlock, Restart, Assign Owner
//

import SwiftUI

/// View for managing multiple device actions: Lock to Login, Unlock, Restart, Assign Owner
struct MultiDeviceAppLockView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    
    let devices: [TheDevice]
    let allStudents: [Student]
    let onActionsCompleted: () -> Void
    
    @State private var actionsManager = DeviceActionsManager()
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showStudentPicker: Bool = false
    @State private var showRestartConfirmation: Bool = false
    
    /// Devices that have valid owners
    private var devicesWithOwners: [TheDevice] {
        devices.filter { $0.owner != nil }
    }
    
    /// Devices without owners (can't be locked/unlocked)
    private var devicesWithoutOwners: [TheDevice] {
        devices.filter { $0.owner == nil }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with device count
                    devicesHeader
                    
                    // Warning for devices without owners
                    if !devicesWithoutOwners.isEmpty {
                        ownerWarningBanner
                    }
                    
                    // Action buttons
                    actionButtonsView
                    
                    Spacer()
                }
                
                // Loading overlay
                if actionsManager.isProcessing {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text(actionsManager.progressMessage)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(Color.gray.opacity(0.9))
                    .cornerRadius(16)
                }
            }
            .navigationTitle("Manage \(devices.count) Device\(devices.count == 1 ? "" : "s")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertTitle.contains("Success") || alertTitle.contains("Unlocked") || alertTitle.contains("Sent") || alertTitle.contains("Assigned") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog(
                "Restart Devices",
                isPresented: $showRestartConfirmation,
                titleVisibility: .visible
            ) {
                Button("Restart All", role: .destructive) {
                    Task {
                        await restartAllDevices()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to restart \(devices.count) device\(devices.count == 1 ? "" : "s")? This will interrupt any work on the devices.")
            }
            .sheet(isPresented: $showStudentPicker) {
                StudentPickerSheet(
                    students: allStudents,
                    onSelect: { student in
                        Task {
                            await assignOwnerToAll(student)
                        }
                    }
                )
            }
            .onAppear {
                actionsManager.setAuthToken(authManager.token)
            }
        }
    }
    
    // MARK: - Devices Header
    
    private var devicesHeader: some View {
        HStack(spacing: 16) {
            // Device count indicator
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 60, height: 60)
                
                VStack(spacing: 0) {
                    Text("\(devices.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Image(systemName: "ipad.landscape")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(devices.count) iPad\(devices.count == 1 ? "" : "s") selected")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Owner Warning Banner
    
    private var ownerWarningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(devicesWithoutOwners.count) device\(devicesWithoutOwners.count == 1 ? " has" : "s have") no owner")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Lock/Unlock will only apply to devices with owners")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
    }
    
    // MARK: - Action Buttons View
    
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Available Actions")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Lock to Login button
            actionButton(
                title: "Lock All to Login",
                subtitle: "Lock \(devicesWithOwners.count) device\(devicesWithOwners.count == 1 ? "" : "s") to Student Login app",
                icon: "lock.fill",
                color: .blue,
                isDisabled: devicesWithOwners.isEmpty
            ) {
                Task {
                    await lockAllToLogin()
                }
            }
            
            // Unlock button
            actionButton(
                title: "Unlock All Devices",
                subtitle: "Remove restrictions from \(devicesWithOwners.count) device\(devicesWithOwners.count == 1 ? "" : "s")",
                icon: "lock.open.fill",
                color: .green,
                isDisabled: devicesWithOwners.isEmpty
            ) {
                Task {
                    await unlockAllDevices()
                }
            }
            
            // Restart button
            actionButton(
                title: "Restart All Devices",
                subtitle: "Send restart command to \(devices.count) device\(devices.count == 1 ? "" : "s")",
                icon: "arrow.clockwise",
                color: .orange
            ) {
                showRestartConfirmation = true
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Action Button Component
    
    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(color.opacity(isDisabled ? 0.3 : 1.0))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isDisabled ? .secondary : .primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || actionsManager.isProcessing)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
    
    // MARK: - Actions
    
    private func lockAllToLogin() async {
        let result = await actionsManager.lockDevicesToApp(
            devicesWithOwners,
            appBundleId: AppConstants.studentLoginBundleId
        )
        
        await MainActor.run {
            if result.isFullSuccess {
                alertTitle = "Success"
                alertMessage = "All \(result.successCount) device\(result.successCount == 1 ? "" : "s") will be locked to the Student Login app in a few seconds."
            } else if result.isPartialSuccess {
                alertTitle = "Partial Success"
                alertMessage = "\(result.successCount) device\(result.successCount == 1 ? "" : "s") locked. \(result.failCount) failed."
            } else {
                alertTitle = "Error"
                alertMessage = "Failed to lock devices. Please try again."
            }
            showAlert = true
            onActionsCompleted()
        }
    }
    
    private func unlockAllDevices() async {
        let result = await actionsManager.unlockDevices(devicesWithOwners)
        
        await MainActor.run {
            if result.isFullSuccess {
                alertTitle = "Devices Unlocked"
                alertMessage = "All \(result.successCount) device\(result.successCount == 1 ? " has" : "s have") been unlocked."
            } else if result.isPartialSuccess {
                alertTitle = "Partial Success"
                alertMessage = "\(result.successCount) device\(result.successCount == 1 ? "" : "s") unlocked. \(result.failCount) failed."
            } else {
                alertTitle = "Error"
                alertMessage = "Failed to unlock devices. Please try again."
            }
            showAlert = true
            onActionsCompleted()
        }
    }
    
    private func restartAllDevices() async {
        let result = await actionsManager.restartDevices(devices)
        
        await MainActor.run {
            if result.isFullSuccess {
                alertTitle = "Restart Sent"
                alertMessage = "All \(result.successCount) device\(result.successCount == 1 ? "" : "s") will restart shortly."
            } else if result.isPartialSuccess {
                alertTitle = "Partial Success"
                alertMessage = "\(result.successCount) device\(result.successCount == 1 ? "" : "s") will restart. \(result.failCount) failed."
            } else {
                alertTitle = "Error"
                alertMessage = "Failed to restart devices. Please try again."
            }
            showAlert = true
        }
    }
    
    private func assignOwnerToAll(_ student: Student) async {
        let result = await actionsManager.assignStudentToDevices(devices, student: student)
        
        await MainActor.run {
            if result.isFullSuccess {
                alertTitle = "Owner Assigned"
                alertMessage = "\(student.name) has been assigned as owner of all \(result.successCount) device\(result.successCount == 1 ? "" : "s")."
            } else if result.isPartialSuccess {
                alertTitle = "Partial Success"
                alertMessage = "\(student.name) assigned to \(result.successCount) device\(result.successCount == 1 ? "" : "s"). \(result.failCount) failed."
            } else {
                alertTitle = "Error"
                alertMessage = "Failed to assign owner. Please try again."
            }
            showAlert = true
            onActionsCompleted()
        }
    }
}

#Preview {
    MultiDeviceAppLockView(
        devices: [
            TheDevice(
                serialNumber: "ABC123",
                locationId: 1,
                UDID: "00008120-0000000000000001",
                name: "Blue iPad",
                assetTag: "1",
                owner: Owner(id: 143, locationId: 1, name: "John Doe"),
                batteryLevel: 0.85,
                totalCapacity: 64,
                lastCheckin: "2024-01-01",
                modified: "2024-01-01",
                notes: ""
            ),
            TheDevice(
                serialNumber: "DEF456",
                locationId: 1,
                UDID: "00008120-0000000000000002",
                name: "Green iPad",
                assetTag: "2",
                owner: Owner(id: 144, locationId: 1, name: "Jane Smith"),
                batteryLevel: 0.65,
                totalCapacity: 64,
                lastCheckin: "2024-01-01",
                modified: "2024-01-01",
                notes: ""
            )
        ],
        allStudents: [
            Student(id: 143, name: "John Doe", email: "john@example.com", username: "johndoe", firstName: "John", lastName: "Doe", photo: URL(string: "https://via.placeholder.com/100")!),
            Student(id: 144, name: "Jane Smith", email: "jane@example.com", username: "janesmith", firstName: "Jane", lastName: "Smith", photo: URL(string: "https://via.placeholder.com/100")!)
        ],
        onActionsCompleted: { }
    )
    .environment(AuthenticationManager())
}
