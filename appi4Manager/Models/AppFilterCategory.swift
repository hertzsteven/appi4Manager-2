//
//  AppFilterCategory.swift
//  appi4Manager
//
//  Defines filter categories for apps in the Bulk Profile Setup view
//  Named AppFilterCategory to avoid conflict with existing AppCategory struct
//

import SwiftUI

/// Filter categories for apps based on educational content type
/// Used in the bulk profile setup to filter the app list
enum AppFilterCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case letters = "Letters"
    case math = "Math"
    case art = "Art"
    case music = "Music"
    
    var id: String { rawValue }
    
    /// Keywords to search for in app names to match this category
    var searchTerms: [String] {
        switch self {
        case .all:
            return []
        case .letters:
            return ["abc", "alpha", "letter", "phonics", "read", "spell", "word"]
        case .math:
            return ["math", "number", "count", "123", "add", "subtract", "multiply"]
        case .art:
            return ["draw", "paint", "art", "color", "create", "craft", "sketch"]
        case .music:
            return ["music", "song", "piano", "sound", "sing", "rhythm", "melody"]
        }
    }
    
    /// SF Symbol icon name for this category
    var iconName: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .letters:
            return "textformat.abc"
        case .math:
            return "number"
        case .art:
            return "paintpalette"
        case .music:
            return "music.note"
        }
    }
    
    /// Accent color for this category (subtle, matches system style)
    var accentColor: Color {
        switch self {
        case .all:
            return .secondary
        case .letters:
            return .blue
        case .math:
            return .orange
        case .art:
            return .pink
        case .music:
            return .purple
        }
    }
    
    /// Checks if an app name matches this category
    /// - Parameter appName: The name of the app to check
    /// - Returns: true if the app name contains any of the category's search terms
    func matches(appName: String) -> Bool {
        guard self != .all else { return true }
        
        let lowercasedName = appName.lowercased()
        return searchTerms.contains { term in
            lowercasedName.contains(term)
        }
    }
}
