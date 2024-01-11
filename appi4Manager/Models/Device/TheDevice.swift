//
//  Device.swift
//  appi4Manager
//
//  Created by Steven Hertz on 1/4/24.
//

import Foundation

struct TheDevice: Codable, Identifiable, Hashable {
        
    let serialNumber      : String
    let locationId        : Int
    let UDID              : String
    let name              : String
    let assetTag          : String
    let batteryLevel      : Double
    let totalCapacity     : Double
    let lastCheckin       : String
    let modified          : String
    var notes             : String
    var title:          String  { name }
    var picName:        String  { "iPadGraphic"  }
    var id:             String  { UDID }
}


