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
    
    var body: some View {
        List(classesViewModel.getSchoolClassesinLocation(appWorkViewModel.currentLocation.id,
                                                         dummyPicClassToIgnore: appWorkViewModel.getpicClass() ))
        { schoolClass in
            NavigationLink(value: schoolClass) {
                VStack(alignment: .leading, spacing: 6.0) {
                    Text(schoolClass.name).font(.headline)
                    Text(schoolClass.description).font(.caption)
                }
                .padding([.leading, .trailing], 12)
                .padding([.bottom], 16)
            }
        }
        .navigationTitle("Classes")
        .navigationDestination(for: Binding<SchoolClass>.self) { theClass in
            SchoolClassEditorContent(schoolClass: theClass)
        }
        .navigationDestination(for: SchoolClass.self) { theClass in
            SchoolClassEditorContDup(schoolClass: theClass)
        }

        .toolbar {
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
        }
    
    }
}

struct SchoolListDup_Previews: PreviewProvider {
    static var previews: some View {
        SchoolListDup()
    }
}
