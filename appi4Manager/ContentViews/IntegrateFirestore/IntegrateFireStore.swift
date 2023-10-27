
//
//  ContentView.swift
//  Integrate FireStore
//
//  Created by Steven Hertz on 10/26/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

//class StudentAppProfilex: Identifiable, Codable, ObservableObject {
//                var id              : Int
//                var locationId      : Int
//    @Published  var sessions        : [String: DailySessions]
//
//    enum CodingKeys: String, CodingKey {
//        case id
//        case locationId
//        case sessions
//    }
//
//    required init(from decoder: Decoder) throws {
//        let container  = try decoder.container(keyedBy: CodingKeys.self)
//        id             = try container.decode(Int.self, forKey: .id)
//        locationId     = try container.decode(Int.self, forKey: .locationId)
//        sessions       = try container.decode([String: DailySessions].self, forKey: .sessions)
//    }
//
//    // Implementing the Encodable protocol manually
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(locationId, forKey: .locationId)
//        try container.encode(sessions, forKey: .sessions)
//    }
//
//    func convertToDictionary() -> [String: Any]? {
//        do {
//            let data = try JSONEncoder().encode(self)
//            let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
//            return dictionary
//        } catch {
//            print("Error converting to dictionary: \(error)")
//            return nil
//        }
//    }
//
//
////    init(id: Int, locationId: Int, sessions: [String: DailySessions]) {
////        self.id          = id
////        self.locationId  = locationId
////        self.sessions    = sessions
////    }
//}
//
//
//struct DailySessions: Codable, Equatable {
//    var amSession: Session
//    var pmSession: Session
//    var homeSession: Session
//
//        // Implement the Equatable protocol by defining the == operator
//    static func == (lhs: DailySessions, rhs: DailySessions) -> Bool {
//        return lhs.amSession == rhs.amSession &&
//        lhs.pmSession == rhs.pmSession &&
//        lhs.homeSession == rhs.homeSession
//    }
//
//    static func makeDefaultDailySession() -> DailySessions {
//        DailySessions(amSession: Session(apps: [], sessionLength: 0, oneAppLock: false),
//                      pmSession: Session(apps: [], sessionLength: 0, oneAppLock: false),
//                      homeSession: Session(apps: [], sessionLength: 0, oneAppLock: false))
//    }
//}
//
//struct Session: Identifiable, Codable, Equatable {
//    var id = UUID() // to make it unique per session
//    var apps: [Int]
//    var sessionLength: Double
//    var oneAppLock: Bool
//
//    // Implement the Equatable protocol by defining the == operator
//    static func == (lhs: Session, rhs: Session) -> Bool {
//        return lhs.apps == rhs.apps &&
//        lhs.sessionLength == rhs.sessionLength &&
//        lhs.oneAppLock == rhs.oneAppLock
//    }
//}
//
//
//struct StudentAppProfile: Identifiable, Codable, Equatable, Hashable {
//
//    var id: Int
//    var locationId: Int
//    var sessions: [String: DailySessions] // Key is the day of the week (e.g., "Sunday")
//
//
//    static func == (lhs: StudentAppProfile, rhs: StudentAppProfile) -> Bool {
//        lhs.id == rhs.id
//    }
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//        hasher.combine(locationId)
//        // You may want to combine other properties as well, depending on what makes sense for your use case.
//    }
//
//    mutating func deleteSession(forDay day: String) {
//        sessions.removeValue(forKey: day)
//    }
//
//    mutating func replaceSession(forDay day: String, with newSession: DailySessions) {
//        sessions[day] = newSession
//    }
//
//}

struct IntegrateFireStore: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            Button("Get the 11") {
                readStudentProfileWith { profile in
                    print("from completion handler")
                }
            }
        }
        .padding()
    }
    
        //  MARK: -  Read a Student
        func readStudentProfileWith(_ studentID: String = "11",
                                    completion:  @escaping (StudentAppProfilex) -> () ) {
            let db = Firestore.firestore()
            let docRef = db.collection("studentProfiles").document(studentID)
            
            docRef.getDocument(as: StudentAppProfilex.self) { result in
                
                // kickout error condition to be handled
                guard let profile = try? result.get() else {
                    return
                }
                

                // process the received profile
                dump(profile)
//                completion(profile)
//                self.handleSuccess(profile: profile)

                
            }
        }

}

struct IntegrateFireStore_Previews: PreviewProvider {
    static var previews: some View {
        IntegrateFireStore()
    }
}
