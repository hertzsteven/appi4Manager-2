//
//  TestOutView.swift
//  list the users
//
//  Created by Steven Hertz on 2/9/23.
//

import SwiftUI
import PhotosUI



struct TestOutView: View {
    
    @StateObject var imagePicker = ImagePicker()
    @State private var showAlert = false
    @State private var errorMessage = ""

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
                        await processSchoolClasses()
                        print("we will process the classes")
                    }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            

            Button("Check For Teacher") {
                    Task {
                        let resposnsex: UserResponse = try await ApiManager.shared.getData(from: .getUsers)
                        dump(resposnsex)
                        let resposnse: MDMGroupsResponse = try await ApiManager.shared.getData(from: .getGroups)
                        dump(resposnse)
//                        print(resposnse)

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
            let hasXYZClass = schoolClasses.contains { $0.locationId == locationId && $0.name == "abcdef" }
            if !hasXYZClass {
                try await createClass(for: locationId, name: "abcdef")
                print("in creating classes")
            }
        }
        print("finished checking and creating classes")
    }
    
    fileprivate func makeDictofSpecialClass() async throws {
        do {
            let resposnseSchoolClasses: SchoolClassResponse = try await ApiManager.shared.getData(from: .getSchoolClasses)
            let filteredSchoolClasses = resposnseSchoolClasses.classes.filter { $0.name == "abcdef" }
            
            let schoolClassDictionary = filteredSchoolClasses.reduce(into: [Int: String]()) { (dict, schoolClass) in
                dict[schoolClass.locationId] = schoolClass.uuid
            }
                // Output the dictionary
            for (location, uuid) in schoolClassDictionary {
                print("Location: \(location), UUID: \(uuid)")
            }
            
            let schoolClassDictionaryGroupID = filteredSchoolClasses.reduce(into: [Int: Int]()) { (dict, schoolClass) in
                dict[schoolClass.locationId] = schoolClass.userGroupId
            }
                // Output the dictionary
            for (location, classGroupID) in schoolClassDictionaryGroupID {
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
