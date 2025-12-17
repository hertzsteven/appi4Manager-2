//
//  DeviceManagementListView.swift
//  appi4Manager
//
//  Main list view for admin device management.
//  Shows all devices with filtering by location and assignment status.
//

import SwiftUI

// MARK: - AssignmentFilter

enum AssignmentFilter: String, CaseIterable {
    case all = "All"
    case assigned = "Assigned"
    case available = "Available"
}

// MARK: - DeviceManagementListView

/// Admin view for managing devices.
/// - Filter by location and assignment status
/// - Search by name or serial
/// - Tap to view/edit device details
struct DeviceManagementListView: View {
    
    // MARK: - Environment & State
    
    @EnvironmentObject var devicesViewModel: DevicesViewModel
    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var teacherItems: TeacherItems
    
    @State private var devices: [TheDevice] = []
    @State private var isLoading = false
    @State private var hasError = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var assignmentFilter: AssignmentFilter = .all
    @State private var selectedDevice: TheDevice?
    @State private var showDeviceDetail = false
    
    // MARK: - Computed Properties
    
    private var filteredDevices: [TheDevice] {
        let locationId = teacherItems.currentLocation.id
        
        // Filter by location
        var result = devices.filter { $0.locationId == locationId }
        
        // Filter by assignment status
        switch assignmentFilter {
        case .all:
            break
        case .assigned:
            result = result.filter { !$0.assetTag.isEmpty && $0.assetTag.lowercased() != "none" && $0.assetTag != "0" }
        case .available:
            result = result.filter { $0.assetTag.isEmpty || $0.assetTag.lowercased() == "none" || $0.assetTag == "0" }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { device in
                device.name.lowercased().contains(searchText.lowercased()) ||
                device.serialNumber.lowercased().contains(searchText.lowercased())
            }
        }
        
        return result.sorted { $0.name < $1.name }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            Group {
                if isLoading {
                    loadingView
                } else if devices.isEmpty {
                    emptyStateView
                } else if filteredDevices.isEmpty {
                    noResultsView
                } else {
                    deviceListView
                }
            }
        }
        .navigationTitle("Device Management")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search by name or serial")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                locationPicker
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                filterMenu
            }
        }
        .sheet(isPresented: $showDeviceDetail) {
            if let device = selectedDevice {
                NavigationStack {
                    DeviceDetailSheet(
                        device: device,
                        onUpdate: {
                            Task {
                                await loadDevices()
                            }
                        }
                    )
                }
            }
        }
        .alert("Error", isPresented: $hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred.")
        }
        .task {
            await loadDevices()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading devices...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Devices", systemImage: "ipad.slash")
        } description: {
            Text("No devices found for this location.")
        }
    }
    
    @ViewBuilder
    private var noResultsView: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            ContentUnavailableView {
                Label("No Devices", systemImage: "ipad.slash")
            } description: {
                Text("No \(assignmentFilter.rawValue.lowercased()) devices found.")
            }
        }
    }
    
    private var deviceListView: some View {
        ScrollView {
            // Filter chips
            filterChipsView
            
            LazyVStack(spacing: 12) {
                ForEach(filteredDevices, id: \.UDID) { device in
                    DeviceManagementCard(
                        device: device,
                        className: getClassName(for: device)
                    )
                    .onTapGesture {
                        selectedDevice = device
                        showDeviceDetail = true
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .refreshable {
            await loadDevices()
        }
    }
    
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AssignmentFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: assignmentFilter == filter,
                        count: countDevices(for: filter)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            assignmentFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private var locationPicker: some View {
        Menu {
            Picker("Location", selection: $teacherItems.selectedLocationIdx) {
                ForEach(0..<teacherItems.MDMlocations.count, id: \.self) { index in
                    Text(teacherItems.MDMlocations[index].name)
                        .tag(index)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "building.2.fill")
                Text(teacherItems.MDMlocations[teacherItems.selectedLocationIdx].name)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundColor(.accentColor)
        }
    }
    
    private var filterMenu: some View {
        Menu {
            Picker("Filter", selection: $assignmentFilter) {
                ForEach(AssignmentFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title2)
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadDevices() async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        do {
            let response: DeviceListResponse = try await ApiManager.shared.getData(
                from: .getDevices(assettag: nil)
            )
            await MainActor.run {
                devices = response.devices
            }
            
            #if DEBUG
            print("📱 Loaded \(response.devices.count) devices")
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
    
    private func getClassName(for device: TheDevice) -> String? {
        guard !device.assetTag.isEmpty,
              device.assetTag.lowercased() != "none",
              device.assetTag != "0",
              let groupId = Int(device.assetTag) else {
            return nil
        }
        
        return classesViewModel.schoolClasses.first { $0.userGroupId == groupId }?.name
    }
    
    private func countDevices(for filter: AssignmentFilter) -> Int {
        let locationId = teacherItems.currentLocation.id
        let locationDevices = devices.filter { $0.locationId == locationId }
        
        switch filter {
        case .all:
            return locationDevices.count
        case .assigned:
            return locationDevices.filter { !$0.assetTag.isEmpty && $0.assetTag.lowercased() != "none" && $0.assetTag != "0" }.count
        case .available:
            return locationDevices.filter { $0.assetTag.isEmpty || $0.assetTag.lowercased() == "none" || $0.assetTag == "0" }.count
        }
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color(.systemGray5))
                    .cornerRadius(8)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DeviceManagementCard

private struct DeviceManagementCard: View {
    let device: TheDevice
    let className: String?
    
    private var isOnline: Bool {
        // Consider device online if last check-in was within 5 minutes
        // This is a simplified check - you may want to parse the lastCheckin date
        true
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Device Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.teal.opacity(0.8), .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "ipad.landscape")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Device Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(device.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Battery
                    HStack(spacing: 4) {
                        Image(systemName: batteryIcon)
                            .foregroundColor(batteryColor)
                        Text("\(Int(device.batteryLevel * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("SN: \(device.serialNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    // Class assignment
                    if let className = className {
                        Label(className, systemImage: "rectangle.stack.person.crop")
                            .font(.caption)
                            .foregroundColor(.teal)
                    } else {
                        Label("Available", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    // Owner
                    if let owner = device.owner {
                        Label(owner.name, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DeviceManagementListView()
            .environmentObject(DevicesViewModel())
            .environmentObject(ClassesViewModel())
            .environmentObject(TeacherItems())
    }
}
