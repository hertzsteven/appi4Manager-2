//
//  TimeslotSettings.swift
//  appi4Manager
//
//  Manages configurable timeslot hour ranges for AM/PM/Home sessions
//

import Foundation

/// Manages configurable timeslot hour ranges stored in UserDefaults
struct TimeslotSettings {
    
    // MARK: - Default Values
    
    static let defaultAMStart = 8
    static let defaultAMEnd = 12
    static let defaultPMStart = 12
    static let defaultPMEnd = 17
    static let defaultHomeStart = 17
    static let defaultHomeEnd = 24
    
    // MARK: - UserDefaults Keys
    
    private static let amStartKey = "timeslot_am_start"
    private static let amEndKey = "timeslot_am_end"
    private static let pmStartKey = "timeslot_pm_start"
    private static let pmEndKey = "timeslot_pm_end"
    private static let homeStartKey = "timeslot_home_start"
    private static let homeEndKey = "timeslot_home_end"
    
    // MARK: - Getters (with defaults)
    
    static var amStart: Int {
        UserDefaults.standard.object(forKey: amStartKey) as? Int ?? defaultAMStart
    }
    
    static var amEnd: Int {
        UserDefaults.standard.object(forKey: amEndKey) as? Int ?? defaultAMEnd
    }
    
    static var pmStart: Int {
        UserDefaults.standard.object(forKey: pmStartKey) as? Int ?? defaultPMStart
    }
    
    static var pmEnd: Int {
        UserDefaults.standard.object(forKey: pmEndKey) as? Int ?? defaultPMEnd
    }
    
    static var homeStart: Int {
        UserDefaults.standard.object(forKey: homeStartKey) as? Int ?? defaultHomeStart
    }
    
    static var homeEnd: Int {
        UserDefaults.standard.object(forKey: homeEndKey) as? Int ?? defaultHomeEnd
    }
    
    // MARK: - Setters
    
    static func setAMRange(start: Int, end: Int) {
        UserDefaults.standard.set(start, forKey: amStartKey)
        UserDefaults.standard.set(end, forKey: amEndKey)
    }
    
    static func setPMRange(start: Int, end: Int) {
        UserDefaults.standard.set(start, forKey: pmStartKey)
        UserDefaults.standard.set(end, forKey: pmEndKey)
    }
    
    static func setHomeRange(start: Int, end: Int) {
        UserDefaults.standard.set(start, forKey: homeStartKey)
        UserDefaults.standard.set(end, forKey: homeEndKey)
    }
    
    // MARK: - Reset to Defaults
    
    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: amStartKey)
        UserDefaults.standard.removeObject(forKey: amEndKey)
        UserDefaults.standard.removeObject(forKey: pmStartKey)
        UserDefaults.standard.removeObject(forKey: pmEndKey)
        UserDefaults.standard.removeObject(forKey: homeStartKey)
        UserDefaults.standard.removeObject(forKey: homeEndKey)
    }
    
    // MARK: - Time Range Descriptions
    
    /// Returns a formatted time range string for display (e.g., "8:00 AM - 11:59 AM")
    static func timeRangeString(for timeslot: TimeOfDay) -> String {
        switch timeslot {
        case .am:
            return "\(formatHour(amStart)) - \(formatHour(amEnd - 1, minute: 59))"
        case .pm:
            return "\(formatHour(pmStart)) - \(formatHour(pmEnd - 1, minute: 59))"
        case .home:
            let endDisplay = homeEnd == 24 ? "11:59 PM" : formatHour(homeEnd - 1, minute: 59)
            return "\(formatHour(homeStart)) - \(endDisplay)"
        case .blocked:
            return "Overnight (No Access)"
        }
    }
    
    /// Formats an hour (0-23) to a readable string like "8:00 AM" or "5:00 PM"
    private static func formatHour(_ hour: Int, minute: Int = 0) -> String {
        let period = hour < 12 ? "AM" : "PM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        if minute == 0 {
            return "\(displayHour):00 \(period)"
        } else {
            return "\(displayHour):\(String(format: "%02d", minute)) \(period)"
        }
    }
}
