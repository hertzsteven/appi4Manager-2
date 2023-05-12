
//
//  SchoolClassEditorContent.swift
//  list the schoolClasss
//
//  Created by Steven Hertz on 2/9/23.
//


import SwiftUI

enum PersonType {
    case student
    case teacher
}

struct SchoolClassEditorContent: View {
    
    @State private var isSheetPresented = false
    @State private var inCancel = false
	@State private var showCustomBackButton = false
    
    @Environment(\.editMode) var editMode
    @State var enableEditingStudentTeachersMore: Bool = false
    
    @State var selectedStudentsSaved:   Array<Int> = []
    @State var selectedTeachersSaved:   Array<Int> = []
    
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
    
    @Binding var schoolClass: SchoolClass
    
    @State private var schoolClass_start   = SchoolClass.makeDefault()  // this gets done by the update
    @State private var schoolClassCopy     = SchoolClass.makeDefault()
    
    @State         var isNew = false
    @State private var isDeleted = false
    
    @EnvironmentObject var classesViewModel: ClassesViewModel
    
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var classDetailViewModel: ClassDetailViewModel
    @EnvironmentObject var studentPicStubViewModel: StudentPicStubViewModel
    
    @EnvironmentObject var appWorkViewModel: AppWorkViewModel
    
    
    @Environment(\.dismiss) private var dismiss
    
    private var isSchoolClassDeleted: Bool {
        !classesViewModel.exists(schoolClassCopy) && !isNew
    }
    
    @State var teacherIds: Array<Int> = []
    
 
//   MARK: - State Properties  for confirmation dialogues

	@State private var inDelete = false
 
    
    var body: some View {
        GeometryReader { geometry in

            VStack {

//               MARK: - Views

//              View: Other View Top
                SchoolClassDetailContent(schoolClass: $schoolClassCopy, isDeleted: $isDeleted, isNew: $isNew,schoolClassName: schoolClass.name, schoolClassDescription: schoolClass.description, selectedStudentsSaved: selectedStudentsSaved, selectedTeachersSaved: selectedTeachersSaved,  selectedTeachers: $selectedTeachers, selectedStudents: $selectedStudents)
                    .frame(height: geometry.size.height * 0.25)

//				View: Student List
                List {
                    Section {
                        ForEach(selectedStudents.map({ id in
                            usersViewModel.users.first(where: { $0.id == id })!
                        }), id: \.id) { student in
                            Text("\(student.firstName) \(student.lastName)")
                                .foregroundColor(appWorkViewModel.doingEdit  ? .black : .gray)
                        }
                    } header: {
                        HStack {
                            Text("Students \(selectedStudents.count)")
                                //                                .bold()
                                .font(.title3)
                                
                            if appWorkViewModel.doingEdit || ( isNew == true && !schoolClassCopy.name.isEmpty ) {
                                Spacer()
                                Button {
                                    Task {
                                        do {
                                            teacherIds = try await appWorkViewModel.getUsersInTeacherGroup() ?? []
                                            passedItemSelected = selectedStudents
                                            toShowStudentList.toggle()
                                        } catch {
                                                // Handle error
                                        }
                                    }
                                } label: {
                                    AddDeleteView() }
                                Divider()
                            }
                        }
                    } footer: {
                        Text("Number of students: \(selectedStudents.count)")
                    }.headerProminence(.standard)
                }
//                .frame(height: geometry.size.height * 0.35)
                .listStyle(SidebarListStyle())
                
//				View: Teacher List
                List {
                    Section {
                        ForEach(selectedTeachers.map({ id in
                            usersViewModel.users.first(where: { $0.id == id })!
                        }), id: \.id) { teacher in
                            Text("\(teacher.firstName) \(teacher.lastName)")
                        }
                        .foregroundColor(appWorkViewModel.doingEdit  ? .black : .gray)
                    } header: {
                        HStack {
                            Text("Teachers \(selectedTeachers.count)")
                                //                                .bold()
                                .font(.title3)
                            if  appWorkViewModel.doingEdit ||  ( isNew == true && !schoolClassCopy.name.isEmpty ) {
                                Spacer()
                                Button {
                                    Task {
                                        do {
                                            teacherIds = try await appWorkViewModel.getUsersInTeacherGroup() ?? []
                                            passedItemSelected = selectedTeachers
                                            toShowTeacherList.toggle()
                                        } catch {
                                                // Handle error
                                        }
                                    }
                                } label: {
                                    AddDeleteView()

                                }
                                Divider()
                            }
                        }
                    } footer: {
                        Text("Number of teachers: \(selectedTeachers.count)")
                    }.headerProminence(.standard)
                }
                .frame(height: geometry.size.height * 0.15)
                .listStyle(SidebarListStyle())

//				View: Spacer View
                Spacer(minLength: 60)

//              View: Delete Button
                if !isNew {
                    Button(role: .destructive, action: {
                        inDelete.toggle()
                    }, label: {
                        Text("Delete the Class")
                            .font(Font.custom("SF Pro", size: 17))
                            .foregroundColor(appWorkViewModel.doingEdit ? Color(UIColor.systemRed) :  Color(UIColor.gray))
                    })
                    .disabled(!appWorkViewModel.doingEdit)
                }
                
//              View: Spacer View
                Spacer()
                                    

//               MARK: - PopupSheets

//               Select Students Popup
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

//               Select Teachers Popup
                .sheet(isPresented: $toShowTeacherList) {
                    let userFilter2: ((any ItemsToSelectRepresentable) -> Bool) = { usr in
                        teacherIds.contains(usr.id)
                    }
                    
                    NavigationView {
                        ItemListSelectView(passedItemSelected: $passedItemSelected,
                                           itemsToList:        usersViewModel.users,
                                           itemFilter2:        userFilter2,
                                           listTitle:          "Select the teachers for this class")
                        
                            //                     StudentTeacherListView(selectedStudents: $selectedStudents,  selectedTeachers: $selectedTeachers, personType: .teacher)
                    }
                    
                    .onDisappear {
                        print("🚘 it disappeared", selectedTeachers.count)
                        selectedTeachers = passedItemSelected
                        
                    }
                }
                
                
//               MARK: - onChange onDisappear Global
                .onDisappear {
//                    // check if we should do the update process
//
//                    guard   isNew == false &&
//                            isDeleted == false else {
//                        return
//                    } // doing a change
//
//                    guard   schoolClass_start   != schoolClass ||
//                            selectedStudents    != selectedStudentsSaved ||
//                            selectedTeachers    != selectedTeachersSaved else {
//                        return
//                    } // there was a change
//
//                    // do the update and leave
//                    saveSelectedStudents()
//                    saveSelectedTeachers()
//                    Task {
//                        print(schoolClass.description)
//                        await ClassesViewModel.updateSchoolClass(schoolClass:schoolClass)
//                    }
//                    dismiss()
                }


                
//               MARK: - Add Button
                .toolbar(content: {
                    
                    
                    ToolbarItem {
                        Button {
                            if isNew {
                                addClass()
                                dismiss()
                            }
                            
                        } label: {
                            Text(isNew ? "Add" : "")
                        }
                        .disabled(schoolClassCopy.name.isEmpty)
                    }
                })
                
                // this on appear happens second
                .onAppear {
                    schoolClassCopy = schoolClass
                    schoolClass_start = schoolClass
                }
                // not monitoring students and teachers
                .onChange(of: appWorkViewModel.doingEdit) { currentValue in
                    print("***** Current Value: \(currentValue)")
                }
                .onChange(of: schoolClassCopy){ _ in
                    if !isDeleted {
                        schoolClass = schoolClassCopy
                    }
                }
                .onChange(of: appWorkViewModel.doingEdit) { newValue in
                    if newValue == false {
                        print("************* do the update")
                        upDateClass()
                    }
                }
                .onDisappear {
                        // check if we should do the update process
                    appWorkViewModel.doingEdit = false
//                    dismiss()
                }
                
            }
            .ignoresSafeArea(.keyboard)
            
    }
            
            .onTapGesture {
                 self.hideKeyboard()
             }
        
            .navigationBarTitle("Edit Class", displayMode: .inline)
            
//    MARK: - Cancel button for Add
            .toolbar  {
                
                ToolbarItem(placement: .cancellationAction) {
                    if isNew {
                        Button("Cancel") {
                            inCancel.toggle()
                        }
                    }
                }
            }
            // this on appear happens first
            .onAppear {
                restoreSavedItems()
            }

            // MARK: - Confirmation Dialog
        
            .confirmationDialog("Are you sure you want to discard changes?", isPresented: $inCancel, titleVisibility: .visible) {
                Button("Discard Changes - main", role: .destructive) {
                        // Do something when the user confirms
                    if isNew  {
                        appWorkViewModel.doingEdit.toggle()
                        dismiss()
                    } 
                }
                Button("Keep Editing", role: .cancel) {
                        // Do something when the user cancels
                }
            }

            .confirmationDialog("Are you sure you want to delete this class?", isPresented: $inDelete) {
                Button("Delete Class", role: .destructive) {
                    deleteClass()
                }
            }
        
        }
    }

//   MARK: - function for sub processes
extension SchoolClassEditorContent {
    
    fileprivate func addClass() {
        schoolClassCopy.locationId = appWorkViewModel.currentLocation.id
        
        Task {
            do {
                
                let resposnseCreateaClassResponse: CreateaClassResponse = try await ApiManager.shared.getData(from: .createaClass(name: schoolClassCopy.name, description: schoolClassCopy.description, locationId:  String(appWorkViewModel.currentLocation.id)))
                saveSelectedStudents()
                saveSelectedTeachers()
                schoolClassCopy.uuid = resposnseCreateaClassResponse.uuid
                self.classesViewModel.schoolClasses.append(self.schoolClassCopy)
                
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
       
        guard   schoolClass_start   != schoolClass ||
                selectedStudents    != selectedStudentsSaved ||
                selectedTeachers    != selectedTeachersSaved else {
            return
        } // there was a change
        
        // do the update and leave
        saveSelectedStudents()
        saveSelectedTeachers()
        Task {
            print(schoolClass.description)
            await ClassesViewModel.updateSchoolClass(schoolClass:schoolClass)
        }

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
extension SchoolClassEditorContent {
    

    // Update the students belonging to the class
    fileprivate func saveSelectedStudents() {
        
        /* See if any added or deleted */
        
        // capture students added and removed
        let selectedStudentsRemoved = Set(selectedStudentsSaved).subtracting(Set(selectedStudents))
        let selectedStudentsAdded   = Set(selectedStudents).subtracting(Set(selectedStudentsSaved))
        
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
            
            selectedStudentsSaved = selectedStudents  // save as new starting point
            
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
                
                selectedStudentsSaved = selectedStudents  // save as new starting point
            }
        }
    }
    
    // Update the teachers belonging to the class
    fileprivate func saveSelectedTeachers() {
        
        /* See if any added or deleted */
        
        // capture teachers added and removed
        let selectedTeachersRemoved  = Set(selectedTeachersSaved).subtracting(Set(selectedTeachers))
        let selectedTeachersAdded    = Set(selectedTeachers).subtracting(Set(selectedTeachersSaved))
        
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
            
            selectedTeachersSaved = selectedTeachers  // save as new starting point
            
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
                
                selectedTeachersSaved = selectedTeachers  // save as new starting point
            }
        }
        
    }
        
    fileprivate func restoreSavedItems() {
        
      /**
       - only students in the view model
       */
        Task {
            do {
                // get the class info
                let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(from: .getStudents(uuid: schoolClass.uuid))
                
                // retreive the students into View Model
                self.classDetailViewModel.students = classDetailResponse.class.students
                self.classDetailViewModel.teachers = classDetailResponse.class.teachers
                
                // put the ids into selected students array
                selectedStudents = classDetailResponse.class.students.map({ std in
                    std.id
                })
                
                // initialize the saved list
                selectedStudentsSaved = selectedStudents
                
                selectedTeachers = classDetailResponse.class.teachers.map({ std in
                    std.id
                })
                
                // initialize the saved list
                selectedTeachersSaved = selectedTeachers
                
                dump(classDetailResponse.class.teachers)
                print(classDetailResponse.class.teachers)
                
            } catch let error as ApiError {
                    //  FIXME: -  put in alert that will display approriate error message
                print(error.description)
            }
        }
     }
     
}


//    MARK: - Custom View
struct AddDeleteView: View {
    var body: some View {
        HStack {
            Image(systemName: "person.badge.minus")
                .resizable()
                .frame(width: 20, height: 20)
                .cornerRadius(4)
                .tint(Color.red)
                .offset(x: 5)
            Image(systemName: "person.badge.plus")
                .resizable()
                .frame(width: 20, height: 20)
                .cornerRadius(4)
                .tint(Color.green)
        }
        .padding([.top, .bottom, .trailing],10)
            //                                    .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30)
            .strokeBorder(LinearGradient(gradient: Gradient(colors: [Color.green, Color.red]),
                                         startPoint: .leading,
                                         endPoint: .trailing), lineWidth: 0.4))
    }
}



struct SchoolClassEditorContent_Previews: PreviewProvider {
    static var previews: some View {
        SchoolClassEditorContent(schoolClass: .constant(SchoolClass.makeDefault()))
            .environmentObject(ClassesViewModel())
            .environmentObject(UsersViewModel())
            .environmentObject(ClassDetailViewModel())
            .environmentObject(AppWorkViewModel())
            .previewDevice("iPhone 12")
            .preferredColorScheme(.light)
    }
}

    //struct SchoolClassEditorContent_Previews: PreviewProvider {
    //    static var previews: some View {
    //        SchoolClassEditorContent(schoolClass:  SchoolClass(id: 1, locationId: 1, deviceCount: 0, email: "", groupIds: [1], groups: ["qq"], firstName: "Sam", lastName: "Harris", schoolClassname: "dlknnlknk", notes: "some notes", modified: "12/32/21"))
    //    }
    //}
