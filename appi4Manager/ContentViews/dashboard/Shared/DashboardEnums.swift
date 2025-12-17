//
//  DashboardEnums.swift
//  appi4Manager
//
//  Shared enums used by dashboard views.
//

import Foundation

// MARK: - Dashboard Mode

/// Determines whether the teacher is making quick changes (Now) or planning weekly schedules (Planning)
enum DashboardMode: String, CaseIterable {
    case now = "Now"
    case planning = "Planning"
}
