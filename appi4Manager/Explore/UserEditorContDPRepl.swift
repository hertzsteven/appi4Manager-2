  //
  //  UserEditorContDPRepl.swift
  //  appi4Manager
  //
  //  Created by Steven Hertz on 8/2/24.
  //

import SwiftUI

struct UserEditorContDPRepl: View {
  @Binding var path: NavigationPath
  @StateObject private var profilesViewModel = ProfilesViewModel()
  
  var body: some View {
    ZStack {
      VStack {
        Form {
          Text("Hello, World!")
          Button {
            Task {
              path.append(5)
            }
            print("hello")
          } label: {
            Text("Make student app profile")
          }
          
          .navigationDestination(for: Int.self) { studentId in
            
            let _ = print(studentId, "jdjdjdjdj \(profilesViewModel.profilesx[2].id)")
            if let studentFound = profilesViewModel.profilesx.first { $0.id == studentId} {
              StudentAppProfilxWorkingView(
                studentId                   : studentId,
                studentName                 : "Sam Ashe",
                //                                        studentAppProfilefiles: profilesViewModel.profilesx,
                profileManager: StudentAppProfileManager())
                //                                        studentAppprofile           :  studentFound)
            } else {
              Text("not found")
            }
          }
        }
      }
    }
  }
}

#Preview {
  // Create a state variable for the NavigationPath
  var previewState = State(initialValue: NavigationPath())
  
  return UserEditorContDPRepl(path: previewState.projectedValue)
}
