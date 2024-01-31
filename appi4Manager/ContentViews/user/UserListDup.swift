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

    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var studentPicStubViewModel: StudentPicStubViewModel
    // @EnvironmentObject var appWorkViewModel: AppWorkViewModel
    
    @State var newUser: User
    @State private var isAddingNewUser = false
    
    @State var usersAreLoaded: Bool = false
    
    @Environment(\.horizontalSizeClass)     var horizontalSizeClass
    @Environment(\.verticalSizeClass)         var verticalSizeClass
    
    @State var doGrid = true
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 100, maximum: .infinity)), count: numberOfColumns)
    }
    
    private var numberOfColumns: Int {
        return horizontalSizeClass == .compact ? 2 : 4
    }
    
    
    @State private var hasError = false
    @State private var error: ApiError?

    @State var readyToDoPickerView: Bool = true
    @State var filteredClasses: Array<SchoolClass> {
        didSet {
            if readyToDoPickerView == false {
                readyToDoPickerView.toggle()
            }
        }
    }
    @State var filteredStudents: Array<User>
//        SchoolClass(uuid: "uuid1", name: "Mathematics 101", description: "Basic Mathematics", locationId: 1, userGroupId: 101),
//        SchoolClass(uuid: "uuid2", name: "Physics 201", description: "Intermediate Physics", locationId: 1, userGroupId: 102),
//        SchoolClass(uuid: "uuid3", name: "Chemistry 301", description: "Advanced Chemistry", locationId: 2, userGroupId: 201),
//        SchoolClass(uuid: "uuid4", name: "Biology 401", description: "Biology for Seniors", locationId: 2, userGroupId: 202)
   

    
    var body: some View {
        ZStack {
            
            if usersViewModel.isLoading && filteredClasses.count > 0 {
                VStack {
                    ProgressView().controlSize(.large).scaleEffect(2)
                }
            } else {
                if readyToDoPickerView{
                if doGrid {
                    VStack {
                        Picker("Pick a class", selection: $classesViewModel.selectedClassIdx) {
                            ForEach(0..<filteredClasses.count) { index in
                                Text(filteredClasses[index].name)
                                    .tag(index)
                            }
                        }
                        .padding()
                        .onChange(of: classesViewModel.selectedClassIdx) { theItem in
                            filteredStudents = getStudentsInClass(classGroupID: filteredClasses[theItem].userGroupId)
                            print("--- Selected ----")
                        }
                        .pickerStyle(.menu)
                        
                        ScrollView {
                            
                            LazyVGrid(columns: gridItems, spacing: 30) {
                                
                                ForEach(filteredStudents)  {  theUser  in
                                    /*
                                     ForEach(usersViewModel.sortedUsersNonB(lastNameFilter: searchText, selectedLocationID: teacherItems.selectedLocationIdx, teacherUserID: teacherItems.teacherUserDict[teacherItems.selectedLocationIdx]!) ) {  theUser  in
                                     */
                                    let imageURL = imageURLWithUniqueID(studentPicStubViewModel.getURLpicForStudentWith(theUser.id), uniqueID: teacherItems.uniqueID)
                                        //                            let imageURL = imageURLWithUniqueID( URL(string: "https://developitsnfredu.jamfcloud.com/application/views/default/assets/image/avatar/avatar.png")!, uniqueID: teacherItems.uniqueID)
                                    
                                    UserCardVwDup(user: theUser, urlPic: imageURL)
                                        .foregroundColor(Color.primary)
                                        .font(.body)
                                        .padding([.top, .bottom],10)
                                }
                                
                            } // end of for each
                        } // scrollview
                    
                    }
                        // end of list
                }
            }
            }
        }
        .onAppear {
            doGrid = true

        }

        .onDisappear {
            doGrid = false
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
                            readyToDoPickerView = false
                        studentPicStubViewModel.needsToLoad = true
                        Task {
                            do {
                                try await studentPicStubViewModel.reloadData2(uuid: teacherItems.getpicClass())
                                refreshClassesandStudents()
//                                studentPicStubViewModel.reloadData(uuid: teacherItems.getpicClass())
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
            UserEditorContDup(path: $path, 
                              user: theUser,
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
            if classesViewModel.ignoreLoading {
                classesViewModel.ignoreLoading = false
                    // Don't load the classes if ignoreLoading is true
            } else {
                    // Load the classes if ignoreLoading is false
//                if classesViewModel.
                if filteredClasses.isEmpty {
                    await loadTheClasses()
                    classesViewModel.ignoreLoading = false
                }
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
            studentPicStubViewModel.needsToLoad = true
            try await studentPicStubViewModel.reloadData2(uuid: teacherItems.getpicClass())
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }

}

private extension UserListDup {
    
    fileprivate func refreshClassesandStudents() {
        filteredClasses = getClassesForLocation()
            // Ensure there is at least one class
        if !filteredClasses.isEmpty {
                // Set the selected class index to the first class
            classesViewModel.selectedClassIdx = 0
                // Get the students of the first class
            filteredStudents = getStudentsInClass(classGroupID: filteredClasses[0].userGroupId)
        }
    }
    
    func loadTheClasses() async {
        do {
            try await classesViewModel.loadData2()
            refreshClassesandStudents()
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }
    
    func getClassesForLocation() -> Array<SchoolClass>  {
        classesViewModel.filterSchoolClassesinLocation2(teacherItems.currentLocation.id,
                                                        dummyPicClassToIgnore: teacherItems.getpicClass() ,
                                                        schoolClassGroupID: teacherItems.schoolClassDictionaryGroupID[teacherItems.currentLocation.id]! )
    }
    func getStudentsInClass(classGroupID: Int) -> Array<User>  {
        print(classGroupID)
        dump(usersViewModel.sortedUsersNonBClass(lastNameFilter: searchText,
                                       selectedLocationID: teacherItems.selectedLocationIdx,
                                            teacherUserID: teacherItems.teacherUserDict[teacherItems.selectedLocationIdx]!, 
                                            scGroupid: classGroupID
        ))
        
        return usersViewModel.sortedUsersNonBClass(lastNameFilter: searchText,
                                       selectedLocationID: teacherItems.selectedLocationIdx,
                                            teacherUserID: teacherItems.teacherUserDict[teacherItems.selectedLocationIdx]!,
                                            scGroupid: classGroupID
        )
    }
}



//struct UserListDupView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserListDup(path: $path, newUser: User.makeDefault())
//    }
//}
