
//
//  SchoolClassEditorContent.swift
//  list the schoolClasss
//
//  Created by Steven Hertz on 2/9/23.
//


import SwiftUI


struct SchoolClassEditorContDup: View {
    
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
        GeometryReader { geometry in

            VStack {
                
                Form {
                        Section("Class Information") {
                            HStack {
                                if appWorkViewModel.doingEdit {
                                    if !schoolClass.name.isEmpty {
                                        Text("Name: ")
                                    }
                                    TextField("Class Name", text: $schoolClass.name )
                                        //                    .font(.headline)
                                        .padding([.top, .bottom], 8)
                                } else {
                                    Text(schoolClass.name).foregroundColor(appWorkViewModel.doingEdit  ? .black : Color(.darkGray))
                                }
                            }
                            HStack {
                                if appWorkViewModel.doingEdit {
                                    if !schoolClass.description.isEmpty {
                                        Text("Description: ")
                                    }
                                    
                                    TextField("Description", text: $schoolClass.description )
                                        .font(.subheadline)
                                        .padding([.top, .bottom], 8)
                                } else {
                                    Text(schoolClass.description).foregroundColor(appWorkViewModel.doingEdit  ? .black : Color("disabled"))
                                }
                                
                            } // end of hstack
                        } // end of section
                          //                View: Student List
                    

                    }  // end of form
                
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

//              MARK: - Views


                
//                View: Spacer View
//                Spacer(minLength: 60)

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
                
//               MARK: - onChange onDisappear Global
                
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
                .onDisappear {
                        // check if we should do the update process
                    appWorkViewModel.doingEdit = false
//                    dismiss()
                }
                
            }
            .ignoresSafeArea(.keyboard)
            
            // lets set up the navigatitle and properties
            .navigationTitle("Edit Class")
            .navigationBarTitleDisplayMode(.inline)
            
    }
            
            .onTapGesture {
                 self.hideKeyboard()
             }
        
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
}
        
        }


//   MARK: - function for sub processes
extension SchoolClassEditorContDup {
    
    fileprivate func addClass() {
    }
    

    
    fileprivate func upDateClass() {
//        guard   isNew == false &&

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
