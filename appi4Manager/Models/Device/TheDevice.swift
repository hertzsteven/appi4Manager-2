//
//  Device.swift
//  appi4Manager
//
//  Created by Steven Hertz on 1/4/24.
//

import Foundation


    // Define the owner structure
struct Owner: Codable,  Identifiable, Hashable {
    var id: Int
    var locationId: Int
    var inTrash: Bool?
    var deviceCount: Int?
    var username: String?
    var email: String?
    var name:String
    var firstName: String?
    var lastName: String?
    var groupIds: [Int]?
    var groups: [String]?
    var teacherGroups: [String]?
    var children: [String]? // Assuming children is an array of Strings; adjust if the structure is different
    var notes: String?
    var modified: String?
}



struct TheDevice: Codable, Identifiable, Hashable {
    let serialNumber: String
    let locationId: Int
    let UDID: String
    let name: String
    let assetTag: String
    let owner: Owner?
    let batteryLevel: Double
    let totalCapacity: Double
    let lastCheckin: String
    let modified: String
    var notes: String
    var apps: [DeviceApp]?  // Populated when fetched with includeApps=true
    var title: String { name }
    var picName: String { "iPadGraphic" }
    var id: String { UDID }
    
    static func == (lhs: TheDevice, rhs: TheDevice) -> Bool {
        lhs.UDID == rhs.UDID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(UDID) // Use the UDID as the unique identifier for hashing
    }
}

