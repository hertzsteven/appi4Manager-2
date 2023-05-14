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

    
    init() {
        Task {
            isLoading = true
            do {
                let resposnse: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
                self.schoolClasses = resposnse.classes
                isLoading = false
            } catch {
                fatalError("lost")
            }
        }
    }


    func getSchoolClassesinLocation(_ locationId: Int, dummyPicClassToIgnore: String) -> Array<SchoolClass> {
        var filteredClassesbyLocation = [SchoolClass]()
        
        filteredClassesbyLocation = schoolClasses.filter{ schoolClass in
            schoolClass.locationId  == locationId &&
            !(schoolClass.uuid      == dummyPicClassToIgnore)
        }
        
        return filteredClassesbyLocation
    }
    
    
    func loadData() throws {
        guard !isLoading else { return }
        isLoading = true
        Task {
            let resposnse: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
            DispatchQueue.main.async {
                self.schoolClasses = resposnse.classes
            }
        }
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
    
    
    static func updateSchoolClass(schoolClass: SchoolClass) async -> Void {
        do {
            _ = try await ApiManager.shared.getDataNoDecode(from: .updateaClass(uuid: schoolClass.uuid, name: schoolClass.name, description: schoolClass.description))

        } catch let error as ApiError {
                //  FIXME: -  put in alert that will display approriate error message
            print(error.description)
        } catch {
            print(error.localizedDescription)
        }

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
