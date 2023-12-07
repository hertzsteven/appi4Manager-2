//
//  ContentView.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import SwiftUI


struct UserListContent: View {
    
    @State private var searchText = ""
    
    @State private var presentAlertSw: Bool = false
    
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var studentPicStubViewModel: StudentPicStubViewModel   
    // @EnvironmentObject var appWorkViewModel: AppWorkViewModel
    @EnvironmentObject var teacherItems: TeacherItems

    
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

    
    var body: some View {
//        NavigationView {
//            Section {
            ScrollView {
                
                LazyVGrid(columns: gridItems, spacing: 30) {
                    
                    ForEach(usersViewModel.sortedUsers(lastNameFilter: searchText, selectedLocationID: teacherItems.selectedLocationIdx) )
                    {  $theUser  in
                        
                        let imageURL = imageURLWithUniqueID(studentPicStubViewModel.getURLpicForStudentWith(theUser.id), uniqueID: teacherItems.uniqueID)
                        
                        NavigationLink {
                            UserEditorContent(user: $theUser, urlPic: imageURL)
                        }
                    label: {
                        UserCardView(user: theUser, urlPic: imageURL)
                        
                            .foregroundColor(Color.primary)
                            .font(.body)
                            .padding([.top, .bottom],10)
                    } // end of label
                  } // end of for each
                } // end of list
                
            }
        /*
            List(usersViewModel.sortedUsers(lastNameFilter: searchText, selectedLocationID: teacherItems.selectedLocationIdx)) { $theUser in
                    NavigationLink {
                        UserEditorContent(user: $theUser)
                    } label: {
                        HStack {
                            Label("\(theUser.firstName) \(theUser.lastName)", systemImage: "person.circle")
                                .labelStyle(CustomLabelStyle())
                            Spacer()
                        }
                        .foregroundColor(Color.primary)
                        .font(.body)
                        .padding([.top, .bottom],10)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
                .onAppear { print("🟢 OnAppear - list view") }
                .onDisappear { print("🟢 OnDisappear - list view") }
*/
            
//            end of list view

//            }
            .toolbar {
                ToolbarItem {
                    Button {
                        newUser = User.makeDefault()
                        isAddingNewUser = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .toolbar {
              ToolbarItem(placement: .navigationBarLeading , content: {
                Menu {
                    Picker("Pick a location", selection: $teacherItems.selectedLocationIdx) {
                        ForEach(0..<teacherItems.MDMlocations.count) { index in
                            Text(teacherItems.MDMlocations[index].name)
                                .tag(index)
                        }
                  }
                    .padding()
                    .onChange(of:  $teacherItems.selectedLocationIdx) { value in
                        // Execute your code here
                        Task {
                            do {
                                studentPicStubViewModel.reloadData(uuid: teacherItems.getpicClass())
                                print("--- Selected location picked")
                            } catch let error as ApiError {
                                print(error.description)
                            }
                        
         }

                        print("--- Selected location: teacherItems.MDMlocations[value].name")
                    }

//                    .pickerStyle(.wheel)
                } label: {
                    Text(teacherItems.MDMlocations[teacherItems.selectedLocationIdx].name).padding()
                }
                .pickerStyle(.menu)
                
              })
            }
            
            .sheet(isPresented: $isAddingNewUser) {
                NavigationView {
                    UserEditorContent( user: $newUser, urlPic: URL(string: "https://developitsnfredu.jamfcloud.com/application/views/default/assets/image/avatar/avatar.png")!, isNew: true)
                }
            }
            .alert(isPresented:$presentAlertSw) {
                getAlert()
            }
                //                    .onAppear {
                //                        try usersViewModel.loadData()
                //                    }
            .task {
                print("🚘 In innerTask")
                
            }
            
//         }
        .navigationTitle("Students")
        .navigationBarTitleDisplayMode(.inline)

        .onAppear{
            dump(teacherItems.MDMlocations)
            print(teacherItems.MDMlocations)
        }
        .task {
            print("🚘 In outer task")
            if !usersAreLoaded {


                Task {
                    do {
                        studentPicStubViewModel.reloadData(uuid: teacherItems.getpicClass())
//                        let resposnse: UserResponse = try await ApiManager.shared.getData(from: .getUsers)
//                        self.usersViewModel.users = resposnse.users
//                        let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(from: .getStudents(uuid: ApiHelper.classuuid))
//                        self.classDetailViewModel.students = classDetailResponse.class.students
//                        self.usersAreLoaded.toggle()
                    } catch let error as ApiError {
                        print(error.description)
//                        presentAlertSw.toggle()
                    }
                
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


struct UserListContentView_Previews: PreviewProvider {
    static var previews: some View {
        UserListContent(newUser: User.makeDefault())
    }
}
