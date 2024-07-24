//
//  StudentAppProfilex.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/18/23.
//

import Foundation

class StudentAppProfilex: Identifiable, Codable, ObservableObject {
                var id              : Int
                var locationId      : Int
    @Published  var sessions        : [String: DailySessions]
    
    enum CodingKeys: String, CodingKey {
        case id
        case locationId
        case sessions
    }

    init() {
        self.id = 0
        self.locationId = 0
        self.sessions = [:]
    }
    required init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        id             = try container.decode(Int.self, forKey: .id)
        locationId     = try container.decode(Int.self, forKey: .locationId)
        sessions       = try container.decode([String: DailySessions].self, forKey: .sessions)
    }

    // Implementing the Encodable protocol manually
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(locationId, forKey: .locationId)
        try container.encode(sessions, forKey: .sessions)
    }

    init(id: Int, locationId: Int, sessions: [String: DailySessions]) {
        self.id          = id
        self.locationId  = locationId
        self.sessions    = sessions
    }
    
    func setStudentProfile(studentID: Int)  {
        FirestoreManager().readStudentProfileNew(studentID: studentID) { studentAppProfilex, err in
            guard let studentAppProfilex = studentAppProfilex else {
                fatalError("could not retreive the student profile")
            }
            self.id          = studentAppProfilex.id
            self.locationId  = studentAppProfilex.locationId
            self.sessions    = studentAppProfilex.sessions
        }
    }
    
    func convertToDictionary() -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            return dictionary
        } catch {
            print("Error converting to dictionary: \(error)")
            return nil
        }
    }

}
