//
//  FireStoreManager.swift
//  CaptureFBNotifications
//
//  Created by Steven Hertz on 6/22/23.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift

typealias NetworkResponse = (data: Data, response: URLResponse)


class FirestoreManager: ObservableObject {
    @Published var name: String = ""
    @Published var errorMessage: String = ""
        // FirestoreManager.swift
    init() {
//        fetchRestaurant()
//        addListener()
    }
}


//  MARK: -  for montoring for changes
extension FirestoreManager {
    
/*
    func fetchRestaurant() {
        let db = Firestore.firestore()
        let docRef = db.collection("Observables").document("Test")
        
        docRef.getDocument { (document, error) in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let data = data {
                    print("data", data)
                    self.name = data["name"] as? String ?? ""
                }
            }
        }
    }
 */
    
//  called in class init
    func addListener()  {
        let db = Firestore.firestore()
        let docRef = db.collection("Observables").document("Test")
        
        docRef.addSnapshotListener { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data: \(dataDescription)")
                self.name = dataDescription
                var goto = "app"
                if dataDescription.contains("log") {
                    goto = "log"
                }
                    // Perform desired operations...
                Task {
                    do {
                        try await self.gotoSomewhere(goto: goto)
                        if goto == "app" {
                            try await Task.sleep(for: .seconds(55) )
                            try await self.gotoSomewhere(goto: "log")
                        }
                        
                    }
                    catch ApiError.clientBadRequest(let httpResponse) {
                            // Handle clientBadRequest error
                        print("Client bad request error: \(httpResponse)")
                    } catch ApiError.clientUnauthorized(let httpResponse) {
                            // Handle clientUnauthorized error
                        print("Client unauthorized error: \(httpResponse)")
                    } catch ApiError.clientForbidden(let httpResponse) {
                            // Handle clientForbidden error
                        print("Client forbidden error: \(httpResponse)")
                    } catch ApiError.clientNotFound(let httpResponse) {
                            // Handle clientNotFound error
                        print("Client not found error: \(httpResponse)")
                    } catch ApiError.serverError(let httpResponse) {
                            // Handle serverError
                        print("Server error: \(httpResponse)")
                    } catch {
                            // Handle any other errors
                        print("An error occurred: \(error)")
                    }                }
                
            } else {
                print("Document does not exist")
            }
        }
    }
    
//   called by init and setToScreen
    fileprivate func processNetworkCallResult(_ respnseOfNetworkCall: NetworkResponse) throws {
        if let httpResponse = respnseOfNetworkCall.response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200...299:
                print("Successful response - Code: \(httpResponse.statusCode)")
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: respnseOfNetworkCall.data, options: []) as? [String: Any] {
                        print(jsonDict)
                    }
                } catch {
                    print("Error deserializing JSON: \(error.localizedDescription)")
                }
                
            case 400:
                throw ApiError.clientBadRequest(hTTPuRLResponse: httpResponse)
            case 401:
                throw ApiError.clientUnauthorized(hTTPuRLResponse: httpResponse)
            case 403:
                throw ApiError.clientForbidden(hTTPuRLResponse: httpResponse)
            case 404:
                throw ApiError.clientNotFound(hTTPuRLResponse: httpResponse)
            case 500...599:
                throw ApiError.serverError(hTTPuRLResponse: httpResponse)
            default:
                throw ApiError.unexpected(hTTPuRLResponse: httpResponse)
            }
        }
    }
    
    func gotoSomewhere(goto which: String) async throws {
        print("Return to login")
        
        try await removeRestrictions()
        
            //        let duration = UInt64(1.5 * 1_000_000_000)
        try await Task.sleep(nanoseconds: UInt64(3 * 1_000_000_000))
        
        try await setToScreen(goto: which)
        
        
    }
    
    func removeRestrictions() async throws {
        print("removing Restrictions")
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        guard var url = URL(string: "https://developitsnfrEDU.jamfcloud.com/api/teacher/lessons/stop") else {return}
        let URLParams = [
            "token": "5a0f06612f074717a702e264a4e35c71",
        ]
//        url = URL.appendingQueryParameters(URLParams)
        url = url.appendingQueryParameters(URLParams)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
            // Headers
        request.addValue("Basic NjUzMTkwNzY6TUNTTUQ2VkM3TUNLVU5OOE1KNUNEQTk2UjFIWkJHQVY=", forHTTPHeaderField: "Authorization")
        request.addValue("2", forHTTPHeaderField: "X-Server-Protocol-Version")
        request.addValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
            // Body
        let bodyString = "{\n  \"students\": \"9\",\n  \"apps\": \"com.developItSolutions.PersonalLogin\",\n  \"clearAfter\": \"20\"\n}"
        request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
        
        let respnseOfNetworkCall: NetworkResponse = try await session.data(for: request)
        
        try processNetworkCallResult(respnseOfNetworkCall)
        
    }
    
    func setToScreen(goto which: String) async throws {
        print("adHoc whitelist")
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        guard var URL = URL(string: "https://developitsnfrEDU.jamfcloud.com/api/teacher/apply/applock") else {return}
        let URLParams = [
            "token": "5a0f06612f074717a702e264a4e35c71",
        ]
        URL = URL.appendingQueryParameters(URLParams)
        var request = URLRequest(url: URL)
        request.httpMethod = "POST"
        
            // Headers
        request.addValue("Basic NjUzMTkwNzY6TUNTTUQ2VkM3TUNLVU5OOE1KNUNEQTk2UjFIWkJHQVY=", forHTTPHeaderField: "Authorization")
        request.addValue("2", forHTTPHeaderField: "X-Server-Protocol-Version")
        request.addValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
            // Body
        var bodyString = ""
        if which.contains("log") {
            bodyString = "{\n  \"students\": \"9\",\n  \"apps\": \"com.developItSolutions.PersonalLogin\",\n  \"clearAfter\": \"20\"\n}"
        } else {
            bodyString = "{\n  \"students\": \"9\",\n  \"apps\": \"com.sevenacademy.busyshape\",\n  \"clearAfter\": \"20\"\n}"
        }
        request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
        
        print(request.url?.absoluteString)
        
        let respnseOfNetworkCall: NetworkResponse = try await session.data(for: request)
        
        try processNetworkCallResult(respnseOfNetworkCall)
    }
    

}



//  MARK: -  writing and reading to fire store
extension FirestoreManager {
    
    
    // write
    func writeStudentProfileNew(studentProfile: StudentAppProfilex) {
        let db = Firestore.firestore()
        let docRef = db.collection("studentProfiles").document("\(studentProfile.id)")
        
        do {
            try docRef.setData(from: studentProfile)
        } catch let error {
            print("Error writing studentProfile to Firestore: \(error)")
        }
    }
    

    func readStudentProfileNew() {
        let db = Firestore.firestore()
        let docRef = db.collection("studentProfiles").document("99")
        docRef.getDocument(as: StudentAppProfilex.self) { result in
            switch result {
            case .success(let studentAppProfilex):
                dump(studentAppProfilex)
            case .failure(let error):
                if let err = error as NSError?,
                   err.domain == FirestoreErrorDomain,
                   err.code == FirestoreErrorCode.unavailable.rawValue {
                    print("No internet connection.")
                } else if let decodingError = error as? DecodingError {
                    print("Decoding error: \(decodingError)")
                } else {
                    print("Unknown error: \(error)")
                }
            }
        }
    }
    
    // read
    func readStudentProfileNew(studentID: Int, completion: @escaping (StudentAppProfilex?, Error?) -> Void) {
        let db = Firestore.firestore()
        let docRef = db.collection("studentProfiles").document("\(studentID)")
        
        
        func processDecodingError(_ error: Error) {
            switch error {
            case DecodingError.typeMismatch(_, let context),
                 DecodingError.valueNotFound(_, let context),
                 DecodingError.keyNotFound(_, let context):
                self.errorMessage = "\(error.localizedDescription): \(context.debugDescription)"
            case DecodingError.dataCorrupted(let key):
                self.errorMessage = "\(error.localizedDescription): \(key)"
            default:
                self.errorMessage = "Error decoding document: \(error.localizedDescription)"
            }
        }
        
//        let source = FirestoreSource.server
//
        docRef.getDocument() { (documentSnapshot, error) in
        
//        docRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                // Handle the error here (invalid document ID or other issue)
                print("Error fetching document: \(error)")
                return
            }
            
            guard let documentSnapshot = documentSnapshot, documentSnapshot.exists else {
                // Document ID is invalid or document doesn't exist
                print("Document does not exist.")
                return
            }

            if documentSnapshot.metadata.isFromCache {
                  print("Data was retrieved from cache.")
              } else {
                  print("Data was retrieved from server.")
              }

           do {
               let studentAppProfilex = try documentSnapshot.data(as: StudentAppProfilex.self)
               // Use the 'model' instance
                dump(studentAppProfilex)
                completion(studentAppProfilex, nil)

           } catch let error {
               // Handle error in decoding
               print("Error decoding document: \(error)")
                processDecodingError(error)
           }

        }
        
    }

    // read whole collections
    static func checkFireStoreError(_ err: NSError) {
            // Check the error code and domain to see if it's a network error
        if err.domain == FirestoreErrorDomain {
            switch err.code {
            case FirestoreErrorCode.unavailable.rawValue:
                    // Handle network unavailable error
                print("No internet connection.")
            default:
                    // Handle other errors
                print("Firestore error: \(err.localizedDescription)")
            }
        }
    }
    
    static func getAllProfiles() async throws -> [StudentAppProfilex] {
        let db = Firestore.firestore()
        let colRef = db.collection("studentProfiles")
        
        do {
            let source = FirestoreSource.server
            let snapshot = try await colRef.getDocuments(source: source)
            
            var studentProfiles = [StudentAppProfilex]()
            for doc in snapshot.documents {
                let prf = try doc.data(as: StudentAppProfilex.self)
                studentProfiles.append(prf)
            }
            
            return studentProfiles
        }
        
        catch {
            if let err = error as NSError? {
                checkFireStoreError(err)
            }
            
            // Rethrow the error if you want it to be handled further up the chain
            throw error
        }
    }
    
    static func getAllProfiles3() async throws -> [StudentAppProfilex] {
        var collRef: CollectionReference  {
            let db      = Firestore.firestore()
            return db.collection("studentProfiles")
        }
        
        
//        do {
            let source = FirestoreSource.server
            let snapshot = try await collRef.getDocuments(source: source)
            
            var studentProfiles = [StudentAppProfilex]()
            for doc in snapshot.documents {
                let prf = try doc.data(as: StudentAppProfilex.self)
                studentProfiles.append(prf)
            }
            
            return studentProfiles
//        }
        
      /*  catch {
            if let err = error as NSError? {
                // Check the error code and domain to see if it's a network error
                if err.domain == FirestoreErrorDomain {
                    switch err.code {
                    case FirestoreErrorCode.unavailable.rawValue:
                        // Handle network unavailable error
                        print("No internet connection.")
                    default:
                        // Handle other errors
                        print("Firestore error: \(err.localizedDescription)")
                    }
                }
            }
            
            // Rethrow the error if you want it to be handled further up the chain
            throw error
        }
       */
    }
    
    // read whole collections
    static func getAllProfiles2() async throws -> [StudentAppProfilex] {
        let db      = Firestore.firestore()
        let colRef  = db.collection("studentProfiles")
        var colx: CollectionReference  {
            let db      = Firestore.firestore()
            return db.collection("studentProfiles")
        }
        
        
//        do {
            let source = FirestoreSource.server
            let snapshot = try await colRef.getDocuments(source: source)
            
            var studentProfiles = [StudentAppProfilex]()
            for doc in snapshot.documents {
                let prf = try doc.data(as: StudentAppProfilex.self)
                studentProfiles.append(prf)
            }
            
            return studentProfiles
//        }
        
      /*  catch {
            if let err = error as NSError? {
                // Check the error code and domain to see if it's a network error
                if err.domain == FirestoreErrorDomain {
                    switch err.code {
                    case FirestoreErrorCode.unavailable.rawValue:
                        // Handle network unavailable error
                        print("No internet connection.")
                    default:
                        // Handle other errors
                        print("Firestore error: \(err.localizedDescription)")
                    }
                }
            }
            
            // Rethrow the error if you want it to be handled further up the chain
            throw error
        }
       */
    }
    
}



/*
//  MARK: -  works but the old way before firestore support codable
extension FirestoreManager {
    
    func readStudentProfile(byID id: Int, completion: @escaping (StudentAppProfilex?, Error?) -> Void) {
        let db = Firestore.firestore()
        let docRef = db.collection("studentProfiles").document("\(id)")
        
        docRef.getDocument { (document, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let document = document, document.exists,
               let data = document.data() {
                do {
                        // Convert dictionary to JSON data
                    let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                    
                        // Decode JSON data to StudentAppProfilex object
                    let profile = try JSONDecoder().decode(StudentAppProfilex.self, from: jsonData)
                    completion(profile, nil)
                    
                } catch let error {
                    print("Error converting document data to StudentAppProfilex: \(error)")
                    completion(nil, error)
                }
            } else {
                completion(nil, NSError(domain: "AppError", code: 404, userInfo: ["message": "Document not found"]))
            }
        }
    }

    
    func writeToFirestore(theScreen writeThis: String )  {
        let db = Firestore.firestore()
        let docRef = db.collection("Observables").document("Test")
        
        docRef.setData(["name" : writeThis]) { error in
            if let error = error {
                print("There was an error \(error)")
            } else  {
                print("firestore write worked")
            }
        }
    }
    
    func writeStudentProfile(studentProfile: StudentAppProfilex) {
        let db = Firestore.firestore()
        let docRef = db.collection("studentProfiles").document("\(studentProfile.id)")
        
        if let studentProfileDict = studentProfile.convertToDictionary() {
            do {
                try docRef.setData(studentProfileDict)
            } catch let error {
                print("Error writing studentProfile to Firestore: \(error)")
            }
        }
    }

}
*/

extension FirestoreManager {
    
    
    enum ProfileError: Error {
        case missingCollection   (String)
        // This function provides a readable description of the error
        var description: String {
            switch self {
            case .missingCollection(_):
                return "Error: Collection not found"
            }
        }
    }
    
    
    //  MARK: -  Get Documents in a collection
    
    func getAllAppCategories10with(collectionName: String = "appCategories") async throws -> QuerySnapshot {
        var collRef: CollectionReference {
            let db = Firestore.firestore()
            return db.collection(collectionName)
        }
        
        let snapshot = try await collRef.getDocuments(source: FirestoreSource.server)
        
        if snapshot.documents.isEmpty {
            throw ProfileError.missingCollection("collection name returned no ducuments")
        }
        
        return snapshot
    }
    
    
    func fetchAndHandleAppCategories10(collectionName: String = "appCategories") async -> [AppCategory] {
    
    var appCategories: [AppCategory] = []
    
    do {
        let snapshot = try await self.getAllAppCategories10with(collectionName: collectionName)

        for doc in snapshot.documents {
            let appCtg = try doc.data(as: AppCategory.self)
            appCategories.append(appCtg)
        }

        // Process the AppCategories as you need
        print(appCategories)
    }
    catch {
        handleError(error: error, funcName: #function)
    }
    
    return appCategories

}
    
    
    
    func getAllProfiles10with(collectionName: String = "studentProfiles") async throws -> QuerySnapshot {
        var collRef: CollectionReference {
            let db = Firestore.firestore()
            return db.collection(collectionName)
        }
        
        let snapshot = try await collRef.getDocuments(source: FirestoreSource.server)
        
        if snapshot.documents.isEmpty {
            throw ProfileError.missingCollection("collection name returned no ducuments")
        }
        
        return snapshot
    }
    
    
    func fetchAndHandleProfiles10(collectionName: String = "studentProfiles") async -> [StudentAppProfilex] {
    
    var studentProfiles: [StudentAppProfilex] = []
    
    do {
        let snapshot = try await self.getAllProfiles10with(collectionName: collectionName)

        for doc in snapshot.documents {
            let prf = try doc.data(as: StudentAppProfilex.self)
            studentProfiles.append(prf)
        }

        // Process the profiles as you need
        print(studentProfiles)
    }
    catch {
        handleError(error: error, funcName: #function)
    }
    
    return studentProfiles

}
    
    
    
    // write
    func writeAppCategory(appCategory: AppCategory) {
        let db = Firestore.firestore()
        let docRef = db.collection("appCategories").document("\(appCategory.id)")
        
        do {
            try docRef.setData(from: appCategory)
        } catch let error {
            print("Error writing studentProfile to Firestore: \(error)")
        }
    }

    
    
    
    //  MARK: -  Write a Student
    func writeHandleStudentProfileNew2(studentProfile: StudentAppProfilex)  async  {
        do {
            try await writeStudentProfileNew2(studentProfile: studentProfile)
            print("add student worked")
        }
        catch {
            self.handleError(error: error, funcName: #function)
        }
    }
    
    func writeStudentProfileNew2(studentProfile: StudentAppProfilex) async throws {
        let db = Firestore.firestore()
        let docRef = db.collection("studentProfiles").document("\(studentProfile.id)")

        // Use withCheckedThrowingContinuation to properly wait for server confirmation
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try docRef.setData(from: studentProfile, merge: true) { error in
                    if let error = error {
                        print("Error writing to Firestore server: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else {
                        print("Successfully wrote student profile to Firestore server")
                        continuation.resume()
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }


    //  MARK: -  Detete a app category
    func deleteAppCategoryWith(_ appCategoryID: String) {
        let db = Firestore.firestore()
        let docRef = db.collection("appCategories").document(appCategoryID)
        
        docRef.delete { theError in
            if let theError = theError {
                self.handleError(error: theError, funcName: #function)
            }
        }
    }




    
    //  MARK: -  Read a Student
    func readStudentProfileWith(_ studentID: String,
                                completion:  @escaping (StudentAppProfilex) -> () ) {
        let db = Firestore.firestore()
        let docRef = db.collection("studentProfiles").document(studentID)
        
        docRef.getDocument(as: StudentAppProfilex.self) { result in
            
            // kickout error condition to be handled
            guard let profile = try? result.get() else {
                if case .failure(let theError) = result {
                    self.handleError(error: theError, funcName: #function)
                }
                return
            }
            

            // process the received profile
            completion(profile)
            self.handleSuccess(profile: profile)

            
        }
    }

    func handleSuccess(profile: StudentAppProfilex) {
        dump(profile)
        print("Student profile: \(profile)")
    }
    
    
   
//  MARK: -  Here are the error handling stuff
    func handleError(error: Error, funcName: String ) {
        
        switch error {
    
        case let nsError as NSError where nsError.domain == FirestoreErrorDomain:
            handleFirestoreError(nsError: nsError, funcName: funcName)
        
        case let decodingError as DecodingError:
            handleDecodingError(decodingError: decodingError, funcName: funcName)
            
        case let profileError as ProfileError:
            handleProfileError(profileError: profileError,funcName: funcName)

        
        default:
            print("Unknown error occurred: \(error)")
        }
    }

    func handleFirestoreError(nsError: NSError,  funcName: String) {
        if nsError.code == FirestoreErrorCode.unavailable.rawValue {
            print("At Function: \(funcName) - Network is down.")
        } else {
            print("At Function: \(funcName) - Firestore Error Code: \(nsError.code)")
        }
    }

    func handleDecodingError(decodingError: DecodingError, funcName: String) {
        switch decodingError {
        case .typeMismatch(let type, let context):
            print("At Function: \(funcName) - Type mismatch for type \(type): \(context)")
        case .valueNotFound(let type, let context):
            print("At Function: \(funcName) - Also for Rec Not Found -Value missing for type \(type): \(context)")
        case .keyNotFound(let key, let context):
            print("At Function: \(funcName) - Key '\(key)' not found: \(context)")
        case .dataCorrupted(let context):
            print("At Function: \(funcName) - Data corrupted: \(context)")
        default:
            print("At Function: \(funcName) - Decoding error: \(decodingError)")
        }
    }
    
    func handleProfileError(profileError: ProfileError, funcName: String) {
        switch profileError {
        case .missingCollection(let messg):
            print("missing collection: -  \(messg)")
        default:
            print("Unknown error: \(profileError.localizedDescription)")
        }
    }
  
  func getaStudentFB(collectionName: String = "studentProfiles", studentID: Int) async throws -> DocumentSnapshot {
    
    var docRef: DocumentReference {
      let db = Firestore.firestore()
      let docRef = db.collection("studentProfiles").document("\(studentID)")
      return docRef
    }
    
    let docSnapshot = try await docRef.getDocument(source: FirestoreSource.server)
    
    if !docSnapshot.exists  {
      throw ProfileError.missingCollection("collection name returned no ducuments")
    }
    
    return docSnapshot
  }
  
  


  func getaStudent(collectionName: String = "studentProfiles", studentID: Int) async -> StudentAppProfilex {
    var prf: StudentAppProfilex?
    
    do {
      let docSnapshot = try await self.getaStudentFB(collectionName: collectionName,  studentID: studentID)
      prf = try docSnapshot.data(as: StudentAppProfilex.self)
    }
    catch {
      handleError(error: error, funcName: #function)
    }
    
    guard let prf = prf else { fatalError("prf error")}
    return prf
  }
  

}


//
//    /// Define your custom errors
//enum ApiError: LocalizedError {
//    case invalidPath
//    case clientBadRequest(hTTPuRLResponse: HTTPURLResponse)
//    case clientUnauthorized(hTTPuRLResponse: HTTPURLResponse)
//    case clientForbidden(hTTPuRLResponse: HTTPURLResponse)
//    case clientNotFound(hTTPuRLResponse: HTTPURLResponse)
//    case serverError(hTTPuRLResponse: HTTPURLResponse)
//    case unexpected (hTTPuRLResponse: HTTPURLResponse)
//    case decodingError(decodingStatus: Error)
//}

//extension ApiError {
//    
//    var description: String {
//        switch self {
//        case .invalidPath:
//            return "Invalid Path"
//        case .clientBadRequest:
//            return "Bad Request"
//        case .clientUnauthorized:
//            return "Unauthorized access to API resource"
//        case .clientForbidden:
//            return "client lacks the necessary authorization to access the resource"
//        case .clientNotFound:
//            return "API resource not found"
//        case .serverError(hTTPuRLResponse: let hTTPuRLResponse):
//            return "Server Error code: \(hTTPuRLResponse)"
//        case .unexpected(hTTPuRLResponse: let hTTPuRLResponse):
//            return "Unexpected Error code: \(hTTPuRLResponse)"
//        case .decodingError(decodingStatus: let decodingStatus):
//            return "Decoding Error code: \(decodingStatus)"
//            
//        default:
//            return "Other error not defined"
//        }
//    }
//    
//}
