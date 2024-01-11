//
//  DeviceListView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 1/4/24.
//


import SwiftUI

/*
struct DeviceListView: View {
    
    @EnvironmentObject var teacherItems: TeacherItems

    @EnvironmentObject var devicesViewModel: DevicesViewModel
    // @EnvironmentObject var appWorkViewModel: AppWorkViewModel
    
    @State          var newClass: TheDevice
    @State private  var isAddingNewSchoolClass = false

    @State private var hasError = false
    @State private var error: ApiError?


//   MARK: - Body View   * * * * * * * * * * * * * * * * * * * * * * * *
    var body: some View {
        
        Text("gkkgk")
//        ZStack {
//            
//            if devicesViewModel.isLoading {
//                VStack {
//                    ProgressView().controlSize(.large).scaleEffect(2)
//                }
//            } else {
//                Text("hello")
//                /*
//                List(devicesViewModel.devices
//                { device in
//                    Text("dddd")
////                    DeviceRow(device: device)
//                }
//                     */
//            }
//        }

/*
        
//      MARK: - Popup  Sheets  * * * * * * * * * * * * * * * * * * * * * * * *
        .sheet(isPresented: $isAddingNewSchoolClass) {
            NavigationView {
                SchoolClassEditorContDup(device: newClass, isNew: true)
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
//        .navigationDestination(for: Binding<Device>.self) { theClass in
//            SchoolClassEditorContent(device: theClass)
//        }
        .navigationDestination(for: Device.self) { theClass in
            SchoolClassEditorContDup(device: theClass)
        }
        

//      MARK: - Toolbar   * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
        .toolbar {
 
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newClass = Device.makeDefault()
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
       
 */
        
//      MARK: - Task Modifier    * * * * * * * * * * * * * * * * * * *  * * * * * * * * * *
        .task {
            if devicesViewModel.ignoreLoading {
                devicesViewModel.ignoreLoading = false
                // Don't load the classes if ignoreLoading is true
            } else {
                // Load the classes if ignoreLoading is false
                await loadTheClasses()
                devicesViewModel.ignoreLoading = false
            }

        }
    }
}


//      MARK: - Extension  subView  school class row view in the list   * * * * * * * *
struct DeviceRow : View  {
    let device: TheDevice
    var body: some View {
        NavigationLink(value: device) {
            VStack(alignment: .leading, spacing: 6.0) {
                Text(device.name).font(.headline)
                Text(device.serialNumber).font(.caption)
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

private extension DeviceListView {
    func loadTheClasses() async {
        do {
            try await devicesViewModel.loadData2()
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }
}

//struct DeviceListView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Create some mock Device objects
//        let mockClasses = [
//            Device(uuid: "001", name: "dldldlld", description: "kwkwkkw", locationId: 1, userGroupId: 10),
//            Device(uuid: "002", name: "Morning", description: "Some data", locationId: 1, userGroupId: 8) // Other properties
//            // Add more classes as needed
//        ]
//        let devicesViewModel = DevicesViewModel(schoolClasses: mockClasses)
//
//        return DeviceListView(newClass: Device.makeDefault())
//            .environmentObject(devicesViewModel)
//            .environmentObject(teacherItems())
//    }
//}





#Preview {
    DeviceListView()
}



*/
