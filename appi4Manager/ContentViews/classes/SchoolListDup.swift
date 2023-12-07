//
//  SchoolListDup.swift
//  appi4Manager
//
//  Created by Steven Hertz on 5/12/23.
//

import SwiftUI

struct SchoolListDup: View {
    
    @EnvironmentObject var teacherItems: TeacherItems

    @EnvironmentObject var classesViewModel: ClassesViewModel
    // @EnvironmentObject var appWorkViewModel: AppWorkViewModel
    
    @State          var newClass: SchoolClass
    @State private  var isAddingNewSchoolClass = false

    @State private var hasError = false
    @State private var error: ApiError?


//   MARK: - Body View   * * * * * * * * * * * * * * * * * * * * * * * *
    var body: some View {
        ZStack {
            
            if classesViewModel.isLoading {
                VStack {
                    ProgressView().controlSize(.large).scaleEffect(2)
                }
            } else {
                List(classesViewModel.filterSchoolClassesinLocation(teacherItems.currentLocation.id,
                                                                    dummyPicClassToIgnore: teacherItems.getpicClass() ) )
                { schoolClass in
                    SchoolClassRow(schoolClass: schoolClass)
                }
            }
        }

        
//      MARK: - Popup  Sheets  * * * * * * * * * * * * * * * * * * * * * * * *
        .sheet(isPresented: $isAddingNewSchoolClass) {
            NavigationView {
                SchoolClassEditorContDup(schoolClass: newClass, isNew: true)
            }
       }
        
//      MARK: -alerts  * * * * * * * * * * * * * * * * * * * * * * * *
        .alert(isPresented: $hasError,
               error: error) {
            Button {
                Task {
                    await loadTheClasses()
                }
            } label: {
                Text("Retry")
            }
        }
        
         
//      MARK: - Navigation Bar  * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
        .navigationTitle("Classes")
        .navigationBarTitleDisplayMode(.inline)
        

//      MARK: - Navigation Destimation   * * * * * * * * * * * * * * * * * * * * * *
        .navigationDestination(for: Binding<SchoolClass>.self) { theClass in
            SchoolClassEditorContent(schoolClass: theClass)
        }
        .navigationDestination(for: SchoolClass.self) { theClass in
            SchoolClassEditorContDup(schoolClass: theClass)
        }
        

//      MARK: - Toolbar   * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
        .toolbar {
 
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newClass = SchoolClass.makeDefault()
                    isAddingNewSchoolClass = true
                    teacherItems.doingEdit = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Picker("Pick a location", selection: $teacherItems.selectedLocationIdx) {
                        ForEach(0 ..< teacherItems.MDMlocations.count) { index in
                            Text(teacherItems.MDMlocations[index].name)
                                .tag(index)
                        }
                    }
                    .padding()
                } label: {
                    Text(teacherItems.MDMlocations[teacherItems.selectedLocationIdx].name).padding()
                }
                .pickerStyle(.menu)
            }

        } // end if  .toolbar
       
        
//      MARK: - Task Modifier    * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
        .task {
            if classesViewModel.ignoreLoading {
                classesViewModel.ignoreLoading = false
                // Don't load the classes if ignoreLoading is true
            } else {
                // Load the classes if ignoreLoading is false
                await loadTheClasses()
                classesViewModel.ignoreLoading = false
            }

        }
    }
}


//      MARK: - Extension  subView  school class row view in the list   * * * * * * * *
struct SchoolClassRow : View  {
    let schoolClass: SchoolClass
    var body: some View {
        NavigationLink(value: schoolClass) {
            VStack(alignment: .leading, spacing: 6.0) {
                Text(schoolClass.name).font(.headline)
                Text(schoolClass.description).font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    //        .padding(.horizontal, 4)

//            .padding([.leading, .trailing], 12)
//            .padding([.bottom], 16)
        }
    }
}

private extension SchoolListDup {
    func loadTheClasses() async {
        do {
            try await classesViewModel.loadData2()
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }   
}

//struct SchoolListDup_Previews: PreviewProvider {
//    static var previews: some View {
//        // Create some mock SchoolClass objects
//        let mockClasses = [
//            SchoolClass(uuid: "001", name: "dldldlld", description: "kwkwkkw", locationId: 1, userGroupId: 10),
//            SchoolClass(uuid: "002", name: "Morning", description: "Some data", locationId: 1, userGroupId: 8) // Other properties
//            // Add more classes as needed
//        ]
//        let classesViewModel = ClassesViewModel(schoolClasses: mockClasses)
//
//        return SchoolListDup(newClass: SchoolClass.makeDefault())
//            .environmentObject(classesViewModel)
//            .environmentObject(teacherItems())
//    }
//}
