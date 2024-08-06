//
//  TestMVVMView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 7/22/24.
//

import SwiftUI

@MainActor
class ProfilesViewModel: ObservableObject {
    @Published var profilesx: [StudentAppProfilex] = []
    @Published var isLoading: Bool = true
    
//    init() {
//        loadProfiles()
//    }
  
//    init() {
//        Task {
//            await loadProfilesWithDelay()
//        }
//    }

    init() {
        Task {
            self.isLoading = true
            let fetchedProfiles = await StudentAppProfileManager.loadProfilesx()
            self.profilesx = fetchedProfiles
            self.isLoading = false
        }
    }

    private func loadProfilesWithDelay() async {
        // Introduce a delay (e.g., 3 seconds)
        try? await Task.sleep(nanoseconds: 5 * 1_000_000_000) // 3 seconds
        await loadProfiles()
    }
 
    
    func loadProfiles() {
        Task {
            self.isLoading = true
            let fetchedProfiles = await StudentAppProfileManager.loadProfilesx()
            self.profilesx = fetchedProfiles
            self.isLoading = false
        }
    }
}

struct TestMVVMView: View {
    
//    @Binding var path: NavigationPath
    @StateObject private var profilesViewModel = ProfilesViewModel()
    
    @State private var navigationPath = NavigationPath()
    @State var profilesx: [StudentAppProfilex] = []
    

    @EnvironmentObject var studentAppProfileManager: StudentAppProfileManager

    @ObservedObject var viewModel: StudentAppProfileFS
    
    init(studentId: Int, locationID: Int)  {
        self.viewModel = StudentAppProfileFS(id: studentId, locationId: locationID)
     }
    
    @State var appCount: Int = 0
    
    var body: some View {
        NavigationStack(path: $navigationPath){
            Text("Hello, World!")
            Text("\(viewModel.appCount)")
                // Show a loading indicator while loading
                if profilesViewModel.isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
          Button {
                      Task {
                        let prf = await FirestoreManager().getaStudent(studentID: 5)
                        dump(prf)
                        print("finished")
                      }
                      print("hello")
                    } label: {
                      Text("get Student")
                    }
           
            Button {
                Task {
//                    profilesx = await StudentAppProfileManager.loadProfilesx()
//                    print("count \(profilesx.count)")
                    navigationPath.append(5)
                }
                    //            studentAppProfileManager
                print("hello")
            } label: {
                Text("Make student app profile")
            }
            .disabled(profilesViewModel.isLoading) // Disable if loading
            

            
//            .task {
//                // Load profilesx after initialization
//                profilesx = await StudentAppProfileManager.loadProfilesx()
//                print("Loaded profiles count: \(profilesx.count)")
//            }

            .navigationDestination(for: Int.self) { studentId in
                
                let _ = print(studentId, "jdjdjdjdj \(profilesViewModel.profilesx[2].id)")
                                if let studentFound = profilesViewModel.profilesx.first { $0.id == studentId} {
                                    StudentAppProfilxWorkingView(
                                        studentId                   : studentId,
                                        studentName                 : "Sam Ashe")
//                                        studentAppProfilefiles: profilesViewModel.profilesx,
//                                        profileManager: StudentAppProfileManager())
//                                        studentAppprofile           :  studentFound)
                                } else {
                                    Text("not found")
                                }
            }
        }
    }
}

//#Preview {
//    TestMVVMView()
//}
