//
//  StudentAppProfileManager.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/18/23.
//

import Foundation


class StudentAppProfileManager: ObservableObject {
    @Published var studentAppProfileFiles: [StudentAppProfilex] = []
//    var firestoreManager = FirestoreManager()
    
    static func loadProfilesx() async -> [StudentAppProfilex] {
        
//        Task {
            let profs = await FirestoreManager().fetchAndHandleProfiles10(collectionName: "studentProfiles")
            dump(profs)
            print("done")
            return profs
//        }

//        let sampleprofiles = StudentAppProfileManager.sampleProfile()
//        StudentAppProfileManager.savePassedProfiles(profilesToSave: sampleprofiles)
//        return sampleprofiles
    }
    
    static func loadProfilesxUserDefaukts() -> [StudentAppProfilex] {
        if let savedProfiles = UserDefaults.standard.object(forKey: "StudentProfiles7") as? Data {
            if let decoded = try? JSONDecoder().decode([StudentAppProfilex].self, from: savedProfiles) {
                if decoded.count == 0 {
                    let sampleprofiles = StudentAppProfileManager.sampleProfile()
                    StudentAppProfileManager.savePassedProfiles(profilesToSave: sampleprofiles)
                    return sampleprofiles
                } else {
                    return decoded
                }
            }
        }
        let sampleprofiles = StudentAppProfileManager.sampleProfile()
        StudentAppProfileManager.savePassedProfiles(profilesToSave: sampleprofiles)
        return sampleprofiles
    }

    func addStudentAppProfile(newProfile: StudentAppProfilex) async {
        DispatchQueue.main.async {
            self.studentAppProfileFiles.append(newProfile)
        }
//        Task {
            await  FirestoreManager().writeHandleStudentProfileNew2(studentProfile: newProfile)
            print("added new student")
//        }
    }
    
    func updateStudentAppProfile(newProfile: StudentAppProfilex) {
        // Update local array if profile exists there
        if let idx = studentAppProfileFiles.firstIndex(where: { $0.id == newProfile.id }) {
            studentAppProfileFiles.remove(at: idx)
            studentAppProfileFiles.append(newProfile)
        }
        
        // Always write to Firestore regardless of local array
        Task {
            do {
                try await FirestoreManager().writeStudentProfileNew2(studentProfile: newProfile)
                print("✅ Successfully updated student profile in Firestore server")
            } catch {
                print("❌ Failed to update student profile in Firestore: \(error.localizedDescription)")
                // Note: You may want to show an alert to the user here
            }
        }
    }
    func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(studentAppProfileFiles) {
            if let idx = studentAppProfileFiles.firstIndex(where: { prf in
                prf.id == 8
            }) {
                    // 5
                dump(studentAppProfileFiles[idx])
            }
            UserDefaults.standard.set(encoded, forKey: "StudentProfiles7")
        }
    }
    
    
    static func savePassedProfiles(profilesToSave: [StudentAppProfilex]) {
        if let encoded = try? JSONEncoder().encode(profilesToSave) {
            UserDefaults.standard.set(encoded, forKey: "StudentProfiles7")
        }
    }
}

// generating Mockes
extension StudentAppProfileManager {
    
    static func makeDefaultfor(_ id: Int, locationId: Int) -> StudentAppProfilex {
         generateSampleProfileforId(id: id, locationId: locationId, apps: [], sessionLength: 0, oneAppLock: false)
    }

    static func sampleProfile() -> [StudentAppProfilex] {
        
        let sampleProfile1 = generateSampleProfileforId(id: 3, locationId: 0, apps: ["com.sample.app1", "com.sample.app2"], sessionLength: 20, oneAppLock: false)
        let sampleProfile2 = generateSampleProfileforId(id: 8, locationId: 0, apps: ["com.sample.app3"], sessionLength: 30, oneAppLock: false)
        let sampleProfile3 = generateSampleProfileforId(id: 48, locationId: 0, apps: ["com.sample.app2"], sessionLength: 15, oneAppLock: true)
        
        return [sampleProfile1, sampleProfile2, sampleProfile3 ]
    }
    
    static func generateSampleProfileforId(id: Int, locationId: Int, apps:[String], sessionLength: Double, oneAppLock: Bool ) ->  StudentAppProfilex {
        let sampleSession = Session(apps: apps, sessionLength: sessionLength, oneAppLock: oneAppLock)
        let sampleDailySessions = DailySessions(amSession: sampleSession, pmSession: sampleSession, homeSession: sampleSession)
        
        let sampleProfile = StudentAppProfilex(
            id: id,
            locationId: locationId,
            sessions: [
                "Sun":       sampleDailySessions,
                "Mon":       sampleDailySessions,
                "Tues":      sampleDailySessions,
                "Wed":    sampleDailySessions,
                "Thurs":     sampleDailySessions,
                "Fri":       sampleDailySessions,
                "Sat":     sampleDailySessions
            ]
        )
        return sampleProfile
    }
    
}
