//
//  StudentAppProfile.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/8/23.
//

import Foundation


struct DailySessions: Codable, Equatable {
    var amSession: Session
    var pmSession: Session
    var homeSession: Session
    
        // Implement the Equatable protocol by defining the == operator
    static func == (lhs: DailySessions, rhs: DailySessions) -> Bool {
        return lhs.amSession == rhs.amSession &&
        lhs.pmSession == rhs.pmSession &&
        lhs.homeSession == rhs.homeSession
    }
    
    static func makeDefaultDailySession() -> DailySessions {
        DailySessions(amSession: Session(apps: [], sessionLength: 0, oneAppLock: false),
                      pmSession: Session(apps: [], sessionLength: 0, oneAppLock: false),
                      homeSession: Session(apps: [], sessionLength: 0, oneAppLock: false))
    }
}

struct Session: Identifiable, Codable, Equatable {
    var id = UUID() // to make it unique per session
    var apps: [Int]
    var sessionLength: Int
    var oneAppLock: Bool
    
    // Implement the Equatable protocol by defining the == operator
    static func == (lhs: Session, rhs: Session) -> Bool {
        return lhs.apps == rhs.apps &&
        lhs.sessionLength == rhs.sessionLength &&
        lhs.oneAppLock == rhs.oneAppLock
    }
}


struct StudentAppProfile: Identifiable, Codable, Equatable, Hashable {
    
    var id: Int
    var locationId: Int
    var sessions: [String: DailySessions] // Key is the day of the week (e.g., "Sunday")
    
    
    static func == (lhs: StudentAppProfile, rhs: StudentAppProfile) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(locationId)
        // You may want to combine other properties as well, depending on what makes sense for your use case.
    }
    
    mutating func deleteSession(forDay day: String) {
        sessions.removeValue(forKey: day)
    }
    
    mutating func replaceSession(forDay day: String, with newSession: DailySessions) {
        sessions[day] = newSession
    }

}




//struct StudentAppProfile: Identifiable, Codable {
//    var id: Int
//    var locationId: Int
////    var dayOfWeek: Int
//
//    var sunAmSessionApps: [Int]
//    var sunAmSessionLength: Int
//    var sunAmOneAppLock: Bool
//    var sunPmSessionApps: [Int]
//    var sunPmSessionLength: Int
//    var sunPmOneAppLock: Bool
//    var sunHomeSessionApps: [Int]
//    var sunHomeSessionLength: Int
//    var sunHomeOneAppLock: Bool
//
//    var monAmSessionApps: [Int]
//    var monAmSessionLength: Int
//    var monAmOneAppLock: Bool
//    var monPmSessionApps: [Int]
//    var monPmSessionLength: Int
//    var monPmOneAppLock: Bool
//    var monHomeSessionApps: [Int]
//    var monHomeSessionLength: Int
//    var monHomeOneAppLock: Bool
//
//    var tuesAmSessionApps: [Int]
//    var tuesAmSessionLength: Int
//    var tuesAmOneAppLock: Bool
//    var tuesPmSessionApps: [Int]
//    var tuesPmSessionLength: Int
//    var tuesPmOneAppLock: Bool
//    var tuesHomeSessionApps: [Int]
//    var tuesHomeSessionLength: Int
//    var tuesHomeOneAppLock: Bool
//
//    var wedAmSessionApps: [Int]
//    var wedAmSessionLength: Int
//    var wedAmOneAppLock: Bool
//    var wedPmSessionApps: [Int]
//    var wedPmSessionLength: Int
//    var wedPmOneAppLock: Bool
//    var wedHomeSessionApps: [Int]
//    var wedHomeSessionLength: Int
//    var wedHomeOneAppLock: Bool
//
//    var thursAmSessionApps: [Int]
//    var thursAmSessionLength: Int
//    var thursAmOneAppLock: Bool
//    var thursPmSessionApps: [Int]
//    var thursPmSessionLength: Int
//    var thursPmOneAppLock: Bool
//    var thursHomeSessionApps: [Int]
//    var thursHomeSessionLength: Int
//    var thursHomeOneAppLock: Bool
//
//    var friAmSessionApps: [Int]
//    var friAmSessionLength: Int
//    var friAmOneAppLock: Bool
//    var friPmSessionApps: [Int]
//    var friPmSessionLength: Int
//    var friPmOneAppLock: Bool
//    var friHomeSessionApps: [Int]
//    var friHomeSessionLength: Int
//    var friHomeOneAppLock: Bool
//
//    var satAmSessionApps: [Int]
//    var satAmSessionLength: Int
//    var satAmOneAppLock: Bool
//    var satPmSessionApps: [Int]
//    var satPmSessionLength: Int
//    var satPmOneAppLock: Bool
//    var satHomeSessionApps: [Int]
//    var satHomeSessionLength: Int
//    var satHomeOneAppLock: Bool
//
//}


