    //
    //  LocationViewModel.swift
    //  list the users
    //
    //  Created by Steven Hertz on 3/20/23.
    //

import Foundation

import SwiftUI
//@MainActor
class AppWorkViewModel: ObservableObject {
    
    @Published var locations = [Location]()
    @Published var selectedLocationIdx: Int = 0 {
        didSet {
            currentLocation = locations[selectedLocationIdx]
        }
    }
    @Published var currentLocation = Location(id: 0, name: "")
    @Published var isLoading = false
    @Published var isLoaded = false
    @Published var uniqueID = UUID()
    @Published var doingEdit = false
    @Published var doUpdate = false

    
    @Published var picClassDict: [Int: String] = [0: "abb340de-2faa-4dc8-bc9c-a53c0d31d51d", 1: "00c934d5-c9fa-4cb7-bbab-5589a6d30c67"]
    @Published var picClassIDDict: [Int: Int] =  [0: 20, 1: 22]

    @Published var teacherGroupDict: [Int: Int] =  [0: 3, 1: 21]
    
    public func getpicClass() -> String {
        picClassDict[currentLocation.id]!
    }
    
    public func getIDpicClass() -> Int {
        picClassIDDict[currentLocation.id]!
    }
    
    public func getTeacherGroup() -> Int {
        teacherGroupDict[currentLocation.id]!
    }
    
    public func getUsersInTeacherGroup() async -> [Int]? {
        do {
            let userResponse: UserResponse = try await ApiManager.shared.getData(from: .getUsersInGroup(groupID: teacherGroupDict[currentLocation.id]!))
            dump(userResponse)
            let ids = userResponse.users.map { $0.id }
            return ids
        } catch {
            //  FIXME: -  put in alert that will display appropriate error message
            print(error.localizedDescription)
        }
        return nil
    }
    
    public func getTeacherAuth() -> String {
        "9c74b8d6a4934ca986dfe46592896801"
    }
    

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

    
    @MainActor
    static func instantiate() -> AppWorkViewModel {
        let viewModel = AppWorkViewModel()
        Task {
            do {
                let locationsResponse: LocationsResponse = try await ApiManager.shared.getData(from: .getLocations)

                    viewModel.locations = locationsResponse.locations
                    viewModel.selectedLocationIdx = 1
                    viewModel.currentLocation = viewModel.locations[viewModel.selectedLocationIdx]
                    viewModel.isLoaded = true
            } catch {
                print("major error")
            }
        }
        return viewModel
    }
}
