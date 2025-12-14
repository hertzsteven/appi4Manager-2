//
//  TimeOfDay.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/18/23.
//

import Foundation

enum TimeOfDay {
    case am
    case pm
    case home
    
    /// Human-readable display name for the timeslot
    var displayName: String {
        switch self {
        case .am: return "AM"
        case .pm: return "PM"
        case .home: return "Home"
        }
    }
}
