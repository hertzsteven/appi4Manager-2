
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
    var title:      String
    
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
    @State private var inCancel = false
    @State private var showCustomBackButton = false
    
//    @Environment(\.editMode) var editMode
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
    
    
    @State  var schoolClass: SchoolClass
    
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
//        GeometryReader { geometry in
                
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
 
                    
//                    CollapsibleList(isListVisible: $isList2Visible, newItem: $newItem2, listData: selectedTeachers, title: "Teachers")
  
                    if !isNew {
                        DeleteButtonView(action: {
                            inDelete.toggle()
                        })
                        .listRowInsets(EdgeInsets())
                        .disabled(!itIsInEdit ? true : false)
                    }
                    

                    }  // end of form
        
        
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

        
//               MARK: - PopupSheets
                
//               MARK: - onChange onDisappear Global
                
//               MARK: - Add Button
                .toolbar {
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(!itIsInEdit ? "Edit" : "**Done**") {
                            if itIsInEdit {
                                upDateClass()
                            }
                            mode = !itIsInEdit ? .active  : .inactive
                        }.frame(height: 96, alignment: .trailing)
                     }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        if itIsInEdit {
                            Button("Cancel") {
                                inCancel.toggle()
                            }.frame(height: 96, alignment: .trailing)
                        }
                    }


                    
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
                }
                .environment(\.editMode, $mode)
                
                // this on appear happens second
                .onAppear {
                    schoolClassCopy = schoolClass
                    schoolClass_start = schoolClass
                }
                // not monitoring students and teachers
                .onDisappear {
                        // check if we should do the update process
                    appWorkViewModel.doingEdit = false
//                    dismiss()
                }
                
            // vstack end
            .ignoresSafeArea(.keyboard)
            
            // lets set up the navigatitle and properties
            .navigationTitle("Edit Class")
            .navigationBarTitleDisplayMode(.inline)
        
            .navigationBarBackButtonHidden(mode == .active ? true : false)

            
//    } // end geomotry
//
//            .onTapGesture {
//                 self.hideKeyboard()
//             }
        
            .navigationBarTitle("Edit Dup Class", displayMode: .inline)
            
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
                getSchoolDetail()
                saveSchoolDetailInfo()
            }

            // MARK: - Confirmation Dialog
        
            .confirmationDialog("Are you sure you want to discard changes?", isPresented: $inCancel, titleVisibility: .visible) {
                Button("Discard Changes detail", role: .destructive) {
                        // Do something when the user confirms
                    if isNew  {
//                        appWorkViewModel.doingEdit.toggle()
//                        dismiss()
                    } else {
                        mode = .inactive
                        selectedStudents        = selectedStudentsSaved
                        selectedTeachers        = selectedTeachersSaved
                        schoolClass.name        = schoolClassCopy.name
                        schoolClass.description = schoolClassCopy.description
                        dump(schoolClass)
                    }
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
extension SchoolClassEditorContDup {
    
    fileprivate func addClass() {
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
        
        let index = classesViewModel.schoolClasses.firstIndex { sc in
            sc.uuid == schoolClass.uuid
        }

        classesViewModel.schoolClasses[index!] = schoolClass


    }
    
    fileprivate func deleteClass() {

    }
    
    fileprivate func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}

//  MARK: -  funcs to save student and teachers updates to class
extension SchoolClassEditorContDup {
    
    
        // Update the students belonging to the class
    fileprivate func saveSelectedStudents() {
        
        
    }
    
        // Update the teachers belonging to the class
    fileprivate func saveSelectedTeachers() {
        
    }
    
    
    /*
     Executes on appear.
      - gets the school detail using the api
      - save the info
     */
    fileprivate func getSchoolDetail() {
        
        Task {
            do {
                    // get the class info
                let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(from: .getStudents(uuid: schoolClass.uuid))
                
                    // retreive the students into View Model
                self.classDetailViewModel.students = classDetailResponse.class.students
                self.classDetailViewModel.teachers = classDetailResponse.class.teachers
                
                saveSchoolDetailInfo()
                
                
            } catch let error as ApiError {
                    //  FIXME: -  put in alert that will display approriate error message
                print(error.description)
            }
        }
    }
    
    fileprivate func saveSchoolDetailInfo() {
            // put the ids into selected students array
        selectedStudents = self.classDetailViewModel.students.map({ std in
            std.id
        })
        
            // initialize the saved list
        selectedStudentsSaved = selectedStudents
        
        
        
        selectedTeachers =  self.classDetailViewModel.teachers.map({ std in
            std.id
        })
        
            // initialize the saved list
        selectedTeachersSaved = selectedTeachers
    }

}


struct SchoolClassEditorContDup_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SchoolClassEditorContDup(schoolClass: SchoolClass.makeDefault())
                .environmentObject(ClassesViewModel())
                .environmentObject(UsersViewModel())
                .environmentObject(ClassDetailViewModel())
                .environmentObject(StudentPicStubViewModel())
                .environmentObject(AppWorkViewModel())
        }
    }
}
