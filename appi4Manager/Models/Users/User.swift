//
//  User.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import Foundation

struct User: Codable, Identifiable, Hashable, ItemsToSelectRepresentable {

    var id:             Int
    var locationId:     Int
    var deviceCount:    Int
    var email:          String
    var groupIds:       Array<Int>
    var groups:         Array<String>
    var teacherGroups:  Array<Int>
    var firstName:      String
    var lastName:       String
    var username:       String
    var notes:          String
    var modified:       String
    var nameToDisplay: String {
        "\(firstName) \(lastName)"
    }
    
    internal init(id: Int, locationId: Int, deviceCount: Int, email: String, groupIds: Array<Int>, groups: Array<String>, teacherGroups: Array<Int>, firstName: String, lastName: String, username: String, notes: String, modified: String) {
        self.id             = id
        self.locationId     = locationId
        self.deviceCount    = deviceCount
        self.email          = email
        self.groupIds       = groupIds
        self.groups         = groups
        self.teacherGroups  = teacherGroups
        self.firstName      = firstName
        self.lastName       = lastName
        self.username       = username
        self.notes          = notes
        self.modified       = modified
    }
}


extension User {
    static func makeDefault() -> User {
        
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

        let year = components.year!
        let month = components.month!
        let day = components.day!
        let hour = components.hour!
        let minute = components.minute!
        let second = components.second!

        let startOfToday = DateComponents(calendar: calendar, year: year, month: month, day: day).date!
        let elapsedTime = date.timeIntervalSince(startOfToday)

        let totalSeconds = Int(elapsedTime) + (hour * 60 * 60) + (minute * 60) + second

//        print("Total seconds from the start of today: \(totalSeconds)")

        
        return User(id: totalSeconds, locationId:0, deviceCount: 0, email: "", groupIds: [], groups: [""], teacherGroups: [], firstName: "", lastName: "", username: "", notes: "", modified: "")
    }
}





extension User {
     init(locationId: Int, email: String, firstName: String, lastName: String, username: String) {
        self.id             = 0
        self.locationId     = locationId
        self.deviceCount    = 0
        self.email          = email
        self.groupIds       = []
        self.groups         = []
        self.teacherGroups  = []
        self.firstName      = firstName
        self.lastName       = lastName
        self.username       = username
        self.notes          = ""
        self.modified = Date().description // Or any other default value/format
    }
}


extension User {
    static func createUserTeacher(locationId: Int) -> User {
        let appi4TeacherName              = AppConstants.teacherUserName
        let appi4TeacherNameWithLocation  = appi4TeacherName + String(locationId)
        let rn                            = Int.random(in: 1...1000000)
        let appi4Teacheremail             = "appi4Teacher\(locationId)and\(rn)@gmail.com"
        return User(locationId: locationId, email: appi4Teacheremail, firstName: appi4TeacherName, lastName: appi4TeacherName, username: appi4TeacherNameWithLocation)
    }
}



/*
 {
   "username": "sun4",
   "password": "123456",
   "email": "nekhhh1wapi2@jamfschool.com",
   "firstName": "sun1",
   "lastName": "sun1",
   "locationId": 1
 }
 */
