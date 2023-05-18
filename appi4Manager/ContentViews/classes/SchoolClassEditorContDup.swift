
//
//  SchoolClassEditorContent.swift
//  list the schoolClasss
//
//  Created by Steven Hertz on 2/9/23.
//


import SwiftUI


struct DeleteButtonView: View {
    
    var action: () -> Void
    
    var body: some View {
        Button(role: .destructive) {
            action()
        }
    label: {
        Text("Delete")
            .foregroundColor(.white)
            .bold()
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(10)
    }
    .buttonStyle(PlainButtonStyle())
    .frame(maxWidth: .infinity)
    .listRowInsets(EdgeInsets())
    }
}


struct CollapsibleList: View {
    @EnvironmentObject var usersViewModel: UsersViewModel
    @Environment(\.editMode) var editMode
    
    @Binding var isListVisible: Bool
    @Binding var newItem: String
    @Binding var listData:   [Int]
    let title:      String
    
    var action: () -> Void
    
    var itIsInEdit: Bool {
        editMode?.wrappedValue == .active
    }
    
    var body: some View {
        
        Section(header: HStack {
       
            TextField("Add new \(title)", text: $newItem)
            Spacer()
       
            if itIsInEdit {
                Button {
                    action()
                } label: {
                    Image(systemName: "plus")
                }
                Divider()
            }
       
            Button {
                isListVisible.toggle()
            } label: {
                Image(systemName: isListVisible ? "chevron.down" : "chevron.right")
            }
       
        })  { if isListVisible {
            ForEach(listData.map({ id in
                usersViewModel.users.first(where: { $0.id == id })!
            }), id: \.id) { student in
                Text("\(student.firstName) \(student.lastName)")
                    .foregroundColor(itIsInEdit ? .black :  Color(.darkGray))
            }
          }
        }
    }
}


struct SchoolClassEditorContDup: View {
    
    @State var isList1Visible: Bool = true
    @State var newItem1: String = ""
    @State var isList2Visible: Bool = true
    @State var newItem2: String = ""
    
    @State var mode: EditMode = .inactive
    
    var itIsInEdit: Bool {
        mode == .active
    }
    
    @State private var isSheetPresented = false
    @State private var inCancelEdit = false
    @State private var inCancelAdd = false
    

    @State var passedItemSelected:      Array<Int> = []
    
    @State var selectedStudents:        Array<Int> = []
    @State var selectedTeachers:        Array<Int> = []
    
    
    @State private var toShowStudentList: Bool = false
    @State private var toShowTeacherList: Bool = false
    
    @State var personType: PersonType = PersonType.student
    
    private var selectedStudentsKey: String {
        "selectedStudentp-\(schoolClass.uuid)"
    }
    private var selectedTeachersKey: String {
        "selectedTeacherp-\(schoolClass.uuid)"
    }
    
    
    @State  var schoolClass: SchoolClass
    
    @State private var schoolClassInitialValues   = SchoolClass.makeDefault()  // this gets done by the update
    @State var selectedStudentsInitialValues:   Array<Int> = []
    @State var selectedTeachersInitialValues:   Array<Int> = []
    
    
    @State         var isNew = false
    @State private var isDeleted = false
    
    @EnvironmentObject var classesViewModel: ClassesViewModel
    
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var classDetailViewModel: ClassDetailViewModel
    @EnvironmentObject var studentPicStubViewModel: StudentPicStubViewModel
    
    @EnvironmentObject var appWorkViewModel: AppWorkViewModel
    
    
    @Environment(\.dismiss) private var dismiss
    
    private var isSchoolClassDeleted: Bool {
        !classesViewModel.exists(schoolClassInitialValues) && !isNew
    }
    
    @State var teacherIds: Array<Int> = []
    
    

    @State private var inDelete = false
    
    
//   MARK: - Body View
    
    var body: some View {
        Form {
            Section("Class Information") {
                HStack {
                    if itIsInEdit {
                        if !schoolClass.name.isEmpty {
                            Text("Name: ")
                        }
                        TextField("Class Name", text: $schoolClass.name )
                            //                    .font(.headline)
                            .padding([.top, .bottom], 8)
                    } else {
                        Text(schoolClass.name).foregroundColor(itIsInEdit  ? .black : Color(.darkGray))
                    }
                }
                HStack {
                    if itIsInEdit {
                        if !schoolClass.description.isEmpty {
                            Text("Description: ")
                        }
                        
                        TextField("Description", text: $schoolClass.description )
                            .font(.subheadline)
                            .padding([.top, .bottom], 8)
                    } else {
                        Text(schoolClass.description).foregroundColor(itIsInEdit  ? .black : Color("disabled"))
                    }
                    
                } // end of hstack

            } // end of section
            
            CollapsibleList(isListVisible: $isList1Visible, newItem: $newItem1, listData: $selectedStudents, title: "Students") {
                Task {
                    do {
                        teacherIds = try await appWorkViewModel.getUsersInTeacherGroup() ?? []
                        passedItemSelected = selectedStudents
                        toShowStudentList.toggle()
                    } catch {
                            // Handle error
                    }
                }
            }
            
            CollapsibleList(isListVisible: $isList2Visible, newItem: $newItem2, listData: $selectedTeachers, title: "Teachers") {
                Task {
                    do {
                        teacherIds = try await appWorkViewModel.getUsersInTeacherGroup() ?? []
                        passedItemSelected = selectedTeachers
                        toShowTeacherList.toggle()
                    } catch {
                            // Handle error
                    }
                }
            }

            if !isNew {
                DeleteButtonView(action: {
                    inDelete.toggle()
                })
                .listRowInsets(EdgeInsets())
                .disabled(!itIsInEdit ? true : false)
            }
            
        }  // end of form
        .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom)
        

//      MARK: - Popup  Sheets  * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
        
//       Select Students Popup
        .sheet(isPresented: $toShowStudentList) {
            
            let userFilter2: ((any ItemsToSelectRepresentable) -> Bool) = { usr in
                !teacherIds.contains(usr.id)
            }
            
            NavigationView {
                ItemListSelectView(passedItemSelected: $passedItemSelected,
                                   itemsToList: usersViewModel.users,
                                   itemFilter2: userFilter2,
                                   listTitle: "Select the students for this class")
            }
            .onDisappear {
                selectedStudents = passedItemSelected
            }
        }
        
//       Select Teachers Popup
        .sheet(isPresented: $toShowTeacherList) {
            let userFilter2: ((any ItemsToSelectRepresentable) -> Bool) = { usr in
                teacherIds.contains(usr.id)
            }
            
            NavigationView {
                ItemListSelectView(passedItemSelected: $passedItemSelected,
                                   itemsToList:        usersViewModel.users,
                                   itemFilter2:        userFilter2,
                                   listTitle:          "Select the teachers for this class")
                
            }
            
            .onDisappear {
                selectedTeachers = passedItemSelected                
            }
        }
      
        
        
//       MARK: - Confirmation Dialog
        
        .confirmationDialog("Are you sure you want to delete this class?", isPresented: $inDelete) {
            Button("Delete Class", role: .destructive) {
                deleteClass()
            }
        }
        // from edit
        .confirmationDialog("Are you sure you want to discard changes?", isPresented: $inCancelEdit, titleVisibility: .visible) {
            Button("Discard Changes edit ", role: .destructive) {
                    // Do something when the user confirms
                     mode = .inactive
                    selectedStudents        = selectedStudentsInitialValues
                    selectedTeachers        = selectedTeachersInitialValues
                    schoolClass.name        = schoolClassInitialValues.name
                    schoolClass.description = schoolClassInitialValues.description
                    dump(schoolClass)
            }
        }
        // from add
        .confirmationDialog("Are you sure you want to discard changes?", isPresented: $inCancelAdd, titleVisibility: .visible) {
            Button("Discard Changes add ", role: .destructive) {
                    // Do something when the user confirms
                dismiss()
            }
        }
    
        
        
        
//      MARK: - Toolbar   * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
        
        .toolbar {
//         edit done toolbar button   
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isNew {
                    Button(!itIsInEdit ? "Edit" : "**Done**") {
                        if itIsInEdit {
                            upDateClass()
                        }
                        mode = !itIsInEdit ? .active  : .inactive
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
            
            
//		    Cancel button from adding
            ToolbarItem(placement: .cancellationAction) {
                if isNew {
                    Button("Cancel") {
                        if schoolClass.name.isEmpty {
                            dismiss()
                        } else {
                            inCancelAdd.toggle()
                        }
                    }.frame(height: 96, alignment: .trailing)
                }
            }
            
//            ToolbarItem {
//                Button("N") {
//                    let index = classesViewModel.getSchoolClassesinLocation(appWorkViewModel.currentLocation.id,
//                                                                            dummyPicClassToIgnore: appWorkViewModel.getpicClass() ).firstIndex(of: schoolClass)
//                    schoolClass =  classesViewModel.getSchoolClassesinLocation(appWorkViewModel.currentLocation.id,
//                                                                               dummyPicClassToIgnore: appWorkViewModel.getpicClass() )[index! + 1]
//                    toDoWithNewSchoolClassToProcess()
//                }
//            }
            ToolbarItem(placement: .bottomBar) {
                ControlGroup {
                    Button(action: {}) {
                        Image(systemName: "chevron.backward.circle")
                    }
                    Button(action: {}) {
                        Image(systemName: "chevron.forward.circle")
                    }
                }
                .controlGroupStyle(.navigation)
            }
            
            ToolbarItemGroup(placement: .secondaryAction) {
                Button(action: {
                    print("Item 1 tapped")
                }) {
                    HStack(spacing: -10) {
                        Image(systemName: "1.circle")
                        Text("Item 1")
                    }
                }

                Button(action: {
                    print("Item 2 tapped")
                }) {
                    HStack(spacing: -10) {
                        Image(systemName: "2.circle")
                        Text("Item 2")
                    }
                }

                Button(action: {
                    print("Item 3 tapped")
                }) {
                    HStack(spacing: -10) {
                        Image(systemName: "3.circle")
                        Text("Item 3")
                    }
                }

            }

//
                
//              ToolbarItemGroup(placement: .secondaryAction) {
//                  Button {
//                      <#code#>
//                  } label: {
//                      <#code#>
//                  }
//
//                  Button {
//                      let index = classesViewModel.getSchoolClassesinLocation(appWorkViewModel.currentLocation.id,
//                                                                              dummyPicClassToIgnore: appWorkViewModel.getpicClass() ).firstIndex(of: schoolClass)
//                      schoolClass =  classesViewModel.getSchoolClassesinLocation(appWorkViewModel.currentLocation.id,
//                                                                                 dummyPicClassToIgnore: appWorkViewModel.getpicClass() )[index! + 1]
//                      toDoWithNewSchoolClassToProcess()
//
//                  } label: {
//                      Label("Next", image: Image(systemName: "chevron.forward.circle"))
//                  }
//
//                  Button {
//                      let index = classesViewModel.getSchoolClassesinLocation(appWorkViewModel.currentLocation.id,
//                                                                              dummyPicClassToIgnore: appWorkViewModel.getpicClass() ).firstIndex(of: schoolClass)
//                      schoolClass =  classesViewModel.getSchoolClassesinLocation(appWorkViewModel.currentLocation.id,
//                                                                                 dummyPicClassToIgnore: appWorkViewModel.getpicClass() )[index! - 1]
//                      toDoWithNewSchoolClassToProcess()
//
//                  } label: {
//                      Label("Next", image: Image(systemName: "chevron.forward.circle"))
//                  }
//              }

            
//          Add button New Class
            ToolbarItem {
                Button(isNew ? "Add" : "") {
                    if isNew {
                        addClass()
                        dismiss()
                    }
                }
                .disabled(schoolClass.name.isEmpty)
            }
        }
        
        .environment(\.editMode, $mode)
                
        .ignoresSafeArea(.keyboard)
        
        
//      MARK: - Navigation Bar  * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *

        .navigationTitle("Edit Class")
        .navigationBarTitleDisplayMode(.inline)
        
        .navigationBarBackButtonHidden(mode == .active ? true : false)
//        .navigationBarTitle("Edit Dup Class", displayMode: .inline)
        
            
//      MARK: - Appear and Disappear   * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
        
        .onAppear {
            if !isNew {
                toDoWithNewSchoolClassToProcess()
            } else {
                mode = .active
            }
        }

        .onDisappear {
            mode = .inactive
        }
    }
}


//   MARK: - function for sub processes
extension SchoolClassEditorContDup {
    
    fileprivate func addClass() {
        
        schoolClass.locationId = appWorkViewModel.currentLocation.id
         
         Task {
             do {
                 let resposnseCreateaClassResponse: CreateaClassResponse = try await ApiManager.shared.getData(from: .createaClass(name: schoolClass.name, description: schoolClass.description, locationId:  String(schoolClass.locationId)))
                 saveSelectedStudents()
                 saveSelectedTeachers()
                 schoolClass.uuid = resposnseCreateaClassResponse.uuid
                 self.classesViewModel.schoolClasses.append(self.schoolClass)
             } catch let error as ApiError {
                     //  FIXME: -  put in alert that will display approriate error message
                 print(error)
             }
         }
    }
    
    fileprivate func upDateClass() {

        guard   isNew == false &&
                isDeleted == false else {
            return
        } // doing a change
       
        guard   schoolClassInitialValues   != schoolClass ||
                selectedStudents    != selectedStudentsInitialValues ||
                selectedTeachers    != selectedTeachersInitialValues else {
            return
        } // there was a change
        
        // do the update and leave
        saveSelectedStudents()
        saveSelectedTeachers()
        Task {
            await ClassesViewModel.updateSchoolClass(schoolClass:schoolClass)
        }
        
        let index = classesViewModel.schoolClasses.firstIndex { sc in
            sc.uuid == schoolClass.uuid
        }

        classesViewModel.schoolClasses[index!] = schoolClass


    }
    
    fileprivate func deleteClass() {

        print("we are about to delete the schoolClass \(schoolClass.id)")
        isDeleted = true
        Task {
            do {
                let response = try await ApiManager.shared.getDataNoDecode(from: .deleteaClass(uuid: schoolClass.uuid))
                dump(response)
                print("break")
                classesViewModel.delete(schoolClass)
            } catch let error as ApiError {
                    //  FIXME: -  put in alert that will display approriate error message
                print(error.description)
            }
        }
        dismiss()
 
        
    }
    
    fileprivate func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}

//  MARK: -  funcs to save student and teachers updates to class
extension SchoolClassEditorContDup {
    
    
        // Update the students belonging to the class
    fileprivate func saveSelectedStudents() {
        
        /* See if any added or deleted */
        
        // capture students added and removed
        let selectedStudentsRemoved = Set(selectedStudentsInitialValues).subtracting(Set(selectedStudents))
        let selectedStudentsAdded   = Set(selectedStudents).subtracting(Set(selectedStudentsInitialValues))
        
        // if there are students to remove then remove them
        if !selectedStudentsRemoved.isEmpty {
            
            for studentToDelete in selectedStudentsRemoved {
                    //get the student
                
                Task {
                    do {
                            // get the user that we need to update
                        var userToUpdate: UserDetailResponse = try await ApiManager.shared.getData(from: .getaUser(id: studentToDelete))
                        
                            // eliminate the duplicates
                        var groupIdsNoDups = userToUpdate.user.groupIds.removingDuplicates()
                        
                            // remove the group being deleted from
                        guard let idx = groupIdsNoDups.firstIndex(of: schoolClass.userGroupId) else { fatalError("no match") }
                        groupIdsNoDups.remove(at: idx)
                        userToUpdate.user.groupIds = groupIdsNoDups
                        
                            // Update the user
                        let responseFromUpdatingUser = try await ApiManager.shared.getDataNoDecode(from: .updateaUser(id: userToUpdate.user.id,
                                                                                                                      username:     userToUpdate.user.username,
                                                                                                                      password:     "123456",
                                                                                                                      email:        userToUpdate.user.email,
                                                                                                                      firstName:    userToUpdate.user.firstName,
                                                                                                                      lastName:     userToUpdate.user.lastName,
                                                                                                                      notes:        userToUpdate.user.notes,
                                                                                                                      locationId:   userToUpdate.user.locationId,
                                                                                                                      groupIds:     userToUpdate.user.groupIds,
                                                                                                                      teacherGroups: userToUpdate.user.teacherGroups))
                    } catch let error as ApiError {
                            //  FIXME: -  put in alert that will display approriate error message
                        print(error.description)
                    }
                }
            }
            
            selectedStudentsInitialValues = selectedStudents  // save as new starting point
            
        }
        
        // if there are students to add then add them
        if !selectedStudentsAdded.isEmpty {
                // do the api assign users to class
            Task {
                do {
                    let z = try await ApiManager.shared.getDataNoDecode(from: .assignToClass(uuid: schoolClass.uuid, students: selectedStudents, teachers: []))
                        //                    dump(z)
                    
                } catch let error as ApiError {
                        //  FIXME: -  put in alert that will display approriate error message
                    print(error.description)
                }
                
                selectedStudentsInitialValues = selectedStudents  // save as new starting point
            }
        }
        
    }
    
        // Update the teachers belonging to the class
    fileprivate func saveSelectedTeachers() {
        
        
        /* See if any added or deleted */
        
        // capture teachers added and removed
        let selectedTeachersRemoved  = Set(selectedTeachersInitialValues).subtracting(Set(selectedTeachers))
        let selectedTeachersAdded    = Set(selectedTeachers).subtracting(Set(selectedTeachersInitialValues))
        
        // if there are teachers to remove then remove them
        if !selectedTeachersRemoved.isEmpty {
            
            for teacherToDelete in selectedTeachersRemoved {
                    //get the teacher
                
                Task {
                    do {
                            // get the user that we need to update
                        var userToUpdate: UserDetailResponse = try await ApiManager.shared.getData(from: .getaUser(id: teacherToDelete))
                        
                            // eliminate the duplicates
                        var groupIdsNoDups = userToUpdate.user.teacherGroups.removingDuplicates()
                        
                            // remove the group being deleted from
                        guard let idx = groupIdsNoDups.firstIndex(of: schoolClass.userGroupId) else { fatalError("no match") }
                        groupIdsNoDups.remove(at: idx)
                        userToUpdate.user.teacherGroups = groupIdsNoDups
                        
                            // Update the user
                        let responseFromUpdatingUser = try await ApiManager.shared.getDataNoDecode(from: .updateaUser(id: userToUpdate.user.id,
                                                                                                                      username:     userToUpdate.user.username,
                                                                                                                      password:     "123456",
                                                                                                                      email:        userToUpdate.user.email,
                                                                                                                      firstName:    userToUpdate.user.firstName,
                                                                                                                      lastName:     userToUpdate.user.lastName,
                                                                                                                      notes:        userToUpdate.user.notes,
                                                                                                                      locationId:   userToUpdate.user.locationId,
                                                                                                                      groupIds:     userToUpdate.user.groupIds,
                                                                                                                      teacherGroups: userToUpdate.user.teacherGroups))
                    } catch let error as ApiError {
                            //  FIXME: -  put in alert that will display approriate error message
                        print(error.description)
                    }
                }
            }
            
            selectedTeachersInitialValues = selectedTeachers  // save as new starting point
            
        }
        
        // if there are teachers to add then add them
        if !selectedTeachersAdded.isEmpty {
                // do the api assign users to class
            Task {
                do {
                    let z = try await ApiManager.shared.getDataNoDecode(from: .assignToClass(uuid: schoolClass.uuid, students: [], teachers: selectedTeachers))
                        //                    dump(z)
                    
                } catch let error as ApiError {
                        //  FIXME: -  put in alert that will display approriate error message
                    print(error.description)
                }
                
                selectedTeachersInitialValues = selectedTeachers  // save as new starting point
            }
        }
        
        
    }
    
    
    /*
     Executes on appear.
      - gets the school detail using the api
      - save the info
     */
    
    func toDoWithNewSchoolClassToProcess()  {
        getSchoolClassDetail()
        storeSchoolClassDetailStartingPoint()
        mode = .inactive
    }
    
    
    fileprivate func getSchoolClassDetail() {
        
        Task {
            do {
                    // get the class info
                let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(from: .getStudents(uuid: schoolClass.uuid))
                
                    // retreive the students into View Model
                self.classDetailViewModel.students = classDetailResponse.class.students
                self.classDetailViewModel.teachers = classDetailResponse.class.teachers
                
                storeSchoolClassDetailStartingPoint()
                
                
            } catch let error as ApiError {
                    //  FIXME: -  put in alert that will display approriate error message
                print(error.description)
            }
        }
    }
    
    fileprivate func storeSchoolClassDetailStartingPoint() {
    
    	// save for restore and compare
        schoolClassInitialValues = schoolClass

        // put the ids into selected students array
        selectedStudents = self.classDetailViewModel.students.map({ std in
            std.id
        })
        
            // initialize the saved list
        selectedStudentsInitialValues = selectedStudents
        
        
        
        selectedTeachers =  self.classDetailViewModel.teachers.map({ std in
            std.id
        })
        
            // initialize the saved list
        selectedTeachersInitialValues = selectedTeachers
    }

}


struct SchoolClassEditorContDup_Previews: PreviewProvider {


    static var previews: some View {
        NavigationView {

            SchoolClassEditorContDup(schoolClass: SchoolClass.makeDefault())
                .environmentObject(ClassesViewModel())
                .environmentObject(UsersViewModel())
                .environmentObject(ClassDetailViewModel())
                .environmentObject(StudentPicStubViewModel())
                .environmentObject(AppWorkViewModel())
        }
    }
}


