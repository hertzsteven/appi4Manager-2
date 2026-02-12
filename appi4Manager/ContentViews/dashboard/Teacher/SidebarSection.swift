//
//  SidebarSection.swift
//  appi4Manager
//
//  Defines the navigation sections available in the teacher sidebar.
//

import SwiftUI

/// Represents the different sections accessible from the teacher sidebar.
enum SidebarSection: String, CaseIterable, Identifiable {
    case home
    case reports
    case students
    case devices
    case calendar
    case setup
    
    var id: String { rawValue }
    
    /// The SF Symbol icon name for each section
    var iconName: String {
        switch self {
        case .home: "house"
        case .reports: "chart.bar"
        case .students: "person.2"
        case .devices: "ipad.landscape"
        case .calendar: "calendar"
        case .setup: "gearshape"
        }
    }
    
    /// The display label shown below the icon
    var label: String {
        switch self {
        case .home: "Home"
        case .reports: "Reports"
        case .students: "Students"
        case .devices: "Devices"
        case .calendar: "Calendar"
        case .setup: "Setup"
        }
    }
}
