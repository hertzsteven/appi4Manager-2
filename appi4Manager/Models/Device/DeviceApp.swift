//
//  DeviceApp.swift
//  appi4Manager
//
//  Model for apps installed on a device (from /devices/?includeApps=true response)
//

import Foundation

/// Represents an app installed on a managed device
struct DeviceApp: Codable, Identifiable, Hashable {
    let name: String?
    let identifier: String?  // Bundle ID (e.g., "com.apple.pages")
    let vendor: String?
    let version: String?
    let icon: String?        // URL to app icon
    
    var id: String { identifier ?? UUID().uuidString }
    
    /// Display name, falls back to "Unknown App" if nil
    var displayName: String {
        name ?? "Unknown App"
    }
    
    /// Returns the icon URL if available
    var iconURL: URL? {
        guard let icon = icon, !icon.isEmpty else { return nil }
        return URL(string: icon)
    }
}
