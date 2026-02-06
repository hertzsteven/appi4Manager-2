//
//  TeacherDevicesSidebarView.swift
//  appi4Manager
//
//  Devices management view accessed from the sidebar.
//

import SwiftUI

/// View for managing devices from the sidebar.
struct TeacherDevicesSidebarView: View {
    let teacherClasses: [TeacherClassInfo]
    
    /// All devices from all classes
    private var allDevices: [TheDevice] {
        teacherClasses.flatMap { $0.devices }
    }
    
    var body: some View {
        Group {
            if allDevices.isEmpty {
                ContentUnavailableView(
                    "No Devices",
                    systemImage: "ipad.landscape",
                    description: Text("No devices are assigned to your classes.")
                )
            } else {
                List(allDevices, id: \.id) { device in
                    DeviceRowView(device: device)
                }
            }
        }
        .navigationTitle("Devices")
    }
}

/// Simple row view for a device in the list
private struct DeviceRowView: View {
    let device: TheDevice
    
    var body: some View {
        HStack {
            Image(systemName: "ipad.landscape")
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                
                Text(device.serialNumber)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Show owner name if available
            if let owner = device.owner {
                Text(owner.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TeacherDevicesSidebarView(teacherClasses: [])
    }
}
