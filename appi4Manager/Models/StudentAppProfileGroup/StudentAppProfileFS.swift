//
//  StudentAppProfileFS.swift
//  appi4Manager
//
//  Created by Steven Hertz on 7/22/24.
//

import Foundation
class StudentAppProfileFS: Identifiable, ObservableObject {
                var id              : Int
                var locationId      : Int
    @Published  var sessions        : [String: DailySessions] = [:]
    @Published var appCount = 0
    
    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case locationId
//        case sessions
//    }

    init() {
        self.id = 0
        self.locationId = 0
        self.sessions = [:]
    }

    init(id: Int,
         locationId: Int ) {
        self.id          = id
        self.locationId  = locationId
        loadDailySessions(studentID: id)
//        self.sessions    = sessions
    }
    
    func loadDailySessions(studentID: Int)  {
        Task {
            await setStudentProfile(studentID: studentID)
        }
    }
    
    private func setStudentProfile(studentID: Int)  {
        FirestoreManager().readStudentProfileNew(studentID: studentID) { studentAppProfilex, err in
            guard let studentAppProfilex = studentAppProfilex else {
                fatalError("could not retreive the student profile")
            }
//            self.id          = studentAppProfilex.id
//            self.locationId  = studentAppProfilex.locationId
            DispatchQueue.main.async {
                self.sessions    = studentAppProfilex.sessions
                self.appCount = (studentAppProfilex.sessions["Mon"]?.pmSession.apps.count)!
            }
        }
    }
    
}
