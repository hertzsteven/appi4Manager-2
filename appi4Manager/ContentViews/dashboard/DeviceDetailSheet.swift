//
//  DeviceDetailSheet.swift
//  appi4Manager
//
//  Detail sheet for viewing device information and unassigning from class.
//

import SwiftUI

// MARK: - DeviceDetailSheet

/// Sheet for viewing device details and performing actions.
/// - View device info: name, serial, battery, last seen, owner, class
/// - Unassign from class
struct DeviceDetailSheet: View {
    
    // MARK: - Environment & State
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var classesViewModel: ClassesViewModel
    
    let device: TheDevice
    var onUpdate: (() -> Void)?
    
    // State
    @State private var isSaving = false
    @State private var hasError = false
    @State private var errorMessage: String?
    @State private var showUnassignConfirmation = false
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    
    // MARK: - Computed Properties
    
    private var isAssigned: Bool {
        !device.assetTag.isEmpty && 
        device.assetTag.lowercased() != "none" && 
        device.assetTag != "0"
    }
    
    private var assignedClassName: String? {
        guard isAssigned, let groupId = Int(device.assetTag) else { return nil }
        return classesViewModel.schoolClasses.first { $0.userGroupId == groupId }?.name
    }
    
    private var batteryColor: Color {
        if device.batteryLevel < 0.2 { return .red }
        if device.batteryLevel < 0.5 { return .orange }
        return .green
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
    
    // MARK: - Body
    
    var body: some View {
        Form {
            // Device Name Section
            deviceNameSection
            
            // Device Info Section
            deviceInfoSection
            
            // Status Section
            statusSection
            
            // Class Assignment Section
            classSection
            
            // Actions Section
            actionsSection
        }
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .overlay {
            if isSaving {
                savingOverlay
            }
        }
        .confirmationDialog(
            "Unassign Device",
            isPresented: $showUnassignConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unassign", role: .destructive) {
                Task {
                    await unassignDevice()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Unassign \"\(device.name)\" from \(assignedClassName ?? "this class")? The device will become available for other classes.")
        }
        .alert("Error", isPresented: $hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred.")
        }
        .alert("Success", isPresented: $showSuccessMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage)
        }
    }
    
    // MARK: - Sections
    
    private var deviceNameSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(device.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
        } header: {
            Text("Device")
        }
    }
    
    private var deviceInfoSection: some View {
        Section {
            InfoRowView(
                icon: "barcode",
                title: "Serial Number",
                value: device.serialNumber
            )
            
            InfoRowView(
                icon: "number",
                title: "UDID",
                value: String(device.UDID.prefix(8)) + "..."
            )
            
            if !device.notes.isEmpty {
                InfoRowView(
                    icon: "note.text",
                    title: "Notes",
                    value: device.notes
                )
            }
        } header: {
            Text("Device Information")
        }
    }
    
    private var statusSection: some View {
        Section {
            HStack {
                Label {
                    Text("Battery")
                } icon: {
                    Image(systemName: batteryIcon)
                        .foregroundColor(batteryColor)
                }
                
                Spacer()
                
                Text("\(Int(device.batteryLevel * 100))%")
                    .foregroundColor(.secondary)
            }
            
            InfoRowView(
                icon: "clock",
                title: "Last Check-in",
                value: formatDate(device.lastCheckin)
            )
            
            InfoRowView(
                icon: "arrow.triangle.2.circlepath",
                title: "Modified",
                value: formatDate(device.modified)
            )
        } header: {
            Text("Status")
        }
    }
    
    private var classSection: some View {
        Section {
            if isAssigned {
                HStack {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Assigned Class")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(assignedClassName ?? "Group \(device.assetTag)")
                                .font(.body)
                        }
                    } icon: {
                        Image(systemName: "rectangle.stack.person.crop")
                            .foregroundColor(.teal)
                    }
                    
                    Spacer()
                    
                    // Unassign button
                    Button(role: .destructive) {
                        showUnassignConfirmation = true
                    } label: {
                        Text("Unassign")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            } else {
                Label {
                    Text("Not assigned to any class")
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                }
            }
            
            if let owner = device.owner {
                InfoRowView(
                    icon: "person.fill",
                    title: "Owner",
                    value: owner.name
                )
            }
        } header: {
            Text("Assignment")
        }
    }
    
    private var actionsSection: some View {
        Section {
            if isAssigned {
                Button(role: .destructive) {
                    showUnassignConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Unassign from Class", systemImage: "minus.circle")
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Saving...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Helper Views
    
    private struct InfoRowView: View {
        let icon: String
        let title: String
        let value: String
        
        var body: some View {
            HStack {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text(value)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Actions
    
    private func unassignDevice() async {
        await MainActor.run { isSaving = true }
        defer { Task { await MainActor.run { isSaving = false } } }
        
        do {
            _ = try await ApiManager.shared.getDataNoDecode(
                from: .updateDevice(uuid: device.UDID, assetTag: "None")
            )
            
            await MainActor.run {
                successMessage = "Device unassigned successfully."
                showSuccessMessage = true
            }
            
            onUpdate?()
            
            // Dismiss after a short delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run { dismiss() }
            
            #if DEBUG
            print("✅ Unassigned device: \(device.name)")
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
    
    // MARK: - Helpers
    
    private func formatDate(_ dateString: String) -> String {
        if dateString.isEmpty { return "Unknown" }
        let components = dateString.components(separatedBy: "T")
        if components.count >= 1 {
            return components[0]
        }
        return dateString
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DeviceDetailSheet(
            device: TheDevice(
                serialNumber: "ABC123456",
                locationId: 1,
                UDID: "test-udid-12345",
                name: "iPad 001",
                assetTag: "100",
                owner: Owner(id: 1, locationId: 1, name: "John Smith"),
                batteryLevel: 0.85,
                totalCapacity: 64,
                lastCheckin: "2024-12-17T10:30:00Z",
                modified: "2024-12-17T09:00:00Z",
                notes: ""
            )
        )
        .environmentObject(ClassesViewModel())
    }
}
