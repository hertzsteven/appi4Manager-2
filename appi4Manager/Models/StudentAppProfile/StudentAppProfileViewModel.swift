//
//  StudentAppProfileViewModel.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/8/23.
//

import Foundation


struct DailySessionConfiguration {
    var oneAppLockAM:           Bool
    var appCodeAM:              Int
    var sessionLengthAM:        Int {
        didSet {
            sessionLengthDoubleAM = Double(sessionLengthAM)
        }
    }
    var sessionLengthDoubleAM:  Double
    
    var oneAppLockPM:           Bool
    var appCodePM:              Int
    var sessionLengthPM:        Int {
        didSet {
            sessionLengthDoublePM = Double(sessionLengthPM)
        }
    }
    var sessionLengthDoublePM:  Double

}


class StudentAppProfileViewModel: ObservableObject {
    @Published var profiles: [StudentAppProfile] = [] {
        didSet {
            if !profiles.isEmpty {
//                saveProfiles()
            }
        }
    }
    @Published var dailySessionConfiguration: [DailySessionConfiguration] =
    Array(repeating: DailySessionConfiguration(
        oneAppLockAM: false,
        appCodeAM: 0,
        sessionLengthAM: 0,
        sessionLengthDoubleAM: 0.0,
        oneAppLockPM: false,
        appCodePM: 0,
        sessionLengthPM: 0,
        sessionLengthDoublePM: 0.0
    ), count: 7)

    
    func addProfile(profile: StudentAppProfile) {
        profiles.append(profile)
        saveProfiles()
    }
    
    func updateProfile(profile: StudentAppProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles()
        }
    }
    
    static func makeDefaultfor(_ id: Int, locationId: Int) -> StudentAppProfile {
         generateSampleProfileforId(id: id, locationId: locationId, apps: [], sessionLength: 0, oneAppLock: false)
    }

    
    static func sampleProfile() -> [StudentAppProfile] {
        
        let sampleProfile1 = generateSampleProfileforId(id: 3, locationId: 0, apps: [11,34], sessionLength: 20, oneAppLock: false)
        let sampleProfile2 = generateSampleProfileforId(id: 8, locationId: 0, apps: [27], sessionLength: 30, oneAppLock: false)
        let sampleProfile3 = generateSampleProfileforId(id: 48, locationId: 0, apps: [34], sessionLength: 15, oneAppLock: true)
        
        return [sampleProfile1, sampleProfile2, sampleProfile3 ]
    }
    
    static func generateSampleProfileforId(id: Int, locationId: Int, apps:[Int], sessionLength: Int, oneAppLock: Bool ) ->  StudentAppProfile {
        let sampleSession = Session(apps: apps, sessionLength: sessionLength, oneAppLock: oneAppLock)
        let sampleDailySessions = DailySessions(amSession: sampleSession, pmSession: sampleSession, homeSession: sampleSession)
        
        let sampleProfile = StudentAppProfile(
            id: id,
            locationId: locationId,
            sessions: [
                "Sunday":       sampleDailySessions,
                "Monday":       sampleDailySessions,
                "Tuesday":      sampleDailySessions,
                "Wednesday":    sampleDailySessions,
                "Thursday":     sampleDailySessions,
                "Friday":       sampleDailySessions,
                "Saturday":     sampleDailySessions
            ]
        )
        return sampleProfile
    }
    
    func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            if let idx = profiles.firstIndex(where: { prf in
                prf.id == 8
            }) {
                    // 5
                dump(profiles[idx])
            }
            UserDefaults.standard.set(encoded, forKey: "StudentProfiles3")
        }
    }
    
    static func loadProfiles() -> [StudentAppProfile] {
        if let savedProfiles = UserDefaults.standard.object(forKey: "StudentProfiles3") as? Data {
            if let decoded = try? JSONDecoder().decode([StudentAppProfile].self, from: savedProfiles) {
                return decoded
            }
        }
        return []
    }
}

