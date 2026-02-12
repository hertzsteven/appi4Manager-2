//
//  TimeOfDay.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/18/23.
//

import SwiftUI

enum TimeOfDay {
    case am
    case pm
    case home
    case blocked
    
    /// Human-readable display name for the timeslot
    var displayName: String {
        switch self {
        case .am: "AM"
        case .pm: "PM"
        case .home: "Home"
        case .blocked: "Overnight"
        }
    }
    
    /// The SF Symbol icon for the timeslot
    var symbolName: String {
        switch self {
        case .am: "sun.max"
        case .pm: "sun.horizon"
        case .home: "house"
        case .blocked: "moon.stars"
        }
    }
    
    /// The semantic color for the timeslot
    var color: Color {
        switch self {
        case .am: .brandAmber
        case .pm: .brandIndigo
        case .home: .brandEmerald
        case .blocked: .secondary
        }
    }
}
