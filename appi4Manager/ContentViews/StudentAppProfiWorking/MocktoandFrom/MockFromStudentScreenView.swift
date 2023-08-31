//
//  MockFromStudentScreenView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 8/28/23.
//

import SwiftUI

struct MockFromStudentScreenView: View {
    var body: some View {
        VStack {
            NavigationLink("Go To Student Profile For Student id 8", value: 8)
        }
        .navigationTitle("Launch Profile for Student 8")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Int.self) { studentId in
            
         let profilesx =  StudentAppProfileViewModel.loadProfiles()
            
            if let studentFound = profilesx.first { $0.id == studentId} {
                MockToStudentScreenView(studentAppProfilefiles: StudentAppProfileViewModel.loadProfiles(), studentId: studentId, studentAppprofile:  studentFound)
            }

        }
    }
    
}

struct MockFromStudentScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MockFromStudentScreenView()
    }
}
