//
//  DailySessions.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/18/23.
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
