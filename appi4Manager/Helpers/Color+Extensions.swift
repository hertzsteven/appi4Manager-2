//
//  Color+Extensions.swift
//  appi4Manager
//
//  Created by Assistant on 2024-05-22.
//

import SwiftUI

extension Color {
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
