//
//  DevicePickerSheet.swift
//  appi4Manager
//
//  Sheet for selecting available devices to assign to a class.
//  Shows devices with empty/blank asset tags (available devices).
//

import SwiftUI

// MARK: - DevicePickerSheet

/// Sheet for picking available devices to assign to a class.
/// Shows devices that are not currently assigned to any class.
struct DevicePickerSheet: View {
    
    // MARK: - Environment & State
    
    @Environment(\.dismiss) private var dismiss
    
    let classGroupId: Int
    var onDevicesSelected: (([TheDevice]) -> Void)?
    
    @State private var availableDevices: [TheDevice] = []
    @State private var selectedDevices: Set<String> = []  // UDIDs
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var hasError = false
    @State private var errorMessage: String?
    
    // MARK: - Computed Properties
    
    private var filteredDevices: [TheDevice] {
        if searchText.isEmpty {
            return availableDevices
        }
        return availableDevices.filter { device in
            device.name.lowercased().contains(searchText.lowercased()) ||
            device.serialNumber.lowercased().contains(searchText.lowercased())
        }
    }
    
    private var selectedDevicesList: [TheDevice] {
        availableDevices.filter { selectedDevices.contains($0.UDID) }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if availableDevices.isEmpty {
                emptyStateView
            } else if filteredDevices.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                deviceListView
            }
        }
        .navigationTitle("Add Devices")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by name or serial")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Add (\(selectedDevices.count))") {
                    onDevicesSelected?(selectedDevicesList)
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(selectedDevices.isEmpty)
            }
        }
        .alert("Error", isPresented: $hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Failed to load devices.")
        }
        .task {
            await loadAvailableDevices()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading available devices...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Available Devices", systemImage: "ipad.slash")
        } description: {
            Text("All devices are currently assigned to classes.")
        }
    }
    
    private var deviceListView: some View {
        List {
            Section {
                ForEach(filteredDevices, id: \.UDID) { device in
                    DevicePickerRow(
                        device: device,
                        isSelected: selectedDevices.contains(device.UDID),
                        onToggle: {
                            toggleSelection(device)
                        }
                    )
                }
            } header: {
                Text("\(filteredDevices.count) Available Device\(filteredDevices.count == 1 ? "" : "s")")
            } footer: {
                Text("Select devices to assign to this class. Their asset tag will be updated to associate them with the class.")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Actions
    
    private func loadAvailableDevices() async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        do {
            // Get all devices
            let response: DeviceListResponse = try await ApiManager.shared.getData(
                from: .getDevices(assettag: nil)
            )
            
            // Filter to only available devices (empty, "None", or no asset tag)
            let available = response.devices.filter { device in
                device.assetTag.isEmpty ||
                device.assetTag.lowercased() == "none" ||
                device.assetTag == "0"
            }
            
            await MainActor.run {
                availableDevices = available.sorted { $0.name < $1.name }
            }
            
            #if DEBUG
            print("📱 Found \(available.count) available devices out of \(response.devices.count) total")
            #endif
            
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = error.localizedDescription
            }
            #if DEBUG
            print("❌ Failed to load devices: \(error)")
            #endif
        }
    }
    
    private func toggleSelection(_ device: TheDevice) {
        if selectedDevices.contains(device.UDID) {
            selectedDevices.remove(device.UDID)
        } else {
            selectedDevices.insert(device.UDID)
        }
    }
}

// MARK: - DevicePickerRow

private struct DevicePickerRow: View {
    let device: TheDevice
    let isSelected: Bool
    var onToggle: (() -> Void)?
    
    var body: some View {
        Button {
            onToggle?()
        } label: {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .gray)
                
                // Device icon
                Image(systemName: "ipad.landscape")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 32)
                
                // Device info
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
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
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

#Preview {
    NavigationStack {
        DevicePickerSheet(classGroupId: 100)
    }
}
