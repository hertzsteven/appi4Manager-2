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
                imagePicker.studentId = 16
                imagePicker.teachAuth = "9c74b8d6a4934ca986dfe46592896801"
            }
            if let image = imagePicker.image {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Text("Tap the menu bar button to select a photo.")
            }
            
            Text("I am over here")
            Button {
                 print("getting the students")
                Task {
                    do {
                      
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

        }
    }
}

struct TestOutView_Previews: PreviewProvider {
    static var previews: some View {
        TestOutView()
    }
}
