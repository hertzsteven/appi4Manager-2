//
//  DailySessionConfiguration.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/18/23.
//

import Foundation

struct DailySessionConfiguration {
    var oneAppLockAM:           Bool
    var appCodeAM:              Int
    var sessionLengthAM:        Double {
        didSet {
            sessionLengthDoubleAM = Double(sessionLengthAM)
        }
    }
    var sessionLengthDoubleAM:  Double
    
    var oneAppLockPM:           Bool
    var appCodePM:              Int
    var sessionLengthPM:        Double {
        didSet {
            sessionLengthDoublePM = Double(sessionLengthPM)
        }
    }
    var sessionLengthDoublePM:  Double
}
