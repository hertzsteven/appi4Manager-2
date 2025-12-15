//
//  WeeklyProfileEnums.swift
//  appi4Manager
//
//  Enums for the weekly profile view mode.
//  Controls whether viewing a single day or all days at once.
//

import Foundation

// MARK: - Weekly View Mode

/// Controls which day(s) to display in the weekly profile view.
/// Used by the segmented control at the top of WeeklyProfileView.
enum WeeklyViewMode: String, CaseIterable, Identifiable {
    case monday = "Mon"
    case tuesday = "Tue"
    case wednesday = "Wed"
    case thursday = "Thu"
    case friday = "Fri"
    case all = "All"
    
    var id: String { rawValue }
    
    /// Convert to DayOfWeek for data lookup (returns nil for .all)
    var toDayOfWeek: DayOfWeek? {
        switch self {
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .all: return nil
        }
    }
    
    /// Convert to day string for profile lookup (returns nil for .all)
    var toDayString: String? {
        toDayOfWeek?.asAString
    }
    
    /// All weekday cases (excludes .all)
    static var weekdays: [WeeklyViewMode] {
        [.monday, .tuesday, .wednesday, .thursday, .friday]
    }
}
