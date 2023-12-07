    //
    //  LocationViewModel.swift
    //  list the users
    //
    //  Created by Steven Hertz on 3/20/23.
    //

import Foundation

import SwiftUI

enum SchoolClassError: Error {
    case fetchError
    case createClassError
    case dictCreationError
    case retreiveLocationsError
    case other(Error)
    
    var localizedDescription: String {
        switch self {
        case .fetchError:
            return "Failed to fetch school classes."
        case .createClassError:
            return "Failed to create a class."
        case .dictCreationError:
            return "Failed to create a dictionary of classes."
        case .retreiveLocationsError:
            return "Failed to retreive locations"
        case .other(let error):
            return error.localizedDescription
        }
    }
}


//@MainActor
//class AppWorkViewModel: ObservableObject {
    
//    static let SpecialPictureClassName = "ytrewq"
//    
//    @Published var locations = [Location]()
//    @Published var selectedLocationIdx: Int = 0 {
//        didSet {
//            currentLocation = locations[selectedLocationIdx]
//        }
//    }
  
//    @Published var currentLocation = Location(id: 0, name: "")
//    @Published var isLoading = false
//    @Published var isLoaded = false
//    @Published var uniqueID = UUID()
//    @Published var doingEdit = false
//    @Published var doUpdate = false

    
//    @Published var picClassIDDict: [Int: Int] =  [0: 20, 1: 22]
//    @Published var picClassDict: [Int: String] = [0: "abb340de-2faa-4dc8-bc9c-a53c0d31d51d", 1: "00c934d5-c9fa-4cb7-bbab-5589a6d30c67"]

//    @Published var picClassDict: [Int: String] = [:]
//    @Published var picClassIDDict: [Int: Int] =  [:]
//
//    @Published var teacherGroupDict: [Int: Int] =  [0: 3, 1: 21]
    
//    public func getpicClass() -> String {
//        picClassDict[currentLocation.id]!
//    }
//    
//    public func getIDpicClass() -> Int {
//        picClassIDDict[currentLocation.id]!
//    }
//    
//    public func getTeacherGroup() -> Int {
//        teacherGroupDict[currentLocation.id]!
//    }
    
//    public func getUsersInTeacherGroup() async -> [Int]? {
//        do {
//            let userResponse: UserResponse = try await ApiManager.shared.getData(from: .getUsersInGroup(groupID: teacherGroupDict[currentLocation.id]!))
//            dump(userResponse)
//            let ids = userResponse.users.map { $0.id }
//            return ids
//        } catch {
//            //  FIXME: -  put in alert that will display appropriate error message
//            print(error.localizedDescription)
//        }
//        return nil
//    }
//    
//    public func getTeacherAuth() -> String {
//        "9c74b8d6a4934ca986dfe46592896801"
//    }
    

    /*
    public func getUsersInTeacherGroup() -> [Int]? {
//        teacherGroupDict[currentLocation.id]!
        Task {
            do {
                let userRespnse: UserResponse = try await ApiManager.shared.getData(from: .getUsersInGroup(groupID: 21))
                dump(userRespnse)
                let ids = userRespnse.users.map { $0.id }
                return ids
            } catch {
                    //  FIXME: -  put in alert that will display approriate error message
                print(error.localizedDescription)
                
            }

        }
        return nil
    }
    */

/*
    @MainActor
    static func instantiate() -> AppWorkViewModel {
        let viewModel = AppWorkViewModel()
//        Task {
//            do {
//                await viewModel.processSchoolClasses()
//                let locationsResponse: LocationsResponse = try await ApiManager.shared.getData(from: .getLocations)
//
//                    viewModel.locations = locationsResponse.locations
//                    viewModel.selectedLocationIdx = 0
//                    viewModel.currentLocation = viewModel.locations[viewModel.selectedLocationIdx]
//                    viewModel.isLoaded = true
//                dump(viewModel)
//                print("vm")
//            } catch {
//                print("major error")
//            }
//        }
        return viewModel
    }
    
     func processSchoolClasses() async {
        do {
            let resposnseSchoolClasses: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
            try await checkAndCreateClasses(schoolClasses: resposnseSchoolClasses.classes)
            print("before dict")
            try await makeDictofSpecialClass()
            print("after dict")
        } catch let error as SchoolClassError {
            switch error {
            case .other(let originalError):
                print("An unexpected error occurred: \(originalError.localizedDescription)")
//                errorMessage = "An unexpected error occurred: \(originalError.localizedDescription)"
//                showAlert = true
            default:
                print("Error occurred: \(error.localizedDescription)")
//                errorMessage = error.localizedDescription
//                showAlert = true
            }
        } catch {
            print("An unknown error occurred: \(error.localizedDescription)")
//            errorMessage = "An unknown error occurred: \(error.localizedDescription)"
//            showAlert = true
            
        }
        
    }
    
    func checkAndCreateClasses(schoolClasses: [SchoolClass]) async throws {
        let locationIds = Set(schoolClasses.map { $0.locationId })
        for locationId in locationIds {
            let hasXYZClass = schoolClasses.contains { $0.locationId == locationId && $0.name == "SpecialPictureClassName" }
            if !hasXYZClass {
                try await createClass(for: locationId, name: "SpecialPictureClassName")
                print("in creating classes")
            }
        }
        print("finished checking and creating classes")
    }
    
    @MainActor
    fileprivate func makeDictofSpecialClass() async throws {
        do {
            let resposnseSchoolClasses: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
            let filteredSchoolClasses = resposnseSchoolClasses.classes.filter { $0.name == "SpecialPictureClassName" }
            
            picClassDict = filteredSchoolClasses.reduce(into: [Int: String]()) { (dict, schoolClass) in
                dict[schoolClass.locationId] = schoolClass.uuid
            }
                // Output the dictionary
            for (location, uuid) in picClassDict {
                print("Location: \(location), UUID: \(uuid)")
            }
            
            picClassIDDict = filteredSchoolClasses.reduce(into: [Int: Int]()) { (dict, schoolClass) in
                dict[schoolClass.locationId] = schoolClass.userGroupId
            }
                // Output the dictionary
            for (location, classGroupID) in picClassIDDict {
                print("Location: \(location), userGroup: \(classGroupID)")
            }

        } catch {
            print("ddjjdjdjdjjdjj")
            throw SchoolClassError.dictCreationError
        }
    }
    
    func createClass(for locationId: Int, name: String) async throws {
        print("Creating class for locationId: \(locationId)")

        do {
            // create the class
            let resposnseCreateaClassResponse: CreateaClassResponse =
                try await ApiManager.shared.getData(from: .createaClass(name: name, description: "testing from new app", locationId:  String(locationId)))
            
            // put the users is the class
            let theuuid = resposnseCreateaClassResponse.uuid
            // get all users
            let resposnse: UserResponse = try await ApiManager.shared.getData(from: .getUsers)
            // filter to get users in this location
            let filteredUsers = resposnse.users.filter { $0.locationId == locationId }
            // make an array from the user ids
            let justUserIds = filteredUsers.map { $0.id }
            
            _ = try await ApiManager.shared.getDataNoDecode(from: .assignToClass(uuid: theuuid, students: justUserIds, teachers: []))

        } catch  {
            print(error)
            throw SchoolClassError.createClassError
        }
    }
*/
    
//}
