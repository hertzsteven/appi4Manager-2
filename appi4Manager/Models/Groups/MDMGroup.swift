    //
    //  Group.swift
    //  appi4Manager
    //
    //  Created by Steven Hertz on 12/1/23.
    //

import Foundation

struct MDMGroup: Codable {
    struct Acl: Codable {
        let teacher: String
        let parent: String
        
            // Convenience initializer for Acl
        init(teacher: String, parent: String = "inherit") {
            self.teacher = teacher
            self.parent = parent
        }
    }
    
    let id          : Int
    let locationId  : Int
    let name        : String
    let description : String
    let userCount   : Int
    let acl         : Acl
    let modified    : String
    
        // Default initializer
    init(id: Int, locationId: Int, name: String, description: String, userCount: Int, acl: Acl, modified: String) {
        self.id = id
        self.locationId = locationId
        self.name = name
        self.description = description
        self.userCount = userCount
        self.acl = acl
        self.modified = modified
    }
}

extension MDMGroup {
    
        // Convenience initializer for MDMGroup
    init(locationId: Int, name: String, teacher: String) {
        self.id = 0 // Provide a default value or a way to calculate it
        self.locationId = locationId
        self.name = name
        self.description = "Default Description" // Default value
        self.userCount = 0 // Default value
        self.acl = Acl(teacher: teacher)
        self.modified = Date().description // Or any other default value/format
    }
}

extension MDMGroup {
    static func createTeacherGroup(locationId: Int) -> MDMGroup {
        let appi4TeachermdmGroupName              = AppConstants.teacherGroupName
        let appi4TeachermdmGroupNameWithLocation  = appi4TeachermdmGroupName + String(locationId)
//        let rn                            = Int.random(in: 1...1000000)
//        let appi4Teacheremail             = "appi4Teacher\(locationId)and\(rn)@gmail.com"
        return MDMGroup(locationId: locationId, name: appi4TeachermdmGroupNameWithLocation, teacher: "allow")
    }
}
