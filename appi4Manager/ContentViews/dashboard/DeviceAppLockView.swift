//
//  DeviceAppLockView.swift
//  appi4Manager
//
//  View for managing a single device with action buttons:
//  Lock to Login, Unlock, Restart, Assign Owner
//

import SwiftUI

/// View for managing device actions: Lock to Login, Unlock, Restart, Assign Owner
struct DeviceAppLockView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    
    let device: TheDevice
    let allStudents: [Student]
    let onActionsCompleted: () -> Void
    
    @State private var actionsManager = DeviceActionsManager()
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showStudentPicker: Bool = false
    @State private var showRestartConfirmation: Bool = false
    
    /// Check if device has a valid owner for locking
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
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with device info
                deviceHeader
                
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
        .navigationTitle("Device Actions")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog(
            "Restart Device",
            isPresented: $showRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restart", role: .destructive) {
                Task {
                    await restartDevice()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to restart \(device.name)? This will interrupt any work on the device.")
        }
        .sheet(isPresented: $showStudentPicker) {
            StudentPickerSheet(
                students: allStudents,
                onSelect: { student in
                    Task {
                        await assignOwner(student)
                    }
                }
            )
        }
        .onAppear {
            actionsManager.setAuthToken(authManager.token)
        }
    }
    
    // MARK: - Device Header
    
    private var deviceHeader: some View {
        HStack(spacing: 16) {
            // Device icon with colored ring
            ZStack {
                Circle()
                    .stroke(ringColor, lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "ipad.landscape")
                    .font(.system(size: 28))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Owner info
                if let owner = device.owner {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                        Text(owner.name)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.caption)
                        Text("No owner assigned")
                            .font(.subheadline)
                    }
                    .foregroundColor(.orange)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
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
                title: "Lock to Login",
                subtitle: "Lock device to Student Login app",
                icon: "lock.fill",
                color: .blue,
                isDisabled: !hasOwner
            ) {
                Task {
                    await lockToLogin()
                }
            }
            
            // Unlock button
            actionButton(
                title: "Unlock Device",
                subtitle: "Remove all restrictions from device",
                icon: "lock.open.fill",
                color: .green,
                isDisabled: !hasOwner
            ) {
                Task {
                    await unlockDevice()
                }
            }
            
            // Restart button
            actionButton(
                title: "Restart Device",
                subtitle: "Send restart command to device",
                icon: "arrow.clockwise",
                color: .orange
            ) {
                showRestartConfirmation = true
            }
            
            // Assign Owner button
            actionButton(
                title: "Assign Owner",
                subtitle: hasOwner ? "Change device owner" : "Set a student as owner",
                icon: "person.badge.plus",
                color: .purple
            ) {
                showStudentPicker = true
            }
            
            // Warning for devices without owner
            if !hasOwner {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Lock and Unlock require an assigned owner")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
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
    
    private func lockToLogin() async {
        let result = await actionsManager.lockDeviceToApp(
            device,
            appBundleId: AppConstants.studentLoginBundleId
        )
        
        await MainActor.run {
            if result.isFullSuccess {
                alertTitle = "Success"
                alertMessage = "\(device.name) will be locked to the Student Login app in a few seconds."
            } else {
                alertTitle = "Error"
                alertMessage = "Failed to lock device. Please try again."
            }
            showAlert = true
            onActionsCompleted()
        }
    }
    
    private func unlockDevice() async {
        let result = await actionsManager.unlockDevice(device)
        
        await MainActor.run {
            if result.isFullSuccess {
                alertTitle = "Device Unlocked"
                alertMessage = "\(device.name) has been unlocked."
            } else {
                alertTitle = "Error"
                alertMessage = "Failed to unlock device. Please try again."
            }
            showAlert = true
            onActionsCompleted()
        }
    }
    
    private func restartDevice() async {
        let result = await actionsManager.restartDevice(device)
        
        await MainActor.run {
            if result.isFullSuccess {
                alertTitle = "Restart Sent"
                alertMessage = "\(device.name) will restart shortly."
            } else {
                alertTitle = "Error"
                alertMessage = "Failed to restart device. Please try again."
            }
            showAlert = true
        }
    }
    
    private func assignOwner(_ student: Student) async {
        let result = await actionsManager.assignStudentToDevice(device, student: student)
        
        await MainActor.run {
            if result.isFullSuccess {
                alertTitle = "Owner Assigned"
                alertMessage = "\(student.name) has been assigned as the owner of \(device.name)."
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
    NavigationStack {
        DeviceAppLockView(
            device: TheDevice(
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
            allStudents: [
                Student(id: 143, name: "John Doe", email: "john@example.com", username: "johndoe", firstName: "John", lastName: "Doe", photo: URL(string: "https://via.placeholder.com/100")!),
                Student(id: 144, name: "Jane Smith", email: "jane@example.com", username: "janesmith", firstName: "Jane", lastName: "Smith", photo: URL(string: "https://via.placeholder.com/100")!)
            ],
            onActionsCompleted: { }
        )
        .environment(AuthenticationManager())
    }
}
