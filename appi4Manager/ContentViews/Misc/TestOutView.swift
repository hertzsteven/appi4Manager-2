//
//  TestOutView.swift
//  list the users
//
//  Created by Steven Hertz on 2/9/23.
//

import SwiftUI
import PhotosUI

class TeacherItems {
    static let shared = TeacherItems()

    var isLoaded = false
    var schoolClassDictionaryGroupID: [Int : Int] = [:]
    var teacherGroupDict: [Int : Int] = [:]
    var teacherUserDict: [Int : Int] = [:]
    var theToken = ""

    private init() {
        // Private initializer to prevent external instantiation
    }

    func setup() async {
        do {
            try await processSchoolClasses()
            try await processTeacherUsers()
            try await processTeacherGroups()
            isLoaded = true
        } catch {
            print("Error setting up TeacherItems: \(error)")
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
                                                                                   password: "123456",
                                                                                   email: usr.email,
                                                                                   firstName: usr.firstName,
                                                                                   lastName: usr.lastName,
                                                                                   notes: usr.notes,
                                                                                   locationId: usr.locationId,
                                                                                   groupIds: groupIds,
                                                                                   teacherGroups: usr.teacherGroups))

            
        }

        

    
    let responseAuthenticate: AuthenticateReturnObjct = try await ApiManager.shared.getData(from: .authenticateTeacher(company: "2001128",
                                                                                                             username: usr.username,
                                                                                                            password: "123456"))
        theToken = responseAuthenticate.token
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



struct TestOutView: View {
    
    @StateObject var imagePicker = ImagePicker()
    @State private var showAlert = false
    @State private var errorMessage = ""
        //    var teacherItems = TeacherItems()
    
    
    
    var body: some View {
        VStack(spacing: 12) {
            
            PhotosPicker(selection: $imagePicker.imageSelection,
                         matching: .images) {
                Label("Select a photo", systemImage: "photo")
            }
                         .tint(.purple)
                         .controlSize(.large)
                         .buttonStyle(.borderedProminent)
                         .padding()
                         .onAppear {
                                 //                imagePicker.studentId = 16
                                 //                imagePicker.teachAuth = "9c74b8d6a4934ca986dfe46592896801"
                         }
            if let image = imagePicker.image {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Text("Tap the menu bar button to select a photo.")
            }
            
            Text("I am over here")
            Button("Create Test category") {
                let appCtg = AppCategory.makeDefault()
                FirestoreManager().writeAppCategory(appCategory: appCtg)
                print("doneit")
            }
            Button {
                print("getting the lessons")
                Task {
                    do {
                        let appxOne: Appx = try await ApiManager.shared.getData(from: .getanApp(appId: 9))
                        dump(appxOne)
                        print("appxOne")
                        
                        
                        
                        let lessonsDetailResponse: LessonDetailResponse = try await ApiManager.shared.getData(from: .getLessonDetail(teachAuth: "9c74b8d6a4934ca986dfe46592896801", id: 25))
                        dump(lessonsDetailResponse)
                        print(lessonsDetailResponse)
                        
                        
                        let lessonsListResponse: LessonsListResponse = try await ApiManager.shared.getData(from: .getLessons(teachAuth: "9c74b8d6a4934ca986dfe46592896801"))
                        dump(lessonsListResponse)
                        print(lessonsListResponse)
                        
                        
                        
                        let locationsResponse: LocationsResponse = try await ApiManager.shared.getData(from: .getLocations)
                        dump(locationsResponse)
                        print(locationsResponse)
                        
                        let userRespnse: UserResponse = try await ApiManager.shared.getData(from: .getUsersInGroup(groupID: 21))
                        dump(userRespnse)
                        print("resposnseUserDetail")
                        
                        
                        
                        
                        
                        let z = try await ApiManager.shared.getDataNoDecode(from: .assignToClass(uuid: "3c0945a1-679d-4e0b-b70c-ad8aaa4481de", students: [6,48], teachers: [2]))
                        dump(z)
                        
                        let id =  47
                        let locationId = 0
                        let email =  ""
                        let username =  "xxx_apjgkjkjgjgi_user2"
                        let firstName =  "Jeremy"
                        let lastName =  "Stei"
                        let groupIds:Array<Int>  =  [1,5]
                        let teacherGroups:Array<Int>  =  [3]
                        let notes =  "change6"
                        let y = try await ApiManager.shared.getDataNoDecode(from: .updateaUser(id: id,
                                                                                               username: username,
                                                                                               password: "",
                                                                                               email: email,
                                                                                               firstName: firstName,
                                                                                               lastName: lastName,
                                                                                               notes: notes,
                                                                                               locationId: locationId,
                                                                                               groupIds: groupIds,
                                                                                               teacherGroups: teacherGroups))
                        dump(y)
                        
                        let x = try await ApiManager.shared.getDataNoDecode(from: .createaClass(name: "New class name", description: "created from testoutview", locationId: "1"))
                        
                        let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(from: .getStudents(uuid: ApiHelper.classuuid))
                        dump(classDetailResponse)
                        
                        let resposnse: AuthenticateReturnObjct = try await ApiManager.shared.getData(from: .authenticateTeacher(company: ApiHelper.company, username: ApiHelper.username, password: ApiHelper.password))
                        dump(resposnse)
                        print("break")
                        
                        let resposnseUserDetail: UserDetailResponse = try await ApiManager.shared.getData(from: .getaUser(id: resposnse.authenticatedAs.id))
                        dump(resposnseUserDetail)
                        print("resposnseUserDetail")
                        
                            // get classes
                        let resposnseSchoolClasses: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
                        dump(resposnseSchoolClasses)
                        print("resposnseSchoolClasses")
                        
                            //                        let cls = resposnseSchoolClasses.classes.contains {clss in
                            //                            clss.userGroupId == ApiHelper.clssuserGroupId
                            //                        }
                            //                        dump(cls)
                        
                    } catch let error as ApiError {
                            //  FIXME: -  put in alert that will display approriate error message
                        print(error.description)
                    }
                    
                    print("in task afetr do")
                    
                }
                print("after task")
                
            } label: {
                Text("get the students")
            }
            
            Button("Process the classes") {
                    // Where you want to call the function
                Task {
                        //                    await processSchoolClasses()
                    await TeacherItems.shared.setup()
                    dump(TeacherItems.shared)
                    print("we will process the classes")
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            
            
            Button("Check For Teacher") {
                Task {
                    let resposnsex: AuthenticateReturnObjct = try await ApiManager.shared.getData(from: .authenticateTeacher(company: "2001128", username: "**appi4Teacher-NoModification**xQQRR0", password: "123456"))
                    dump(resposnsex)
                    print("break")
                        //                    try await processTeacherUsers()
                        //                    try await processTeacherGroups()
                    
                    print("wait")
                    
                    
                    let resposnseUserDetail: UserDetailResponse = try await ApiManager.shared.getData(from: .getaUser(id: 96))
                    dump(resposnseUserDetail)
                    let usr = resposnseUserDetail.user
                    print("resposnseUserDetail")
                    let groupIds:Array<Int>  =  [96]
                    let y = try await ApiManager.shared.getDataNoDecode(from: .updateaUser(id: usr.id,
                                                                                           username: usr.username,
                                                                                           password: "123456",
                                                                                           email: usr.email,
                                                                                           firstName: usr.firstName,
                                                                                           lastName: usr.lastName,
                                                                                           notes: usr.notes,
                                                                                           locationId: usr.locationId,
                                                                                           groupIds: groupIds,
                                                                                           teacherGroups: usr.teacherGroups))
                    dump(y)
                    print(y)
                    
                    
                    
                    
                    
                        //                    try await processTeacherGroups()
                        //
                        //                    try await processTeacherUsers()
                        //
                    let resposnse: MDMGroupsResponse = try await ApiManager.shared.getData(from: .getGroups)
                    dump(resposnse)
                        // get the locations
                    let mdmGroups = resposnse.groups
                    let locationsIds = Set(mdmGroups.map { $0.locationId })
                        // check in each locations if there is a tracherGroup name
                    for locationid in locationsIds {
                        let hasMDMTeacherGroup = mdmGroups.contains {
                            $0.locationId == locationid && $0.name == "SpecialTracherGroupName"
                        }
                        if !hasMDMTeacherGroup {
                            print("need to create texhers group for \(locationid)")
                        }
                    }
                    
                    
                    let mdmGroup = MDMGroup(id: 0, locationId: 1, name: "QWQWQW", description: "yes no maybe", userCount: 0, acl: MDMGroup.Acl(teacher: "allow", parent: "inherit"), modified: "inherit")
                    let resposnseaddAGroup: AddAUserResponse = try await ApiManager.shared.getData(from: .addGroup(mdmGroup: mdmGroup))
                    print(resposnseaddAGroup)
                    dump(resposnseaddAGroup)
                    let mdmGroup2 = MDMGroup(id: resposnseaddAGroup.id, locationId: 1, name: "AAAAPI Updated Group2", description: "I updatted it now after created", userCount: 0, acl: MDMGroup.Acl(teacher: "inherit", parent: "inherit"), modified: "inherit")
                    let responseFromUpdatingUser = try await ApiManager.shared.getDataNoDecode(from: .updateaGroup(mdmGroup: mdmGroup2))
                    print(responseFromUpdatingUser)
                    dump(responseFromUpdatingUser)
                    
                        //                        await processSchoolClasses()
                        //                        print("we will process the classes")
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            
            
            Button("Authenticate Teacher") {
                Task {
                        //                         let resposnse: AuthenticateReturnObjct = try await ApiManager.shared.getData(from: .authenticateTeacher(company: ApiHelper.company, username: ApiHelper.username, password: ApiHelper.password))
                        //                         let resposnse: AuthenticateReturnObjct = try await ApiManager.shared.getData(from: .authenticateTeacher(company: ApiHelper.company, username: "teacherlila", password: "123456"))
                        //                         let resposnse: AuthenticateReturnObjct = try await ApiManager.shared.getData(from: .authenticateTeacher(company: ApiHelper.company, username: "FC1E83770E22", password: "123456"))
                    let resposnse: AuthenticateReturnObjct = try await ApiManager.shared.getData(from: .authenticateTeacher(company: ApiHelper.company, username: "coorddavid", password: "123456"))
                    print(resposnse.token)
                    dump(resposnse)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            
            Button {
                print("getting the apps")
                Task {
                    do {
                        let appResponse: AppResponse = try await ApiManager.shared.getData(from: .getApps)
                            //                        dump(appResponse)
                        
                        for app in appResponse.apps {
                                //                            let record = CKRecord(recordType: "appProfiles", recordID: CKRecord.ID(recordName: "\(app.bundleId)"))
                            do {
                                print(app.name, app.bundleId, app.icon)
                                
                                    //                                if app.name.contains("TeachMe") {
                                    //                                    print(app.name, "it is doodle")
                                    ////                                let recordID = CKRecord.ID(recordName: "\(app.bundleId)-\(app.id)")
                                    //                                    let record = CKRecord(recordType: "appProfiles", recordID: CKRecord.ID(recordName: "\(app.bundleId)"))
                                    //                                    record["appBundleId"] = app.bundleId
                                    //                                    record["name"] = app.name
                                    //                                    record["id"] = app.id
                                    //                                    record["locationId"] = app.locationId
                                    //                                    record["description"] = app.description
                                    //                                    record["icon"] = app.icon
                                    //                                    record["category"] = "dummy"
                                    //                                    record["profileName"] = "duummy"
                                    //                                    /// save it
                                    //                                    dbs.save(record) { (record, error) in
                                    //                                    print("```* - * - Saving . . .")
                                    //                                        //   DispatchQueue.main.async {
                                    //                                    if let error = error {
                                    //                                        print("```* - * - error saving it \(error)")
                                    //                                    } else {
                                    //                                        print("```* - * - succesful ***")
                                    //                                        print(record as Any)
                                    //                                    }
                                    //                                         }
                                    //                                } else {
                                    ////                                    print("not doing ", app.name)
                                    ////                                    print("\(app.bundleId)-\(app.id)")
                                    //                                }
                                    //                            }
                            }
                            
                            
                            catch {
                                print("Error fetching records: \(error.localizedDescription)")
                            }
                        }
                        
                    } catch let error as ApiError {
                            //  FIXME: -  put in alert that will display approriate error message
                        print(error.description)
                    }
                    
                    print("in task after do")
                    
                }
                print("after task")
                
            } label: {
                Text("get the apps")
            }
        }
    }
    
    
    mutating func processSchoolClasses() async {
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
                errorMessage = "An unexpected error occurred: \(originalError.localizedDescription)"
                showAlert = true
            default:
                print("Error occurred: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showAlert = true
            }
        } catch {
            print("An unknown error occurred: \(error.localizedDescription)")
            errorMessage = "An unknown error occurred: \(error.localizedDescription)"
            showAlert = true
            
        }
        
    }
    
    func checkAndCreateClasses(schoolClasses: [SchoolClass]) async throws {
        let locationIds = Set(schoolClasses.map { $0.locationId })
        for locationId in locationIds {
            let hasXYZClass = schoolClasses.contains { $0.locationId == locationId && $0.name == AppConstants.pictureClassName }
            if !hasXYZClass {
                try await createClass(for: locationId, name: AppConstants.pictureClassName)
                print("in creating classes")
            }
        }
        print("finished checking and creating classes")
    }
    
    fileprivate mutating func makeDictofSpecialClass() async throws {
        do {
            let resposnseSchoolClasses: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
            let filteredSchoolClasses = resposnseSchoolClasses.classes.filter { $0.name == AppConstants.pictureClassName }
            
            let schoolClassDictionary = filteredSchoolClasses.reduce(into: [Int: String]()) { (dict, schoolClass) in
                dict[schoolClass.locationId] = schoolClass.uuid
            }
                // Output the dictionary
            for (location, uuid) in schoolClassDictionary {
                print("Location: \(location), UUID: \(uuid)")
            }
            
            TeacherItems.shared.schoolClassDictionaryGroupID = filteredSchoolClasses.reduce(into: [Int: Int]()) { (dict, schoolClass) in
                dict[schoolClass.locationId] = schoolClass.userGroupId
            }
                // Output the dictionary
            for (location, classGroupID) in TeacherItems.shared.schoolClassDictionaryGroupID {
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
    
}
    
    




struct TestOutView_Previews: PreviewProvider {
    static var previews: some View {
        TestOutView()
    }
}
