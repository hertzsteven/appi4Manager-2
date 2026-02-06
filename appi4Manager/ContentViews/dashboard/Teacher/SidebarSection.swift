//
//  SidebarSection.swift
//  appi4Manager
//
//  Defines the navigation sections available in the teacher sidebar.
//

import SwiftUI

/// Represents the different sections accessible from the teacher sidebar.
enum SidebarSection: String, CaseIterable, Identifiable {
    case liveClass
    case reports
    case students
    case setup
    
    var id: String { rawValue }
    
    /// The SF Symbol icon name for each section
    var iconName: String {
        switch self {
        case .liveClass: "video.fill"
        case .reports: "chart.bar.doc.horizontal"
        case .students: "person.2.fill"
        case .setup: "gearshape"
        }
    }
    
    /// The display label shown below the icon
    var label: String {
        switch self {
        case .liveClass: "Live Class"
        case .reports: "Reports"
        case .students: "Students"
        case .setup: "Setup"
        }
    }
}
