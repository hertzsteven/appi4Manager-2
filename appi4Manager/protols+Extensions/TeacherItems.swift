//
//  TeacherItems.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/8/23.
//

import Foundation


@MainActor
class TeacherItems: ObservableObject {
//    static let shared = TeacherItems()
    
    @Published var isLoaded = false
    @Published var isLoading = false
    @Published var uniqueID = UUID()
    @Published var doingEdit = false
    @Published var doUpdate = false

    @Published var MDMlocations:                   Array<Location>  = []
    @Published var currentLocation:                Location        = Location(id: 0, name: "")
    @Published var selectedLocationIdx:            Int = 0 {
        didSet {
            currentLocation = MDMlocations[selectedLocationIdx]
        }
    }
    
    @Published var schoolClassDictionaryGroupID:   [Int : Int]     = [:]
    @Published var schoolClassDictionaryUUID:      [Int : String]  = [:]
    @Published var teacherGroupDict:               [Int : Int]     = [:]
    @Published var teacherUserDict:                [Int : Int]     = [:]
    @Published var teacherAuthToken = ""
    
//    private init() {
//            // Private initializer to prevent external instantiation
//    }
}

extension TeacherItems {
    
    public func getpicClass() -> String {
        schoolClassDictionaryUUID[currentLocation.id]!
    }
    
    public func getIDpicClass() -> Int {
        schoolClassDictionaryGroupID[currentLocation.id]!
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
        teacherAuthToken
//        "9c74b8d6a4934ca986dfe46592896801"
    }
    
}

extension TeacherItems {

    func exSetup() async {
        do {
            try await processLocations()
            try await processSchoolClasses()
            try await processTeacherUsers()
            try await processTeacherGroups()
//            try await Task.sleep(nanoseconds: 10_000_000_000)
            DispatchQueue.main.async {
                self.isLoaded = true
            }
        } catch {
            print("Error setting up TeacherItems: \(error)")
        }
    }
    
    func processLocations() async throws {
            // get the locations
        do {
            let locationsResponse: LocationsResponse = try await ApiManager.shared.getData(from: .getLocations)
            MDMlocations = locationsResponse.locations
            currentLocation = MDMlocations[selectedLocationIdx]
            print("got locations")
        }
        catch  {
            throw SchoolClassError.retreiveLocationsError
        }
        
    }
    
    
    
    func processTeacherUsers() async {
        do {
            let resposnseUsers: UserResponse = try await ApiManager.shared.getData(from: .getUsers)
            try await checkAndcreateTeacherUsers(users: resposnseUsers.users)
            try await makeDictofTeacherUser()
        } catch let error as SchoolClassError {
            switch error {
            case .other(let originalError):
                print("An unexpected error occurred: \(originalError.localizedDescription)")
            default:
                print("Error occurred: \(error.localizedDescription)")
            }
        } catch {
            print("An unknown error occurred: \(error.localizedDescription)")
        }
        
    }
    
    func checkAndcreateTeacherUsers(users: [User]) async throws {
        let locationIds = Set(users.map { $0.locationId })
        for locationId in locationIds {
            let hasTeacherUser = users.contains { $0.locationId == locationId && $0.username == AppConstants.teacherUserName + String(locationId) }
            if !hasTeacherUser {
                try await createTeacherUser(for: locationId)
            }
        }
    }
    
    func createTeacherUser(for locationId: Int) async throws {
        print("~ Creating Teacher User for locationId: \(locationId)")
        
        let user = User.createUserTeacher(locationId: locationId)
        do {
            let resposnseaddAUser: AddAUserResponse = try await ApiManager.shared.getData(from: .addUsr(user: user))
            let teacherId  = resposnseaddAUser.id
            
        }
        catch  {
            throw SchoolClassError.createClassError
        }
    }
    
    fileprivate func makeDictofTeacherUser() async throws {
        do {
            let resposnseTeacherUsers: UserResponse = try await ApiManager.shared.getData(from: .getUsers)
            
            let filteredTeacherUsers = resposnseTeacherUsers.users.filter { $0.username.contains(AppConstants.teacherUserName) }
            
            teacherUserDict = filteredTeacherUsers.reduce(into: [Int: Int]()) { (dict, usr) in
                dict[usr.locationId] = usr.id
            }
            
                // Output the dictionary
            for (location, id) in teacherUserDict {
                print("Location: \(location), id: \(id)")
            }
            
            
        } catch {
            throw SchoolClassError.dictCreationError
        }
    }
    
    
    /**            *************************            */
    
    func processTeacherGroups() async {
        do {
            let mdmGroupsResponse: MDMGroupsResponse = try await ApiManager.shared.getData(from: .getGroups)
            try await checkAndcreateTeacherGroups(groups: mdmGroupsResponse.groups)
            try await makeDictofTeacherGroup()
            try await finishUpAndGetAuthCode()
        }
        
        catch let error as SchoolClassError {
            switch error {
            case .other(let originalError):
                print("An unexpected error occurred: \(originalError.localizedDescription)")
            default:
                print("Error occurred: \(error.localizedDescription)")
            }
        } catch {
            print("An unknown error occurred: \(error.localizedDescription)")
        }
        
    }
    
    
    func checkAndcreateTeacherGroups(groups: [MDMGroup]) async throws {
        let locationIds = Set(groups.map { $0.locationId })
        for locationId in locationIds {
            let hasTeacherGroup = groups.contains { $0.locationId == locationId && $0.name == AppConstants.teacherGroupName + String(locationId) }
            if !hasTeacherGroup {
                try await createTeacherGroup(for: locationId)
            }
        }
    }
    
    
    func createTeacherGroup(for locationId: Int) async throws {
        print("~ Creating Teacher group for locationId: \(locationId)")
            //        make an instance of a group that has the teacher group properties
        let mdmTeacherGroup = MDMGroup.createTeacherGroup(locationId: locationId)
        
        do {
            let mdmGroupsResponse: AddAUserResponse = try await ApiManager.shared.getData(from: .addGroup(mdmGroup: mdmTeacherGroup))
            print("just created teacher user for location \(locationId) and the id: \(mdmGroupsResponse.id)")
        }
        
        catch  {
            throw SchoolClassError.createClassError
        }
    }
    
    
    fileprivate func makeDictofTeacherGroup() async throws {
        do {
                //            get groups
            let mdmGroupsResponse: MDMGroupsResponse = try await ApiManager.shared.getData(from: .getGroups)
            
                //            filter groups that match the name of the teacher group name
            let filteredTeacherGroups = mdmGroupsResponse.groups.filter { $0.name.contains(AppConstants.teacherGroupName) }
            
                //            make a dictionary from the location and group id this should be saved in some type
            teacherGroupDict = filteredTeacherGroups.reduce(into: [Int: Int]()) { (dict, grp) in
                dict[grp.locationId] = grp.id
            }
            
                //            not needed just to show it
            for (location, id) in teacherGroupDict {
                print("Location: \(location), Teacher group id: \(id)")
            }
        }
        
        catch {
            throw SchoolClassError.dictCreationError
        }
    }
    
    fileprivate func finishUpAndGetAuthCode() async throws {
        
        /*
            let myDictionary = ["first": "Apple", "second": "Banana", "third": "Cherry"]
            
            for (key, value) in myDictionary {
            print("\(key): \(value)")
            }
            */
        
        guard let teacherGroupId    = teacherGroupDict[0] else {fatalError("no teacher group for 0")}
        guard let teacherId         = teacherUserDict[0]  else {fatalError("no teacher user for 0")}
        
            //           lets get the teacherID Info
        let resposnseUserDetail: UserDetailResponse = try await ApiManager.shared.getData(from: .getaUser(id: teacherId))
        dump(resposnseUserDetail)
        let usr = resposnseUserDetail.user
        
            //        check if it needs to be added
        if !usr.groupIds.contains(teacherGroupId) {
                // add the teacher to the teacher group
            print("~ Adding the teacher group to the teacher user")
            let groupIds:Array<Int>  =  [teacherGroupId]
            let responseUpdateUser = try await ApiManager.shared.getDataNoDecode(from: .updateaUser(id: usr.id,
                                                                                                    username: usr.username,
                                                                                                    password: AppConstants.defaultTeacherPwd,
                                                                                                    email: usr.email,
                                                                                                    firstName: usr.firstName,
                                                                                                    lastName: usr.lastName,
                                                                                                    notes: usr.notes,
                                                                                                    locationId: usr.locationId,
                                                                                                    groupIds: groupIds,
                                                                                                    teacherGroups: usr.teacherGroups))
            
            
        }
        
        
        
        
        let responseAuthenticate: AuthenticateReturnObjct = try await ApiManager.shared.getData(from: .authenticateTeacher(company: String(APISchoolInfo.shared.companyId),
                                                                                                                           username: usr.username,
                                                                                                                           password: AppConstants.defaultTeacherPwd))
        teacherAuthToken = responseAuthenticate.token
        dump(responseAuthenticate)
    }
    
    /* -------------------------- */
    
    func processSchoolClasses() async {
        do {
            let resposnseSchoolClasses: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
            try await checkAndCreateClasses(schoolClasses: resposnseSchoolClasses.classes)
            try await makeDictofSpecialClass()
        } catch let error as SchoolClassError {
            switch error {
            case .other(let originalError):
                print("An unexpected error occurred: \(originalError.localizedDescription)")
                    //               errorMessage = "An unexpected error occurred: \(originalError.localizedDescription)"
                    //               showAlert = true
            default:
                print("Error occurred: \(error.localizedDescription)")
                    //               errorMessage = error.localizedDescription
                    //               showAlert = true
            }
        } catch {
            print("An unknown error occurred: \(error.localizedDescription)")
        }
    }
    
    func checkAndCreateClasses(schoolClasses: [SchoolClass]) async throws {
        let locationIds = Set(schoolClasses.map { $0.locationId })
        for locationId in locationIds {
            let hasXYZClass = schoolClasses.contains { $0.locationId == locationId && $0.name == AppConstants.pictureClassName }
            if !hasXYZClass {
                try await createClass(for: locationId, name: AppConstants.pictureClassName)
            }
        }
    }
    
    fileprivate func makeDictofSpecialClass() async throws {
        do {
            let resposnseSchoolClasses: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
            let filteredSchoolClasses = resposnseSchoolClasses.classes.filter { $0.name == AppConstants.pictureClassName }
            
            
            schoolClassDictionaryGroupID = filteredSchoolClasses.reduce(into: [Int: Int]()) { (dict, schoolClass) in
                dict[schoolClass.locationId] = schoolClass.userGroupId
            }
                // Output the dictionary
            for (location, classGroupID) in schoolClassDictionaryGroupID {
                print("Location: \(location), userGroup: \(classGroupID)")
            }
            
            
            schoolClassDictionaryUUID = filteredSchoolClasses.reduce(into: [Int: String]()) { (dict, schoolClass) in
                dict[schoolClass.locationId] = schoolClass.uuid
            }
                // Output the dictionary
            for (location, classGroupUUID) in schoolClassDictionaryUUID {
                print("Location: \(location), ClassUUID: \(classGroupUUID)")
            }
            
            
            
        } catch {
            throw SchoolClassError.dictCreationError
        }
    }
    
    func createClass(for locationId: Int, name: String) async throws {
        print("~ Creating Special picture class for locationId: \(locationId)")
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
}
    
