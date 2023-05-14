//
//  Categories.swift
//  appi4Manager
//
//  Created by Steven Hertz on 5/12/23.
//

import SwiftUI


struct Category: Identifiable, Hashable {
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id = UUID().uuidString
    let name: String
    let color: Color
    let image: Image
    let count: Int
//    let navTo: AnyView
}

