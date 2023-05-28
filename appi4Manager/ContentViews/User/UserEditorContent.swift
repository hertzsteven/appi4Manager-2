//
//  UserEditorContent.swift
//  list the users
//
//  Created by Steven Hertz on 2/9/23.
//


import SwiftUI
import _PhotosUI_SwiftUI

struct UserEditorContent: View {
    
    
    @State private var userImage: Image? = nil
    @StateObject var imagePicker = ImagePicker()
    @State private var showDeleteAlert = false
    
    
    @State var editMode = EditMode.inactive
    
    @State var selectedStudentClassesSaved:       Array<Int> = []
    @State var selectedTeacherClassesSaved:       Array<Int> = []

    @State var passedItemSelected:                Array<Int> = []

    @State var selectedStudentClasses:            Array<Int> = []
    @State var selectedTeacherClasses:            Array<Int> = []
    
    
    @State private var toShowStudentClassesList:  Bool = false
    @State private var toShowTeacherClassList:    Bool = false

    
    @Binding var user: User
    var urlPic: URL

    @State private var user_start   = User.makeDefault()  // this gets done by the update
    @State private var userCopy     = User.makeDefault()

    @State         var isNew = false
    @State private var isDeleted = false
    
    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var appWorkViewModel: AppWorkViewModel
    @EnvironmentObject var studentPicStubViewModel: StudentPicStubViewModel

//    @EnvironmentObject var classDetailViewModel: ClassDetailViewModel
    @Environment(\.dismiss) private var dismiss

    private var isUserDeleted: Bool {
        !usersViewModel.exists(userCopy) && !isNew
    }
    
    fileprivate func addTheUser() {
        if isNew {
//        setup properties of User for doing the add
            userCopy.username  = String(Array(UUID().uuidString.split(separator: "-")).last!)
            userCopy.locationId = appWorkViewModel.currentLocation.id
            userCopy.groupIds   = [appWorkViewModel.getIDpicClass()]
            Task {
//             add the user
                do {
//                add user into jamf
//                    let resposnseaddAUser: AddAUserResponse = try await ApiManager.shared.getData(from: .addUser(username:    userCopy.username,
//                                                                                                                 password:    "123456",
//                                                                                                                 email:         userCopy.email,
//                                                                                                                 firstName:     userCopy.firstName,
//                                                                                                                 lastName:        userCopy.lastName,
//                                                                                                                 notes:         userCopy.notes,
//                                                                                                                 locationId:     userCopy.locationId,
//                                                                                                                 groupIds:         userCopy.groupIds,
//                                                                                                                 teacherGroups: userCopy.teacherGroups))
//
                    
                    let resposnseaddAUser: AddAUserResponse = try await ApiManager.shared.getData(from: .addUsr(user: userCopy))
//                   add user into existing user array
                    userCopy.id = resposnseaddAUser.id
                    self.usersViewModel.users.append(self.userCopy)
//                 trigger a refresh of screen and not getting the image from cacheh
                    self.appWorkViewModel.uniqueID = UUID()
                } catch let error as ApiError {
                        //  FIXME: -  put in alert that will display approriate error message
                    print(error)
                }
            }
            dismiss()
        }
    }
    fileprivate func deleteTheUser() {
        print("we are about to delete the user \(user.id)")
        isDeleted = true
        
        Task {
            do {
                usersViewModel.delete(user)
                print("break")
                let response = try await ApiManager.shared.getDataNoDecode(from: .deleteaUser(id: user.id))
                dump(response)
                
                
            } catch let error as ApiError {
                    //  FIXME: -  put in alert that will display approriate error message
                print(error.description)
            }
        }
        dismiss()
    }

    var body: some View {
        VStack {
            
            Form {
                Section(header: Text("Photo")) {
                    VStack(alignment: .center) {
                        
                        HStack {
                            
                                // photo picker
                            PhotosPicker(selection: $imagePicker.imageSelection,
                                         matching: .images) {
                                Text("Select a photo")
                            }
                                         .tint(.purple)
                                         .controlSize(.large)
                                         .buttonStyle(.borderedProminent)
                                         .padding()
                                         .onAppear {
                                             imagePicker.studentId = user.id
                                             imagePicker.teachAuth = "9c74b8d6a4934ca986dfe46592896801"
                                         }
                                         .onDisappear {
                                             print("-- in disappear")
                                             task {
                                                 do {
                                                     try await studentPicStubViewModel.reloadData(uuid: appWorkViewModel.getpicClass())
                                                 } catch {
                                                     print("ellelelell  Big error")
                                                 }
                                             }
                                         }
                            
                                // delete button
                            if userImage != nil {
                                Button(action: {
                                    self.userImage = nil
                                }) {
                                    Text("Delete Image")
                                        .padding()
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            
                            Spacer()
                            
                                // if an image exists
                            if let image = imagePicker.image {
                                image
                                    .resizable()
                                    .scaledToFit() // Display the loaded image
                                    .clipShape(Circle())
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                                    )
                                    .onAppear {
                                        appWorkViewModel.uniqueID = UUID()
                                    }
                            } else {
                                AsyncImage(url: urlPic) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView() // Display a progress view while the image is loading
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit() // Display the loaded image
                                            .clipShape(Circle())
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                                            )
                                        
                                    case .failure:
                                        Text("Failed to load image") // Display an error message if the image fails to load
                                    @unknown default:
                                        fatalError()
                                    }
                                }
                            }
                        } // Hstack end
                    }
                }
                Section(header: Text("Name")) {
                    TextField("First Name", text: $user.firstName )
                        .padding([.top, .bottom], 8)
                    TextField("Last Name", text: $user.lastName )
                        .padding([.top, .bottom], 8)
                }
                Section(header: Text("Notes")) {
                    TextField("Notes", text: $user.notes )
                        .padding([.top, .bottom], 8)
                }
                Section(header: Text("email")) {
                    TextField("email", text: $user.email )
                        .padding([.top, .bottom], 8)
                }
                
                .alert("Delete User?", isPresented: $showDeleteAlert) {
                    Button(role: .destructive) {
                        deleteTheUser()
                    } label: {
                        Text("Delete")
                    }
                } message: {
                    Text("This will permanently delete the user.")
                }
                .textCase(nil)
                

//            }
            
            
//            UserDetailContent(user: $userCopy, isDeleted: $isDeleted, isNew: $isNew, urlPic: urlPic)
            List {
                Section {
                    
                    ForEach(selectedStudentClasses.compactMap({ id in
//                        classesViewModel.schoolClasses
                        (classesViewModel.filterSchoolClassesinLocation(appWorkViewModel.currentLocation.id,
                                                                                            dummyPicClassToIgnore: appWorkViewModel.getpicClass() ) )
                            .first(where: { $0.userGroupId == id })
                    }), id: \.id) { schoolClass in
                        Text("\(schoolClass.name)")
                    }
                    .onDelete { offsets in
                        for offSet in offsets {
                            selectedStudentClasses.remove(at: offSet)
                        }
                        saveselectedStudentClasses()
                    }
//                }
                } header: {
                    HStack {
                        Text("Classes ")
                            //                                .bold()
//                            .font(.title3)
                        if editMode == .active || ( isNew == true && !userCopy.lastName.isEmpty ) {
                            Spacer()
                            Button {
                                Task {
                                    do {
//                                        teacherIds = try await appWorkViewModel.getUsersInTeacherGroup() ?? []
                                        passedItemSelected = selectedStudentClasses
                                        toShowStudentClassesList.toggle()
                                    } catch {
                                        // Handle error
                                    }
                                }
                             } label: {
                                Image(systemName: "plus.forwardslash.minus")
                                    .foregroundColor(.blue)
                            }
                            Divider()
                        }
                    }
                }
//           footer: {
//                   Text("Number of classes: \(selectedStudentClasses.count)")
//               }
//                .headerProminence(.standard)
            }
                
                
                if !isNew {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("Delete User")
                            .font(Font.custom("SF Pro", size: 17))
                            .foregroundColor(Color(UIColor.systemRed))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .environment(\.editMode, $editMode)
            .listStyle(SidebarListStyle())
            .onDisappear {
                // We are about to update
                if isNew == false && isDeleted == false {
                    print("🚘 In on disAppear -UserEditorContent zero \(user.firstName) ")
                    if user_start == user {
                        print("its the same")
                    } else {
                        print("its different")
                        
                        Task {
                            print(user.notes)
                            await UsersViewModel.updateUser(user:user)
//                            do {
//                                _ = try await ApiManager.shared.getDataNoDecode(from: .updateaUser(id: user.id,
//                                                                                                   username: user.username,
//                                                                                                   password: "123456" ,
//                                                                                                   email: user.email,
//                                                                                                   firstName: user.firstName,
//                                                                                                   lastName: user.lastName,
//                                                                                                   locationId: user.locationId))
//
//                            } catch let error as ApiError {
//                                    //  FIXME: -  put in alert that will display approriate error message
//                                print(error.description)
//                            }
                        }
                        dismiss()
                    }
                }
             }

                .toolbar(content: {
                    ToolbarItem(placement: .cancellationAction) {
                        if isNew {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                    }
                    ToolbarItem {
                        Button {
                            addTheUser()
                        } label: {
                            Text(isNew ? "Add" : "")
                        }
                        .disabled(userCopy.lastName.isEmpty || userCopy.firstName.isEmpty)
                    }
                })
                       
                .onAppear {
                    userCopy = user
                    user_start = user
                    print("🚘 In on Appear - UserEditorContent ")
                }
                .onChange(of: userCopy){ _ in
                    if !isDeleted {
                        user = userCopy
                    }
                }
                .onDisappear {
//                    print("🚘 In on disAppear -UserEditorContent first \(user.firstName) ")
                }
            

        }
        .onDisappear {
            print("🚴‍♂️ In on disAppear -UserEditorContent second \(user.firstName)")
        }
        .onAppear {
            print("🚴‍♂️ In on appear -UserEditorContent second \(user.firstName)")
           restoreSavedItems()
        }

        .overlay(alignment: .center) {
            if isUserDeleted {
                Color(UIColor.systemBackground)
                Text("User Deleted. Select an User.")
                    .foregroundStyle(.secondary)
            }
        }
    }
 
    
}


extension UserEditorContent {
    
    
    
    fileprivate func restoreSavedItems() {
        dump(user)
        print("pause")
        
            // put the ids into selected students array
        selectedStudentClasses = user.groupIds
        
            // initialize the saved list
        selectedStudentClassesSaved = selectedStudentClasses
        
        
        selectedTeacherClasses = user.teacherGroups
        
            // initialize the saved list
        selectedTeacherClassesSaved = selectedTeacherClasses
    }
}

fileprivate func saveselectedStudentClasses() {
    
}

//struct Container: View {
//    
//    @StateObject var usersViewModel         = UsersViewModel()
//
//    @State var usersAreLoaded: Bool = false
//
//    @State         var isNew = false
//    @State private var isDeleted = false
//
//    @State var user = User(id: 1, locationId: 1, deviceCount: 0, email: "", groupIds: [1], groups: ["qq"], teacherGroups: [], firstName: "Sam", lastName: "Harris", username: "dlknnlknk", notes: "some notes", modified: "12/32/21")
//    
//    
//    var body: some View {
//        UserEditorContent(user: $user)
//    }
//}
//
//
//struct UserEditorContent_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        Container()
//            .environmentObject(UsersViewModel())
//    }
//}
