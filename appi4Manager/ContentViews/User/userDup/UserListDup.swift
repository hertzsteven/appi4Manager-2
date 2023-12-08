    //
    //  ContentView.swift
    //  list the users
    //
    //  Created by Steven Hertz on 2/8/23.
    //

import SwiftUI


struct UserListDup: View {

//   MARK: - Body View   * * * * * * * * * * * * * * * * * * * * * * * *
    @Binding var path: NavigationPath

    @State private var searchText = ""
    
    @State private var presentAlertSw: Bool = false
    
    @EnvironmentObject var teacherItems: TeacherItems

    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var studentPicStubViewModel: StudentPicStubViewModel
    // @EnvironmentObject var appWorkViewModel: AppWorkViewModel
    
    @State var newUser: User
    @State private var isAddingNewUser = false
    
    @State var usersAreLoaded: Bool = false
    
    @Environment(\.horizontalSizeClass)     var horizontalSizeClass
    @Environment(\.verticalSizeClass)         var verticalSizeClass
    
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 100, maximum: .infinity)), count: numberOfColumns)
    }
    
    private var numberOfColumns: Int {
        return horizontalSizeClass == .compact ? 2 : 4
    }
    
    
    @State private var hasError = false
    @State private var error: ApiError?


    
    var body: some View {
        ZStack {
            
            if usersViewModel.isLoading {
                VStack {
                    ProgressView().controlSize(.large).scaleEffect(2)
                }
            } else {
                
                ScrollView {
                    
                    LazyVGrid(columns: gridItems, spacing: 30) {
                        
                        ForEach(usersViewModel.sortedUsersNonB(lastNameFilter: searchText, selectedLocationID: teacherItems.selectedLocationIdx, teacherUserID: teacherItems.teacherUserDict[teacherItems.selectedLocationIdx]!) ) {  theUser  in
                            
                            let imageURL = imageURLWithUniqueID(studentPicStubViewModel.getURLpicForStudentWith(theUser.id), uniqueID: teacherItems.uniqueID)
                            
                            UserCardVwDup(user: theUser, urlPic: imageURL)
                                .foregroundColor(Color.primary)
                                .font(.body)
                                .padding([.top, .bottom],10)
                        }
                        
                    } // end of for each
                } // end of list
            }
        }


//      MARK: - Toolbar   * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
        .toolbar {
        // add user
            ToolbarItem {
                Button {
                    newUser = User.makeDefault()
                    isAddingNewUser = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading , content: {
                // select Location
                Menu {
                    Picker("Pick a location", selection: $teacherItems.selectedLocationIdx) {
                        ForEach(0..<teacherItems.MDMlocations.count) { index in
                            Text(teacherItems.MDMlocations[index].name)
                                .tag(index)
                        }
                    }
                    .padding()
                    .onChange(of:  teacherItems.selectedLocationIdx) { value in
                            // Execute your code here
                        Task {
                            do {
                                studentPicStubViewModel.reloadData(uuid: teacherItems.getpicClass())
                                print("--- Selected location picked")
                            } catch let error as ApiError {
                                print(error.description)
                            }
                            
                        }
                        
                        print("--- Selected location: tea.locations[value].name")
                    }
                    
                        //                    .pickerStyle(.wheel)
                } label: {
                    Text(teacherItems.MDMlocations[teacherItems.selectedLocationIdx].name).padding()
                }
                .pickerStyle(.menu)
                
            })
        }
        
        
//      MARK: - Popup  Sheets  * * * * * * * * * * * * * * * * * * * * * * * *
        .sheet(isPresented: $isAddingNewUser) {
            NavigationView {
                UserEditorContDup( path: $path, user: newUser,
                                   urlPic: URL(string: "https://developitsnfredu.jamfcloud.com/application/views/default/assets/image/avatar/avatar.png")!,
                                   userInitialValues: newUser,
                                   isNew: true)
//                UserEditorContent( user: $newUser, urlPic: URL(string: "https://developitsnfredu.jamfcloud.com/application/views/default/assets/image/avatar/avatar.png")!, isNew: true)
            }
        }
        
//      MARK: -alerts  * * * * * * * * * * * * * * * * * * * * * * * *
        .alert(isPresented: $hasError,
               error: error) {
            Button {
                Task {
                    await loadTheUsers()
                }
            } label: {
                Text("Retry")
            }
        }

        .alert(isPresented:$presentAlertSw) {
            getAlert()
        }


//      MARK: - Navigation Bar  * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *        
        .navigationTitle("Students")
        .navigationBarTitleDisplayMode(.inline)
        
        
//      MARK: - Navigation Destination   * * * * * * * * * * * * * * * * * * * * * *
        .navigationDestination(for: User.self) { theUser in
            let imageURL = imageURLWithUniqueID(studentPicStubViewModel.getURLpicForStudentWith(theUser.id), uniqueID: teacherItems.uniqueID)
            UserEditorContDup(path: $path, user: theUser,
                              urlPic: imageURL,
                              userInitialValues: theUser)
        }
        
        
//        .task {
//            print("🚘 In outer task")
//            if !usersAreLoaded {
//                
//                
//                Task {
//                    do {
//                        studentPicStubViewModel.reloadData(uuid: appWorkViewModel.getpicClass())
//                    } catch let error as ApiError {
//                        print(error.description)
//                            //                        presentAlertSw.toggle()
//                    }
//                    
//                }
//                
//            }
//        }
 //      MARK: - Task Modifier    * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
        .task {
            if usersViewModel.ignoreLoading {
                usersViewModel.ignoreLoading = false
                // Don't load the classes if ignoreLoading is true
            } else {
                // Load the users if ignoreLoading is false
                await loadTheUsers()

                usersViewModel.ignoreLoading = false
            }
            
            if !usersAreLoaded {
                await reloadPicStub()
//                Task {
//                    do {
//                        studentPicStubViewModel.reloadData(uuid: appWorkViewModel.getpicClass())
//                    } catch let error as ApiError {
//                        print(error.description)
//                            //                        presentAlertSw.toggle()
//                    }
//
//                }
            }
        }
    }
    
    func getAlert() -> Alert {
        return Alert(title: Text("This is a second alert"))
    }
    
    func imageURLWithUniqueID(_ photoURL: URL, uniqueID: UUID) -> URL {
        var urlComponents = URLComponents(url: photoURL, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [URLQueryItem(name: "uniqueID", value: uniqueID.uuidString)]
        return urlComponents?.url ?? photoURL
    }
    
}

private extension UserListDup {
    
    func loadTheUsers() async {
        do {
            try await usersViewModel.loadData2()
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }
    
    func reloadPicStub() async {
        do {
            try await studentPicStubViewModel.reloadData2(uuid: teacherItems.getpicClass())
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }

}

//struct UserListDupView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserListDup(path: $path, newUser: User.makeDefault())
//    }
//}
