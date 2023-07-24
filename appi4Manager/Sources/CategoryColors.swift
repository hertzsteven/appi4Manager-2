//
//  CategoryColors.swift
//  button Background
//
//  Created by Steven Hertz on 6/13/23.
//


import SwiftUI

struct CategoryColors {
    static var all: [Color] = [
        .primary,
        .gray,
        .red,
        .orange,
        .yellow,
        .green,
        .mint,
        .cyan,
        .indigo,
        .purple,
    ]
    
    static var `default` : Color = Color.primary
    
    static func random() -> Color {
        if let element = CategoryColors.all.randomElement() {
            return element
        } else {
            return .primary
        }
        
    }
}


