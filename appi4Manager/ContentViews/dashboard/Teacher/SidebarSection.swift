//
//  SidebarSection.swift
//  appi4Manager
//
//  Defines the navigation sections available in the teacher sidebar.
//

import SwiftUI

/// Represents the different sections accessible from the teacher sidebar.
enum SidebarSection: String, CaseIterable, Identifiable {
    case classroom
    case activity
    case students
    case devices
    case planning
    case setup
    
    var id: String { rawValue }
    
    /// The SF Symbol icon name for each section
    var iconName: String {
        switch self {
        case .classroom: "graduationcap"
        case .activity: "chart.bar"
        case .students: "person.2"
        case .devices: "ipad.landscape"
        case .planning: "calendar.badge.clock"
        case .setup: "gearshape"
        }
    }
    
    /// The display label shown below the icon
    var label: String {
        switch self {
        case .classroom: "Classroom"
        case .activity: "Activity"
        case .students: "Students"
        case .devices: "Devices"
        case .planning: "Planning"
        case .setup: "Setup"
        }
    }
}
