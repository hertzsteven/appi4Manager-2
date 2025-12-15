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
    let teacherClasses: [TeacherClassInfo]
    
    @State private var selectedDevices: Set<String> = [] // Set of UDIDs
    @State private var isMultiSelectMode = false
    @State private var showMultiDeviceLockSheet = false
    
    /// All devices flattened from all classes
    private var allDevices: [TheDevice] {
        teacherClasses.flatMap { $0.devices }
    }
    
    /// Selected devices as array for multi-device lock
    private var selectedDevicesArray: [TheDevice] {
        allDevices.filter { selectedDevices.contains($0.UDID) }
    }
    
    var body: some View {
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
                            isMultiSelectMode: isMultiSelectMode
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
            MultiDeviceAppLockView(devices: selectedDevicesArray)
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
                    Text("Lock to App")
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
    let device: TheDevice
    let isSelected: Bool
    let isMultiSelectMode: Bool
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
            VStack(spacing: 8) {
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
                
                // Model Info
                Text("iPad")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 150, height: 150)
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
