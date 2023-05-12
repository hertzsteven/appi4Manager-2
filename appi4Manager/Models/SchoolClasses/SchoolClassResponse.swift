//
//  GroupResponse.swift
//  Test Making a urlSession
//
//  Created by Steven Hertz on 11/14/19.
//  Copyright © 2019 DIA. All rights reserved.
//

import Foundation

struct SchoolClassResponse: Codable {
    let code: Int
    var classes: [SchoolClass]
        
}

struct SchoolClass: Codable, Identifiable , Hashable {
    var uuid:         String
    var name:         String
    var description:  String
//    var userGroupId:  Int
    var locationId:   Int
    var userGroupId: Int
    var id: String {
        uuid
    }
}

extension SchoolClass: Equatable, Comparable {
    static func < (lhs: SchoolClass, rhs: SchoolClass) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

extension SchoolClass {
    static func makeDefault() -> SchoolClass {
        
//        let date = Date()
//        let calendar = Calendar.current
//        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
//
//        let year = components.year!
//        let month = components.month!
//        let day = components.day!
//        let hour = components.hour!
//        let minute = components.minute!
//        let second = components.second!
//
//        let startOfToday = DateComponents(calendar: calendar, year: year, month: month, day: day).date!
//        let elapsedTime = date.timeIntervalSince(startOfToday)
//
//        let totalSeconds = Int(elapsedTime) + (hour * 60 * 60) + (minute * 60) + second

//        print("Total seconds from the start of today: \(totalSeconds)")

  
        SchoolClass(uuid: UUID().uuidString, name: "", description: "", locationId: ApiHelper.globalLocationId, userGroupId: 0)
//        return User(id: totalSeconds, locationId: ApiHelper.globalLocationId, deviceCount: 0, email: "", groupIds: [], groups: [""], firstName: "", lastName: "", username: "", notes: "", modified: "")
    }
}
