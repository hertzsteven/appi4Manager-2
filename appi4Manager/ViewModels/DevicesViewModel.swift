//
//  DevicesViewModel.swift
//  appi4Manager
//
//  Created by Steven Hertz on 1/4/24.
//



 
 
import Foundation
//
//  ClassesViewModel.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import SwiftUI

@MainActor
class DevicesViewModel: ObservableObject {

    @Published var devices = [TheDevice]()
    @Published var isLoading = false
    @Published var ignoreLoading = false

    init(devices: [TheDevice] = []) {
         self.devices = devices
     }

    
//    init() {
//        Task {
//            isLoading = true
//            do {
//                let resposnse: DeviceResponse = try await ApiManager.shared.getData(from: .getDevicees)
//                self.schoolClasses = resposnse.classes
//                isLoading = false
//            } catch {
//                fatalError("lost")
//            }
//        }
//    }
    
//    func loadData() throws {
//        guard !isLoading else { return }
//
//        isLoading = true
//        defer { isLoading = false }
//
//        Task {
//            let resposnse: DeviceResponse = try await ApiManager.shared.getData(from: .getDevicees)
//            DispatchQueue.main.async {
//                self.schoolClasses = resposnse.classes
//            }
//        }
//    }
    

    func loadData2() async throws {
        

        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
//        try await Task.sleep(nanoseconds: 3 * 1_000_000_000) // 1 second = 1_000_000_000 nanoseconds
        let resposnse: DeviceListResponse = try await ApiManager.shared.getData(from: .getDevices(assettag: nil) )
//        DispatchQueue.main.async {
            self.devices = resposnse.devices
            print(self.devices.first)
//        }
        
    }
    

    
/* 
    func addClass(device: Device) async throws -> String {
        let responseCreateClassResponse: CreateaClassResponse = try await ApiManager.shared.getData(from: .createaClass(name: device.name, description: device.description, locationId:  String(device.locationId)))
        var newSchoolClass = device
        newSchoolClass.uuid = responseCreateClassResponse.uuid
        self.devices.append(newSchoolClass)
        return newSchoolClass.uuid
    }
 */


/* 
     func updateSchoolClass2(device: Device) async throws {
         try await ApiManager.shared.getDataNoDecode(from: .updateaClass(uuid: device.uuid, name: device.name, description: device.description))

    }
 */

    
    
/* 
    static func updateSchoolClass(device: Device) async  {
        do {
            _ = try await ApiManager.shared.getDataNoDecode(from: .updateaClass(uuid: device.uuid, name: device.name, description: device.description))

        } catch let error as ApiError {
                //  FIXME: -  put in alert that will display approriate error message
            print(error.localizedDescription)
        } catch {
            print(error.localizedDescription)
        }

    }
 */

    
    
//    func filterSchoolClassesinLocation(_ locationId: Int,
//                                       dummyPicClassToIgnore: String) -> Array<Device> {
//        var filteredClassesbyLocation = [Device]()
//
//        filteredClassesbyLocation = schoolClasses.filter{ device in
//            device.locationId  == locationId &&
//            (device.userGroupId  != TeacherItems.shared.schoolClassDictionaryGroupID[locationId]) &&
//            !(device.uuid      == dummyPicClassToIgnore)
//        }
//
//        return filteredClassesbyLocation
//    }


//    func filterdevicesBySchoolClass(_ locationId: Int, schoolClassGroupID: Int) -> Array<TheDevice> {
//        var filteredDevicesBySchoolClass = [TheDevice]()
//
//        filteredDevicesBySchoolClass = devices.filter{ theDevice in
//            theDevice.assetTag == String(schoolClassGroupID) &&
//            theDevice.locationId == locationId
//        }
//        return filteredDevicesBySchoolClass
//    }

    func filterdevicesBySchoolClass(schoolClassGroupID: Int) -> Array<TheDevice> {
        var filteredDevicesBySchoolClass = [TheDevice]()
        
        filteredDevicesBySchoolClass = devices.filter{ theDevice in
            theDevice.assetTag == String(schoolClassGroupID)
        }
        return filteredDevicesBySchoolClass
    }

 
/*
    func delete(_ device: Device) {
        devices.removeAll { $0.uuid == device.uuid }
    }
 */
    
    
/* 
    func add(_ device: Device) {
        devices.append(device)
    }
 */
    
    
//    func exists(_ device: Device) -> Bool {
//        devices.contains(device)
//    }
    
    

/* 
    
    func sortedClasses(nameFilter searchStr: String = "", selectedLocationID: Int) -> Binding<[Device]> {
         Binding<[Device]>(
            get: {
                self.devices
                    .sorted { $0.name < $1.name }
//                    .filter({ theClass in
//                      theClass.locationId == ApiHelper.globalLocationId || ApiHelper.globalLocationId == 100
//                    })
                    .filter({ schoolclass in
                        schoolclass.locationId == selectedLocationID
                    })

                    .filter {
                        if searchStr.isEmpty  {
                          return  true
                        } else {
                            return  $0.name.lowercased().contains(searchStr.lowercased())
                        }
            }
             },
             set: { devices in
                 for device in devices {
                     if let index = self.devices.firstIndex(where: { $0.uuid == device.uuid }) {
                         self.devices[index] = device
                     }
                 }
             }
         )
     }
 */
}


