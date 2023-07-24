//
//  ItemsToSelectRepresentableStr.swift
//  appi4Manager
//
//  Created by Steven Hertz on 7/23/23.
//

import SwiftUI


// fix make apps conform and change id type
protocol ItemsToSelectRepresentableStr: Identifiable {
    var locationId: Int { get }
    var nameToDisplay: String { get }
    var id: String { get }
    var symbolName: String {get}
}
