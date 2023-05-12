//
//  ClassDetailViewModel.swift
//  list the users
//
//  Created by Steven Hertz on 2/15/23.
//

import SwiftUI
@MainActor
class ClassDetailViewModel: ObservableObject {

    @Published var uuid: String = ""
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var students = [Student]()
    @Published var teachers = [Student]()
    
    @Published var isLoading = false

    //  FIXME:   Make this a throwing function
    /*
    func getURLpicForStudentWith(_ id: Int) -> URL {
        print("--- good in geturl student id \(id)")
        guard let idx = students.firstIndex(where: { student in
            student.id == id
        }) else {
            print("--- error in geturl student id \(id)")
            return URL(string: "https://developitsnfredu.jamfcloud.com/application/views/default/assets/image/avatar/avatar.png")!
        }
        return students[idx].photo
    }
     */

    /*
    init() {
        Task {
            do {
                let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(from: .getStudents(uuid: "abb340de-2faa-4dc8-bc9c-a53c0d31d51d"))
                self.students = classDetailResponse.class.students
                self.name = classDetailResponse.class.name
            } catch {
                fatalError("lost")
            }
        }
    }
     
    func reloadData() throws {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(from: .getStudents(uuid: "abb340de-2faa-4dc8-bc9c-a53c0d31d51d"))
                self.students = classDetailResponse.class.students
                self.name = classDetailResponse.class.name
            } catch {
                fatalError("lost")
            }
        }
    }
    */
    
//    func delete(_ user: User) {
//        users.removeAll { $0.id == user.id }
//    }
//
//    func add(_ user: User) {
//        users.append(user)
//    }
//
//    func exists(_ user: User) -> Bool {
//        users.contains(user)
//    }
//
//    func sortedUsers() -> Binding<[User]> {
//         Binding<[User]>(
//             get: {
//                 self.users
//                     .sorted { $0.lastName < $1.lastName }
//             },
//             set: { users in
//                 for user in users {
//                     if let index = self.users.firstIndex(where: { $0.id == user.id }) {
//                         self.users[index] = user
//                     }
//                 }
//             }
//         )
//     }
}
