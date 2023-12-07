//
//  SchoolClassDetailContent.swift
//  list the schoolClasss
//
//  Created by Steven Hertz on 2/8/23.
//

import SwiftUI

struct SchoolClassDetailContent: View {
    

    @State private var hideTabBar = false
    @State private var inCancel = false

    @Binding var schoolClass: SchoolClass
    @Binding var isDeleted: Bool
    @Binding var isNew: Bool
    
    @EnvironmentObject var teacherItems: TeacherItems
    // @EnvironmentObject var appWorkViewModel: AppWorkViewModel
    @EnvironmentObject var classesViewModel: ClassesViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) var editMode
    
    let schoolClassName:       	String
    let schoolClassDescription: String
    let selectedStudentsSaved: 	Array<Int>
    let selectedTeachersSaved: 	Array<Int>
  
    @Binding var selectedTeachers: Array<Int>
    @Binding var selectedStudents: Array<Int>
    

 
    var body: some View {
        VStack {
        Form {
                Section("Class Information") {
                    HStack {
                        if teacherItems.doingEdit {
                            if !schoolClass.name.isEmpty {
                                Text("Name: ")
                            }
                            TextField("Class Name", text: $schoolClass.name )
                                //                    .font(.headline)
                                .padding([.top, .bottom], 8)
                        } else {
                            Text(schoolClass.name).foregroundColor(teacherItems.doingEdit  ? .black : Color(.darkGray))
                        }
                    }
                    HStack {
                        if teacherItems.doingEdit {
                            if !schoolClass.description.isEmpty {
                                Text("Description: ")
                            }
                            
                            TextField("Description", text: $schoolClass.description )
                                .font(.subheadline)
                                .padding([.top, .bottom], 8)
                        } else {
                            Text(schoolClass.description).foregroundColor(teacherItems.doingEdit  ? .black : Color("disabled"))
                        }
                        
                    }
                }
            }

        }

        
        .confirmationDialog("Are you sure you want to discard changes?", isPresented: $inCancel, titleVisibility: .visible) {
            Button("Discard Changes detail", role: .destructive) {
                    // Do something when the user confirms
                if isNew  {
                    teacherItems.doingEdit.toggle()
                    dismiss()
                } else {
                selectedStudents        = selectedStudentsSaved
                selectedTeachers        = selectedTeachersSaved
                schoolClass.name        = schoolClassName
                schoolClass.description = schoolClassDescription
                dump(schoolClass)
                teacherItems.doingEdit.toggle()
            }
            }
            Button("Keep Editing", role: .cancel) {
                    // Do something when the user cancels
            }
        }

        .toolbar  {

            if !isNew {
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                    Button(teacherItems.doingEdit ? "**Done**" : "Edit") {
                        if teacherItems.doingEdit {
                            teacherItems.doingEdit.toggle()
                            teacherItems.doUpdate.toggle()
                        } else {
                            teacherItems.doingEdit.toggle()
                        }
                    }.frame(height: 96, alignment: .trailing)
                }
            }
        }
        
        .navigationBarBackButtonHidden(teacherItems.doingEdit)
        
//          MARK: - Cancel Button For Update
            .navigationBarItems(leading: teacherItems.doingEdit && !isNew ? Button("Cancel", action: {
                inCancel.toggle()
                print("i am in cancel")
            } ).frame(height: 96, alignment: .trailing)
                                : nil )
    }
}


//struct SchoolClassDetailContent_Previews: PreviewProvider {
//    @State static var schoolClass = SchoolClass(uuid: UUID().uuidString, name: "Example Class", description: "This is an example class description", locationId: 1, userGroupId: 1)
//    @State static var isDeleted = false
//    @State static var isNew = false
//    
//    static var previews: some View {
//        NavigationView {
//            SchoolClassDetailContent(schoolClass: $schoolClass, isDeleted: $isDeleted, isNew: $isNew, schoolClassDescription: "", selectedStudentsSaved: [1], selectedStudents: .constant([2]))
//                .environmentObject(ClassesViewModel())
//        }
//    }
//}

