//
//  DayOfWeek.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/18/23.
//

import Foundation

enum DayOfWeek: Int, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var asAString: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tues"
        case .wednesday: return "Wed"
        case .thursday: return "Thurs"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    func dayOfWeek(from dayNumber: Int) -> DayOfWeek? {
        return DayOfWeek(rawValue: dayNumber)
    }

}
