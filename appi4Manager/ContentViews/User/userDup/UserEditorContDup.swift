//
//  UserEditorContDup.swift
//  list the users
//
//  Created by Steven Hertz on 2/9/23.
//


import SwiftUI
import _PhotosUI_SwiftUI

struct AnimateTextField: View {
    @Binding var textField: String
    @Binding var mode : EditMode
    var itIsInEdit: Bool {
        mode == .active
    }
    let label: String
    
    var body: some View {
        
        HStack {
            if !textField.isEmpty {
                Text("\(label): ")
            }
            
            ZStack(alignment: .leading) {
                TextField(label, text: $textField)
                    .opacity(itIsInEdit ? 1 : 0)
                Text(textField)
                    .opacity(itIsInEdit ? 0 : 1)
                    .foregroundColor(Color(.darkGray))
            }
        }
    }
}

struct UserEditorContDup: View {
    
    @State var profilesx: [StudentAppProfilex] = []
    
    @Binding var path: NavigationPath
    
    @State var isBlocking = false
    
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
    
    @EnvironmentObject var teacherItems: TeacherItems
    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var usersViewModel: UsersViewModel
    // @EnvironmentObject var appWorkViewModel: AppWorkViewModel
    @EnvironmentObject var studentPicStubViewModel: StudentPicStubViewModel

//    @EnvironmentObject var classDetailViewModel: ClassDetailViewModel
    @Environment(\.dismiss) private var dismiss

    private var isUserDeleted: Bool {
        !usersViewModel.exists(userInitialValues) && !isNew
    }
    
    var body: some View {

        ZStack {
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
                                                 .disabled(!itIsInEdit ? true : false)
                                                 .tint(.purple)
                                                 .controlSize(.large)
                                                 .buttonStyle(.borderedProminent)
                                                 .padding()
                                                 .onAppear {
//                                                     imagePicker.studentId = user.id
                                                    // imagePicker.teachAuth = "9c74b8d6a4934ca986dfe46592896801"
                                                     print("-*- in onAppear student id is \(user.id)")
                                                     checkIfUserInAppProfile(studentID: user.id)
                                                 }
                                                 .onDisappear {
                                                     print("-- in disappear")
                                                     task {
                                                         do {
                                                             try await studentPicStubViewModel.reloadData(uuid: teacherItems.getpicClass())
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
                                                teacherItems.uniqueID = UUID()
                                            }
                                    } else if let image = imagePicker.savedImage {
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
                                                teacherItems.uniqueID = UUID()
                                            }
                                    }else {
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
                            AnimateTextField(textField: $user.firstName, mode: $mode, label: "First Name")
                            AnimateTextField(textField: $user.lastName, mode: $mode, label: "Last Name")
                        }
                        
                        Section(header: Text("Notes")) {
                            AnimateTextField(textField: $user.notes, mode: $mode, label: "notes")
                        }
                        
                        Section(header: Text("Apps")) {
                            Button("App Profile For Student \(user.id)") {
                                Task {
                //                    profilesx =  await StudentAppProfileManager.loadProfilesx()
                                    profilesx = await  StudentAppProfileManager.loadProfilesx()
                                    print("-----")
                                    dump(profilesx)
                                    print("-----")
                                    path.append(user.id)
                                }
                            }
//                            NavigationLink("Go To Student Profile For Student id 8", value: user.id)
//                            NavigationLink("Student Apps") {
//                                Text("Apps for Student \(user.id)")
//                            }
                            
                        }


                        Section(header: Text("email")) {
                            AnimateTextField(textField: $user.email, mode: $mode, label: "email")
                            
                        }
                        
                        .textCase(nil)
                        
                        .environment(\.editMode, $mode)

                    List {
                        Section {
                            
                            ForEach(selectedStudentClasses.compactMap({ id in
                                (classesViewModel.filterSchoolClassesinLocation(teacherItems.currentLocation.id,
                                                                                                    dummyPicClassToIgnore: teacherItems.getpicClass() ) )
                                    .first(where: { $0.userGroupId == id })
                            }), id: \.id) { schoolClass in
                                Text("\(schoolClass.name)")
                            }

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
        //                                        teacherIds = try await teacherItems.getUsersInTeacherGroup() ?? []
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
                            DeleteButtonView(action: {
                                inDelete.toggle()
                            })
                            .listRowInsets(EdgeInsets())
                            .disabled(!itIsInEdit ? true : false)
                        }
                        
                    }
                    

                    .navigationDestination(for: Int.self) { studentId in
                        
                     let profilesx =  StudentAppProfileManager.loadProfilesxUserDefaukts()
                        
                        if let studentFound = profilesx.first { $0.id == studentId} {
                            
                            StudentAppProfileWorkingView(
                                studentId                   : studentId,
                                studentAppProfilefiles      : profilesx,
                                profileManager: StudentAppProfileManager(),
                                studentAppprofile           :  studentFound)
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
                                        isBlocking = true
                                       
                                        do {
                                            inUpdate = true
                                            await upDateUser()
                                            inUpdate = false
                                            isBlocking = false
                                            if !itIsInEdit {
                                                updateModeWithAnimation()
                                            } else {
                                                updateModeWithAnimation(switchTo: .inactive)
                                            }
                                        } catch {
                                            print("Failed in task")
                                        }
                                    }
                                } else {
                                    updateModeWithAnimation()
                                }
                            }.frame(height: 96, alignment: .trailing)
                                .disabled(isBlocking)
                            
                        }
                    }
                    // 			Cancel button from editing not adding
                    ToolbarItem(placement: .navigationBarLeading) {
                        if itIsInEdit && !isNew {
                            Button("Cancel") {
                                inCancelEdit.toggle()
                            }.frame(height: 96, alignment: .trailing)
                                .disabled(isBlocking)
                        }
                    }
                    
                    
                        ToolbarItem(placement: .cancellationAction) {
                            if isNew {
                                Button("Cancel") {
                                    inCancelAdd = true
                                }
                            }
                        }
                        ToolbarItem {
                            Button {
                                if isNew {
                                    if inAdd {
                                        return
                                    }
                                    Task {
                                        do {
                                            inAdd = true
                                            await addTheUser()
                                            usersViewModel.ignoreLoading = false
                                            dismiss()
                                            inAdd = false
                                        } catch {
                                            print("Failed in task")
                                        }
                                    }
                                }
                            } label: {
                                Text(isNew ? "Add" : "")
                            }
                            .disabled(user.lastName.isEmpty || user.firstName.isEmpty)
                        }
                    } )
                
                    
        //      MARK: - Navigation Bar  * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
                    .navigationBarBackButtonHidden(mode == .active ? true : false)


        //       MARK: - Confirmation Dialog  * * * * * * * * * * * * * * * * * * * * * * * *
                
                .confirmationDialog("Are you sure you want to delete this class?", isPresented: $inDelete) {
                    Button("Delete the Student", role: .destructive) {
                        deleteTheUser()
                    }
                }
                // from edit
                .confirmationDialog("Are you sure you want to discard changes?", isPresented: $inCancelEdit, titleVisibility: .visible) {
                    Button("Discard Changes edit ", role: .destructive) {
                            // Do something when the user confirms
                        mode = .inactive
                        user.lastName               = userInitialValues.lastName
                        user.firstName              = userInitialValues.firstName
                        user.notes                  = userInitialValues.notes
                        user.email                  = userInitialValues.email
                        imagePicker.imageSelection  = nil
                        imagePicker.image           = nil
                        imagePicker.theUIImage      = nil
                        imagePicker.savedImage      = nil
                    }
                }
                // from add
                .confirmationDialog("Are you sure you want to discard changes?", isPresented: $inCancelAdd, titleVisibility: .visible) {
                    Button("Discard Changes", role: .destructive) {
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

                }

                .overlay(alignment: .center) {
                    if isUserDeleted {
                        Color(UIColor.systemBackground)
                        Text("User Deleted. Select an User.")
                            .foregroundStyle(.secondary)
                    }
                    
            }
            BlockingOverlayView(isBlocking: $isBlocking)

        }
        }
    }
 

extension UserEditorContDup {
    
    fileprivate func updateModeWithAnimation(switchTo theMode: EditMode = .active) {
        withAnimation(.easeInOut(duration: 1.0)) {
            mode = theMode
        }
    }

    
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

        imagePicker.imageSelection = nil
        imagePicker.image = nil
        imagePicker.theUIImage = nil
        imagePicker.savedImage = nil

    }
}



extension UserEditorContDup {
    
    fileprivate func addTheUser() {
         if isNew {
 //        setup properties of User for doing the add
             user.username  = String(Array(UUID().uuidString.split(separator: "-")).last!)
             user.locationId = teacherItems.currentLocation.id
             user.groupIds   = [teacherItems.getIDpicClass()]
             Task {
                 do {
                     let resposnseaddAUser: AddAUserResponse = try await ApiManager.shared.getData(from: .addUsr(user: user))
                     
                     user.id = resposnseaddAUser.id
                     await imagePicker.loadTransferable2Update(teachAuth: teacherItems.getTeacherAuth(), studentId: user.id)


 //                   add user into existing user array
                     self.usersViewModel.users.append(self.user)

 //                 trigger a refresh of screen and not getting the image from cacheh
                     self.teacherItems.uniqueID = UUID()

                 } catch let error as ApiError {
                         //  FIXME: -  put in alert that will display approriate error message
                     print(error)
                 }
             }
         }
     }
    
    fileprivate func deleteTheUser() {
        print("we are about to delete the user \(user.id)")
        isDeleted = true
        
        Task {
            do {
                print("break")
                let response = try await ApiManager.shared.getDataNoDecode(from: .deleteaUser(id: user.id))
                dump(response)
                usersViewModel.delete(user)

                
            } catch let error as ApiError {
                    //  FIXME: -  put in alert that will display approriate error message
                print(error.description)
            }
        }
        dismiss()
    }


    
    fileprivate func upDateUser() async {

    	// update user in JAMF
        await usersViewModel.updateUser2(user: user)
        
        // update user in array of users being shown
        let index = usersViewModel.users.firstIndex { usr in
            usr.id == user.id
        }
        usersViewModel.users[index!] = user
        
        await imagePicker.loadTransferable2Update(teachAuth: TeacherItems.shared.teacherAuthToken, studentId: user.id)
//        await imagePicker.loadTransferable2Update(teachAuth: teacherItems.getTeacherAuth(), studentId: user.id)

        // update the student Pic
//        imagePicker.updateTheImage()
        
        // do housekeeping - start a new starting point
        storeUserDetailStartingPoint()

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

fileprivate func checkIfUserInAppProfile(studentID: Int) {
    
    print(studentID)
    
    var studentProfiles = StudentAppProfileManager.loadProfilesxUserDefaukts()
    
    
    if  !studentProfiles.contains(where: { prf in
        prf.id == studentID
    } ) {
        // need to make a mock
        let newProfile = StudentAppProfileManager.makeDefaultfor(studentID, locationId: 1)
        
        // load it into array
        studentProfiles.append(newProfile)
        
        // save it
        StudentAppProfileManager.savePassedProfiles(profilesToSave: studentProfiles)
    }

    
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
