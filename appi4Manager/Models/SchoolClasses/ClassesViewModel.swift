//
//  ClassesViewModel.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import SwiftUI

@MainActor
class ClassesViewModel: ObservableObject {

    @Published var schoolClasses = [SchoolClass]()
    @Published var isLoading = false
    @Published var ignoreLoading = false

    init(schoolClasses: [SchoolClass] = []) {
         self.schoolClasses = schoolClasses
     }

    
//    init() {
//        Task {
//            isLoading = true
//            do {
//                let resposnse: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
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
//            let resposnse: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
//            DispatchQueue.main.async {
//                self.schoolClasses = resposnse.classes
//            }
//        }
//    }
    

    func loadData2() async throws {
        

        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: 3 * 1_000_000_000) // 1 second = 1_000_000_000 nanoseconds

        let resposnse: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
        DispatchQueue.main.async {
            self.schoolClasses = resposnse.classes
        }
        
    }
    

    
    func addClass(schoolClass: SchoolClass) async throws -> String {
        let responseCreateClassResponse: CreateaClassResponse = try await ApiManager.shared.getData(from: .createaClass(name: schoolClass.name, description: schoolClass.description, locationId:  String(schoolClass.locationId)))
        var newSchoolClass = schoolClass
        newSchoolClass.uuid = responseCreateClassResponse.uuid
        self.schoolClasses.append(newSchoolClass)
        return newSchoolClass.uuid
    }


     func updateSchoolClass2(schoolClass: SchoolClass) async throws {
         try await ApiManager.shared.getDataNoDecode(from: .updateaClass(uuid: schoolClass.uuid, name: schoolClass.name, description: schoolClass.description))

    }

    
    
    static func updateSchoolClass(schoolClass: SchoolClass) async  {
        do {
            _ = try await ApiManager.shared.getDataNoDecode(from: .updateaClass(uuid: schoolClass.uuid, name: schoolClass.name, description: schoolClass.description))

        } catch let error as ApiError {
                //  FIXME: -  put in alert that will display approriate error message
            print(error.description)
        } catch {
            print(error.localizedDescription)
        }

    }

    
    
    func filterSchoolClassesinLocation(_ locationId: Int, dummyPicClassToIgnore: String) -> Array<SchoolClass> {
        var filteredClassesbyLocation = [SchoolClass]()
        
        filteredClassesbyLocation = schoolClasses.filter{ schoolClass in
            schoolClass.locationId  == locationId &&
            !(schoolClass.uuid      == dummyPicClassToIgnore)
        }
        
        return filteredClassesbyLocation
    }
    

//    init() {
//    }
//
//
//    func loadData() throws {
//        guard !isLoading else { return }
//        isLoading = true
//        Task {
//            let resposnse: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
//            DispatchQueue.main.async {
//                self.schoolClasses = resposnse.classes
//            }
//        }
//    }
//
    
    func delete(_ schoolClass: SchoolClass) {
        schoolClasses.removeAll { $0.uuid == schoolClass.uuid }
    }
    
    
    func add(_ schoolClass: SchoolClass) {
        schoolClasses.append(schoolClass)
    }
    
    
    func exists(_ schoolClass: SchoolClass) -> Bool {
        schoolClasses.contains(schoolClass)
    }
    
    

    
    func sortedClasses(nameFilter searchStr: String = "", selectedLocationID: Int) -> Binding<[SchoolClass]> {
         Binding<[SchoolClass]>(
            get: {
                self.schoolClasses
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
             set: { schoolClasses in
                 for schoolClass in schoolClasses {
                     if let index = self.schoolClasses.firstIndex(where: { $0.uuid == schoolClass.uuid }) {
                         self.schoolClasses[index] = schoolClass
                     }
                 }
             }
         )
     }
}
