//
//  UserEditorContDup.swift
//  list the users
//
//  Created by Steven Hertz on 2/9/23.
//


import SwiftUI
import _PhotosUI_SwiftUI

struct UserEditorContDup: View {
    
    @State private var inUpdate = false
    @State private var inDelete = false
    @State private var inAdd    = false
    
    @State var mode: EditMode = .inactive
    
    var itIsInEdit: Bool {
        mode == .active
    }
    


    
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

    
    @State  var user: User
    var urlPic: URL
    
    @State var userInitialValues: User
    @State var selectedStudentsClassesInitialValues:   Array<Int> = []
    @State var selectedTeachersClassesInitialValues:   Array<Int> = []
    
    @State private var isSheetPresented = false
    @State private var inCancelEdit = false
    @State private var inCancelAdd = false


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
        !usersViewModel.exists(userInitialValues) && !isNew
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
                    
                    HStack {
                        if itIsInEdit {
                            if !user.firstName.isEmpty {
                                Text("First Name: ")
                            }
                            TextField("First Name", text: $user.firstName )
                                 .padding([.top, .bottom], 8)
                        } else {
                            Text(user.firstName).foregroundColor(itIsInEdit  ? .black : Color(.darkGray))
                        }
                    }
                    
                    HStack {
                        if itIsInEdit {
                            if !user.lastName.isEmpty {
                                Text("Last Name: ")
                            }
                            TextField("Last Name", text: $user.lastName )
                                 .padding([.top, .bottom], 8)
                        } else {
                            Text(user.lastName).foregroundColor(itIsInEdit  ? .black : Color(.darkGray))
                        }
                    }
                    
//                    TextField("First Name", text: $user.firstName )
//                        .padding([.top, .bottom], 8)
//
//
//                    TextField("Last Name", text: $user.lastName )
//                        .padding([.top, .bottom], 8)
//
                    
                }
                Section(header: Text("Notes")) {
                    
                    HStack {
                        if itIsInEdit {
                            if !user.notes.isEmpty {
                                Text("notes: ")
                            }
                            TextField("notes", text: $user.notes )
                                 .padding([.top, .bottom], 8)
                        } else {
                            Text(user.notes).foregroundColor(itIsInEdit  ? .black : Color(.darkGray))
                        }
                    }

//                    TextField("Notes", text: $user.notes )
//                        .padding([.top, .bottom], 8)


                }
                Section(header: Text("email")) {
                    
                    HStack {
                        if itIsInEdit {
                            if !user.email.isEmpty {
                                Text("email: ")
                            }
                            TextField("email", text: $user.email )
                                 .padding([.top, .bottom], 8)
                        } else {
                            Text(user.email).foregroundColor(itIsInEdit  ? .black : Color(.darkGray))
                        }
                    }
                    
//                    TextField("email", text: $user.email )
//                        .padding([.top, .bottom], 8)
                    
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
                
                .environment(\.editMode, $mode)

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
            
            
            .environment(\.editMode, $mode)
            .listStyle(SidebarListStyle())
            
 

//      MARK: - toolbar   * * * * * * * * * * * * * * * * * * * * * *
			.toolbar(content: {
			    ToolbarItem(placement: .navigationBarTrailing) {
                if !isNew {
                    Button(!itIsInEdit ? "Edit" : "**Done**") {
                        if itIsInEdit {
                            if inUpdate {
                                return
                            }
                            Task {
                                do {
                                    inUpdate = true
                                    await upDateUser()
                                    inUpdate = false
                                    mode = !itIsInEdit ? .active  : .inactive
                                } catch {
                                    print("Failed in task")
                                }
                            }
                        } else {
                            mode = .active
                        }
                    }.frame(height: 96, alignment: .trailing)
                    
                }
            }
            // 			Cancel button from editing not adding
            ToolbarItem(placement: .navigationBarLeading) {
                if itIsInEdit && !isNew {
                    Button("Cancel") {
                        inCancelEdit.toggle()
                    }.frame(height: 96, alignment: .trailing)
                }
            }
            
            
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
			
//      MARK: - Navigation Bar  * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
            .navigationBarBackButtonHidden(mode == .active ? true : false)


//       MARK: - Confirmation Dialog  * * * * * * * * * * * * * * * * * * * * * * * * 
        
        .confirmationDialog("Are you sure you want to delete this class?", isPresented: $inDelete) {
            Button("Delete Class", role: .destructive) {
               // deleteClass()
            }
        }
        // from edit
        .confirmationDialog("Are you sure you want to discard changes?", isPresented: $inCancelEdit, titleVisibility: .visible) {
            Button("Discard Changes edit ", role: .destructive) {
                    // Do something when the user confirms
                     mode = .inactive
//                    selectedStudents        = selectedStudentsInitialValues
//                    selectedTeachers        = selectedTeachersInitialValues
                user.lastName        = userInitialValues.lastName
                user.firstName        = userInitialValues.firstName
                user.notes           = userInitialValues.notes

//                    schoolClass.description = schoolClassInitialValues.description
//                    dump(schoolClass)
            }
        }
        // from add
        .confirmationDialog("Are you sure you want to discard changes?", isPresented: $inCancelAdd, titleVisibility: .visible) {
            Button("Discard Changes add ", role: .destructive) {
                    // Do something when the user confirms
                dismiss()
            }
        }
    
        





//      MARK: - Appear and Disappear   * * * * * * * * * * * * * * * * * * * * * *                        
				.onAppear {
					usersViewModel.ignoreLoading = true

					if !isNew {
						toDoWithNewUserToProcess()
					} else {
						mode = .active
					}
				}

				.onDisappear {
					mode = .inactive
				}

           .onDisappear {
                // We are about to update
                if isNew == false && isDeleted == false {
                    print("🚘 In on disAppear -UserEditorContDup zero \(user.firstName) ")
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
//               .onChange(of: userCopy){ _ in
//                    if !isDeleted {
//                        user = userCopy
//                    }
//                }
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

extension UserEditorContDup {
    
    func toDoWithNewUserToProcess()  {
        getUserDetail()
        storeUserDetailStartingPoint()
        mode = .inactive
    }

    
    fileprivate func getUserDetail() {
    
/*
 - Seems that all the User information is already retreived and no further retrevila is required,
 - this is different from the class detail where we needed o retreive class detail info
 - the only question is the picture
 */
        
        storeUserDetailStartingPoint()
        
//        Task {
//            do {
//                    // get the class info
//                let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(from: .getStudents(uuid: schoolClass.uuid))
//
//                    // retreive the students into View Model
//                self.classDetailViewModel.students = classDetailResponse.class.students
//                self.classDetailViewModel.teachers = classDetailResponse.class.teachers
//
//                storeUserDetailStartingPoint()
//
//
//            } catch let error as ApiError {
//                    //  FIXME: -  put in alert that will display approriate error message
//                print(error.description)
//            }
//        }
    }
    
    fileprivate func storeUserDetailStartingPoint() {
    
        // save for restore and compare
        userInitialValues = user

        // put the ids into selected students array
        selectedStudentClasses = user.groupIds
        selectedTeacherClasses = user.teacherGroups
    }

}

    



extension UserEditorContDup {
    
    fileprivate func upDateUser() async {

        

    }
    
    
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
//        UserEditorContDup(user: $user)
//    }
//}
//
//
//struct UserEditorContDup_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        Container()
//            .environmentObject(UsersViewModel())
//    }
//}
