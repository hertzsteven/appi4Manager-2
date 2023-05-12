
//
//  ContentView.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import SwiftUI

struct SchoolListContent: View {
    @Binding var path: NavigationPath

    @State private var searchText = ""

    @State private var presentAlertSw: Bool = false

    @EnvironmentObject var usersViewModel: UsersViewModel
//    @EnvironmentObject var classDetailViewModel: ClassDetailViewModel
    @EnvironmentObject var studentPicStubViewModel: StudentPicStubViewModel
    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var appWorkViewModel: AppWorkViewModel

    @State var newClass: SchoolClass
    @State private var isAddingNewSchoolClass = false

    @State var classesAreLoaded: Bool = false

    @State var justClasses = [SchoolClass]()

    var body: some View {
//        NavigationView {
        List {
            ForEach($classesViewModel.schoolClasses.filter({ schoolClass in
                schoolClass.locationId.wrappedValue == appWorkViewModel.currentLocation.id && !(schoolClass.uuid.wrappedValue == appWorkViewModel.getpicClass())
            })) { theClass in
                NavigationLink(value: theClass) {
                    VStack(alignment: .leading, spacing: 6.0) {
                        Text(theClass.name.wrappedValue).font(.headline)
                        Text(theClass.description.wrappedValue).font(.caption)
                    }
                    .padding([.leading, .trailing], 12)
                    .padding([.bottom], 16)
                } // NavigationLink
            } // forEach
            
        } 
        
        .navigationDestination(for: Binding<SchoolClass>.self) { theClass in
            SchoolClassEditorContent(schoolClass: theClass)
        }
        
        .toolbar {
            ToolbarItem {
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
            
        }
        
        .sheet(isPresented: $isAddingNewSchoolClass) {
            NavigationView {
                SchoolClassEditorContent(schoolClass: $newClass, isNew: true)
            }
        }
        .alert(isPresented: $presentAlertSw) {
            getAlert()
        }
            //                    .onAppear {
            //                        try usersViewModel.loadData()
            //                    }
        
            // MARK: - .task modifier
        .task {
            print("🚘 In outer task")
            
            if !classesAreLoaded {
                
                Task {
                    
                    do {
                        let resposnseSchoolClasses: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
                        self.classesViewModel.schoolClasses = resposnseSchoolClasses.classes
                        justClasses = resposnseSchoolClasses.classes
                        self.classesAreLoaded.toggle()
                    } catch let error as ApiError {
                        print(error.description)
                        presentAlertSw.toggle()
                    }
                    
                } // Task
                
            } // endif
            
        } // .task
//    }
    } // body

    func getAlert() -> Alert {
        return Alert(title: Text("This is a second alert"))
    }
}

struct SchoolListContentView_Previews: PreviewProvider {
    static var previews: some View {
        SchoolListContent(path: .constant(NavigationPath()), newClass: SchoolClass.makeDefault())
    }
}
