//
//  Session.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/18/23.
//

import Foundation

struct Session: Identifiable, Codable, Equatable {
    var id = UUID() // to make it unique per session
    var apps: [String]  // Bundle IDs of selected apps
    var sessionLength: Double
    var oneAppLock: Bool
    
    // Implement the Equatable protocol by defining the == operator
    static func == (lhs: Session, rhs: Session) -> Bool {
        return lhs.apps == rhs.apps &&
        lhs.sessionLength == rhs.sessionLength &&
        lhs.oneAppLock == rhs.oneAppLock
    }
}
