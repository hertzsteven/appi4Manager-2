//
//  MockBareBones.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/31/23.
//

import SwiftUI




struct MockBareBones: View {
    @ObservedObject var studentAppprofile: StudentAppProfileFS

    init(studentId: Int, locationID: Int) {
        self.studentAppprofile = StudentAppProfileFS(id: studentId, locationId: locationID)
    }
    
                 var studentAppProfilefiles           : [StudentAppProfilex] = []
    @StateObject var profileManager                   : StudentAppProfileManager = StudentAppProfileManager()
//    @StateObject var studentAppprofile                : StudentAppProfilex

    var body: some View {
        VStack {
            Text("Hello")
            
            HStack {
                Button("Update Sunday") {
                    studentAppprofile.sessions["Sunday"]?.amSession.sessionLength = 44
                    studentAppprofile.sessions["Sunday"]?.amSession.apps.removeAll()
                    studentAppprofile.sessions["Sunday"]?.amSession.apps.append(contentsOf: ["999", "888"])
                    dump(studentAppprofile)
                }
                
                Button("Update Monday") {
                    studentAppprofile.sessions["Monday"]?.amSession.sessionLength = 444
                    studentAppprofile.sessions["Monday"]?.amSession.apps.removeAll()
                    studentAppprofile.sessions["Monday"]?.amSession.apps.append(contentsOf: ["555", "444"])
                    dump(studentAppprofile)
//                    profileManager.updateStudentAppProfile(newProfile: studentAppprofile)
//                    dump(profileManager.studentAppProfileFiles)
                    print("finished")
                }
            }
        }
        .onAppear {
//            profileManager.studentAppProfileFiles = studentAppProfilefiles
        }
    }
    

}

struct MockBareBones_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock or sample StudentAppProfileFS instance
        let mockProfile = StudentAppProfileFS(id: 5, locationId: 1)
        
        // Provide the mockProfile to the view
        MockBareBones(studentId: 5, locationID: 1)
            .environmentObject(mockProfile) // Adjust as necessary for your environment setup
    }
}
