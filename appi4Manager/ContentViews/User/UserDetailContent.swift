//
//  UserDetailContent.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import SwiftUI
import _PhotosUI_SwiftUI

struct UserDetailContent: View {

    @EnvironmentObject var studentPicStubViewModel: 	StudentPicStubViewModel
    @EnvironmentObject var usersViewModel: 			UsersViewModel
    @EnvironmentObject var appWorkViewModel: 			AppWorkViewModel
    @EnvironmentObject var teacherItems: TeacherItems

    @Environment(\.dismiss) private var dismiss

    @Binding var user: 		User
    @Binding var isDeleted: Bool
    @Binding var isNew: 	Bool
    
    @State private var userImage: Image? = nil
    @StateObject var imagePicker = ImagePicker()
    
    @State private var showDeleteAlert = false

    let urlPic: URL
    
/* 
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
 */


    fileprivate func deleteTheUser() {
        print("we are about to delete the user \(user.id)")
        isDeleted = true
        
        Task {
            do {
                usersViewModel.delete(user)
                print("break")
                let response = try await ApiManager.shared.getDataNoDecode(from: .deleteaUser(id: user.id))
                dump(response)
                
                
            } catch let error as ApiError {
                    //  FIXME: -  put in alert that will display approriate error message
                print(error.description)
            }
        }
        dismiss()
    }
    
    var body: some View {
        
        Form {
            Section(header: Text("Photo")) {
                VStack(alignment: .center) {
                    
                    HStack {                        
                        
                        // photo picker
                        PhotosPicker(selection: $imagePicker.imageSelection,
                                     matching: .images) {
                            Text("Select a photo")
                        }
                        .tint(.purple)
                        .controlSize(.large)
                        .buttonStyle(.borderedProminent)
                        .padding()
                        .onAppear {
//                            imagePicker.studentId = user.id
//                            imagePicker.teachAuth = "9c74b8d6a4934ca986dfe46592896801"
                        }
                        .onDisappear {
                            print("-- in disappear")
                            task {
                                do {
                                    try await studentPicStubViewModel.reloadData(uuid: teacherItems.getpicClass())
                                } catch {
                                    print("ellelelell  Big error")
                                }
                            }
                            }
                        
                        // delete button
                        if userImage != nil {
                            Button(action: {
                                self.userImage = nil
                            }) {
                                Text("Delete Image")
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        
                        Spacer()
                        
                        // if an image exists
                        if let image = imagePicker.image {
                            image
                                .resizable()
                                .scaledToFit() // Display the loaded image
                                .clipShape(Circle())
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                                )
                                .onAppear {
                                    teacherItems.uniqueID = UUID()
                                }
                        } else {
                            AsyncImage(url: urlPic) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView() // Display a progress view while the image is loading
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit() // Display the loaded image
                                        .clipShape(Circle())
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                                        )

                                case .failure:
                                    Text("Failed to load image") // Display an error message if the image fails to load
                                @unknown default:
                                    fatalError()
                                }
                            }
                        }
                    } // Hstack end
                }
            }
            Section(header: Text("Name")) {
                TextField("First Name", text: $user.firstName )
                    .padding([.top, .bottom], 8)
                TextField("Last Name", text: $user.lastName )
                    .padding([.top, .bottom], 8)
            }
            Section(header: Text("Notes")) {
                TextField("Notes", text: $user.notes )
                    .padding([.top, .bottom], 8)
            }
                Section(header: Text("email")) {
                    TextField("email", text: $user.email )
                    .padding([.top, .bottom], 8)
            }
                    
            .alert("Delete User?", isPresented: $showDeleteAlert) {
                Button(role: .destructive) {
                    deleteTheUser()
                } label: {
                    Text("Delete")
                }
            } message: {
                Text("This will permanently delete the user.")
            }
            .textCase(nil)
            
            
            if !isNew {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Text("Delete User")
                        .font(Font.custom("SF Pro", size: 17))
                        .foregroundColor(Color(UIColor.systemRed))
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        

        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    

}
class SampleStudentPicStubViewModel: ObservableObject {}

class SampleUsersViewModel: ObservableObject {}

class SampleAppWorkViewModel: ObservableObject {
    func getpicClass() -> UUID {
        return UUID()
    }
}
struct UserDetailContent_Previews: PreviewProvider {
    @State static var sampleUser: User = User(id: 1, locationId: 0, deviceCount: 0, email: "", groupIds: [], groups: [], teacherGroups: [], firstName: "llsls", lastName: "slslsl", username: "slmdlm", notes: "dlldkdk", modified: "11/11/2023")
    
    @State static var isDeleted: Bool = false
    @State static var isNew: Bool = false
    
    static var previews: some View {
        UserDetailContent(user: $sampleUser, isDeleted: $isDeleted, isNew: $isNew, urlPic: URL(string: "https://via.placeholder.com/150")!)
            .environmentObject(SampleStudentPicStubViewModel())
            .environmentObject(SampleUsersViewModel())
            .environmentObject(SampleAppWorkViewModel())
    }
}

//struct UserDetailContent_Previews: PreviewProvider {
// //   @EnvironmentObject var usersViewModel: UsersViewModel
//    static var previews: some View {
//        UserDetailContent(user:  .constant(User(id: 3, locationId: 0, deviceCount: 0, email: "fkf", groupIds: [], groups: [], teacherGroups: [], firstName: "Sam", lastName: "Ashe", username: "dkdnfjjf", notes: "fkfkkf", modified: "12/33/44")), isDeleted: .constant(false), isNew: .constant(false), usersViewModel: _usersViewModel)
//    }
//}
