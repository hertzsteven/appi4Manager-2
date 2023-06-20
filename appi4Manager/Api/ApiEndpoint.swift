//
//  ApiEndpoint.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import Foundation

enum ApiEndpoint {
    
    enum Method: String {
        case GET
        case POST
        case PUT
        case DELETE
    }
    
    /// Define all your endpoints here
    case getUsers
    case getUsersInGroup(groupID: Int)
    case getaUser(id: Int)
    case getStudents(uuid: String)
    case authenticateTeacher(company: String, username:String, password: String)
    case getSchoolClasses
    case addUsr(user: User)
    case addUser(username: String, password: String, email: String, firstName: String, lastName: String,  notes: String, locationId: Int, groupIds: Array<Int>, teacherGroups: Array<Int>)
    case deleteaUser(id: Int)
    case updateaUser(id: Int, username: String, password: String, email: String, firstName: String, lastName: String, notes: String, locationId: Int, groupIds: Array<Int>, teacherGroups: Array<Int>)
    case updateaClass(uuid: String, name: String, description: String)
    case createaClass(name: String, description: String, locationId: String)
    case deleteaClass(uuid: String)
    case assignToClass(uuid: String, students: Array<Int>, teachers: Array<Int>)
    case getLocations
    case updatePhoto(id: Int, teachAuth: String, data: Data)
    case getLessons(teachAuth: String)
    case getLessonDetail(teachAuth: String, id: Int)

}

extension ApiEndpoint {

    /// The path for every endpoint
    var path: String {
        switch self {
        case .getUsers:
           return "/users"
        case .getUsersInGroup:
            return "/users"
        case .getStudents(let uuid):
            return "/classes/\(uuid)"
        case .authenticateTeacher(company: _, username: _, password: _):
            return "/teacher/authenticate"
        case .getaUser(let id):
            return "/users/\(id)"
        case .getSchoolClasses:
            return "/classes"
        case .addUser:
            return "/users"
        case .deleteaUser(let id):
            return "/users/\(id)"
        case .updateaUser(let id, username: _, password: _, email: _, firstName: _, lastName: _, notes: _, locationId: _, groupIds: _, teacherGroups: _):
            return "/users/\(id)"
        case .updateaClass(uuid: let uuid, name: _, description: _):
            return "/classes/\(uuid)"
        case .createaClass( name: _, description: _, locationId: _):
            return "/classes"
        case .deleteaClass(let uuid):
            return "/classes/\(uuid)"
        case .assignToClass(uuid: let uuid, students: _, teachers: _):
            return "/classes/\(uuid)/users"
        case .getLocations:
           return "/locations"
        case .updatePhoto(id: let id, teachAuth: _, data: _):
            return "/teacher/uploadPhoto/\(id)"
        case .addUsr:
            return "/users"
        case .getLessons( teachAuth: _ ):
           return "/teacher/lessons"
        case .getLessonDetail( teachAuth: _, let id ):
           return "/teacher/lessons/\(id)"

        }
    }
    
    /// The method for the endpoint
    var method: ApiEndpoint.Method {
        switch self {
        case .authenticateTeacher(company: _, username: _, password: _):
            return .POST
        case .addUser:
            return .POST
        case .addUsr:
            return .POST
        case .updateaUser(id: _):
            return .PUT
        case .updateaClass(uuid: _, name: _, description: _):
            return .PUT
        case .createaClass(name: _, description: _, locationId: _):
            return .POST
        case .deleteaUser(id: _):
            return .DELETE
        case .deleteaClass(uuid: _):
            return .DELETE
        case .assignToClass(uuid: _, students: _, teachers: _):
            return .PUT
        case .updatePhoto(id: _, teachAuth: _, data: _):
            return .POST
        case .getLessons( teachAuth: _ ):
            return .GET
        case .getLessonDetail(teachAuth: _, id: _):
            return .GET
        default:
            return .GET
        }
    }
    
//    var requestHeaders: [String:String] {
//        switch self {
//        case .getUsers, .getStudents:
//            return ["Authorization": "Basic NjUzMTkwNzY6UFFMNjFaVUU2RlFOWDVKSlMzTE5CWlBDS1BETVhMSFA=",
//                    "Content-Type": "application/json",
//                    "X-Server-Protocol-Version": "2"
//            ]
//        case .getaUser(let id):
//            <#code#>
////        case .getStudents:
////            <#code#>
//        case .authenticateTeacher(let company, let username, let password):
//            <#code#>
//        case .getSchoolClasses:
//            <#code#>
//        case .addUser:
//            <#code#>
//        }
//    }
    
    /// The URL parameters for the endpoint (in case it has any)
    var parameters: [URLQueryItem]? {
        switch self {
        case .updatePhoto(id: _, teachAuth: _, data: _) :
            return [URLQueryItem(name: "token", value: "9c74b8d6a4934ca986dfe46592896801")]
        case .getUsersInGroup(let groupID) :
            return [URLQueryItem(name: "memberOf", value: String(groupID))]
        case .getLessons(teachAuth: let teachAuth):
            return [URLQueryItem(name: "token", value: teachAuth)]
        case .getLessonDetail(teachAuth: let teachAuth, id: _ ):
            return [URLQueryItem(name: "token", value: "9c74b8d6a4934ca986dfe46592896801")]

//        case .getStudents(uuid: _):
//            return [URLQueryItem(name: "token", value: "9c74b8d6a4934ca986dfe46592896801")]
        default:
            return nil
        }
    }
}
