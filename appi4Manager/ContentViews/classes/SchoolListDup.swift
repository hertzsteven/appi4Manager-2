//
//  SchoolListDup.swift
//  appi4Manager
//
//  Created by Steven Hertz on 5/12/23.
//

import SwiftUI

struct SchoolListDup: View {
    
    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var appWorkViewModel: AppWorkViewModel
    
    @State var newClass: SchoolClass
    @State private var isAddingNewSchoolClass = false


//   MARK: - Body View   * * * * * * * * * * * * * * * * * * * * * * * *
    var body: some View {
        List(classesViewModel.filterSchoolClassesinLocation(appWorkViewModel.currentLocation.id,
                                                         dummyPicClassToIgnore: appWorkViewModel.getpicClass() ))
        { schoolClass in
            SchoolClassRow(schoolClass: schoolClass)
        }

        
//      MARK: - Popup  Sheets  * * * * * * * * * * * * * * * * * * * * * * * *
        .sheet(isPresented: $isAddingNewSchoolClass) {
            NavigationView {
                SchoolClassEditorContDup(schoolClass: newClass, isNew: true)
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
                    appWorkViewModel.doingEdit = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Picker("Pick a location", selection: $appWorkViewModel.selectedLocationIdx) {
                        ForEach(0 ..< appWorkViewModel.locations.count) { index in
                            Text(appWorkViewModel.locations[index].name)
                                .tag(index)
                        }
                    }
                    .padding()
                } label: {
                    Text(appWorkViewModel.locations[appWorkViewModel.selectedLocationIdx].name).padding()
                }
                .pickerStyle(.menu)
            }

        } // end if  .toolbar
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
            .padding([.leading, .trailing], 12)
            .padding([.bottom], 16)
        }
    }
}

//struct SchoolListDup_Previews: PreviewProvider {
//    static var previews: some View {
//        SchoolListDup(, newClass: <#SchoolClass#>)
//    }
//}
