//
//  Color+Extensions.swift
//  appi4Manager
//
//  Created by Assistant on 2024-05-22.
//

import SwiftUI

public extension Color {
    
    // MARK: - Brand Colors
    
    /// A premium indigo shade for primary branding
    static let brandIndigo = Color(red: 0.35, green: 0.34, blue: 0.84)
    
    /// A sophisticated emerald green for success states
    static let brandEmerald = Color(red: 0.1, green: 0.6, blue: 0.45)
    
    /// A rich amber for warning or standby states
    static let brandAmber = Color(red: 0.95, green: 0.6, blue: 0.1)
    
    // MARK: - Utilities
    
    /// Generates a consistent random color based on a seed string.
    /// This ensures that the same "Class Name" always gets the same color.
    static func random(seed: String) -> Color {
        var total: Int = 0
        for u in seed.unicodeScalars {
            total += Int(UInt32(u))
        }
        
        srand48(total * 200)
        let r = CGFloat(drand48())
        let g = CGFloat(drand48())
        let b = CGFloat(drand48())
        
        return Color(red: r, green: g, blue: b)
    }
    
    /// Returns a specific tailored gradient for a given seed string
    static func gradient(for seed: String) -> LinearGradient {
        let colors: [[Color]] = [
            [.blue, .purple],
            [.orange, .red],
            [.green, .teal],
            [.pink, .purple],
            [.yellow, .orange],
            [.mint, .blue],
            [.indigo, .cyan]
        ]
        
        var total: Int = 0
        for u in seed.unicodeScalars {
            total += Int(UInt32(u))
        }
        
        let index = total % colors.count
        let selection = colors[index]
        
        return LinearGradient(
            colors: selection,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
