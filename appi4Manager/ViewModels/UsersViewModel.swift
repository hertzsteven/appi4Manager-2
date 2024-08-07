//
//  UsersViewModel.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import SwiftUI


enum UserError: Error {
    case userNotFound
}

@MainActor
class UsersViewModel: ObservableObject {
    
    @Published var users = [User]()
    @Published var isLoading = false
    @Published var ignoreLoading = false
    @Published var isLoaded = false

//    init() {
//        Task {
//            isLoading = true
//            do {
//                let resposnse: UserResponse = try await ApiManager.shared.getData(from: .getUsers)
//                self.users = resposnse.users
//                isLoading = false
//            } catch {
//                fatalError("lost")
//            }
//        }
//    }
    
    init(users: [User] = []) {
        self.users = users
    }
    
//    func loadData() throws {
//        guard !isLoading else { return }
//        isLoading = true
//        Task {
//            let resposnse: UserResponse = try await ApiManager.shared.getData(from: .getUsers)
//            DispatchQueue.main.async {
//                self.users = resposnse.users
//            }
//        }
//    }
    
    func loadData2() async throws {
        
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
//        try await Task.sleep(nanoseconds: 1 * 1_000_000_000) // 1 second = 1_000_000_000 nanoseconds

        let resposnse: UserResponse = try await ApiManager.shared.getData(from: .getUsers)
        DispatchQueue.main.async {
            self.users = resposnse.users
            self.isLoaded = true
        }
        
    }

  func getWithId(_ id: Int) throws -> User {
      if let user = users.first(where: { $0.id == id }) {
          return user
      } else {
          throw UserError.userNotFound
      }
  }

//  func getWithId(_ id: Int) -> User {
//    let x = users.first(where: { usr in
//      usr.id == id
//    })
//
//    if x != nil {
//      return x!
//    } else {
//      fatalError("did not work")
//    }
//  }
//  


    func delete(_ user: User) {
        users.removeAll { $0.id == user.id }
    }
    
    
    func add(_ user: User) {
        users.append(user)
    }
    
    
    func exists(_ user: User) -> Bool {
        users.contains(user)
    }
    
    
    static func updateUser(user: User) async -> Void {
        do {
            _ = try await ApiManager.shared.getDataNoDecode(from: .updateaUser(id: user.id,
                                                                               username: user.username,
                                                                               password: AppConstants.defaultUserPwd ,
                                                                               email: user.email,
                                                                               firstName: user.firstName,
                                                                               lastName: user.lastName,
                                                                               notes: user.notes,
                                                                               locationId: user.locationId,
                                                                               groupIds: user.groupIds,
                                                                               teacherGroups: user.teacherGroups))
            
        } catch let error as ApiError {
                //  FIXME: -  put in alert that will display approriate error message
            print(error.description)
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    
    func updateUser2(user: User) async -> Void {
        do {
            _ = try await ApiManager.shared.getDataNoDecode(from: .updateaUser(id: user.id,
                                                                               username: user.username,
                                                                               password: AppConstants.defaultUserPwd ,
                                                                               email: user.email,
                                                                               firstName: user.firstName,
                                                                               lastName: user.lastName,
                                                                               notes: user.notes,
                                                                               locationId: user.locationId,
                                                                               groupIds: user.groupIds,
                                                                               teacherGroups: user.teacherGroups))
            
        } catch let error as ApiError {
                //  FIXME: -  put in alert that will display approriate error message
            print(error.description)
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    
    func sortedUsers(lastNameFilter searchStr: String = "", selectedLocationID: Int) -> Binding<[User]> {
        Binding<[User]>(
            get: {
                self.users
                    .sorted { $0.lastName < $1.lastName }
                
                    .filter({ usr in
                        usr.locationId == selectedLocationID
                    })
                    .filter {
                        if searchStr.isEmpty  {
                            return  true
                        } else {
                            return  $0.lastName.lowercased().contains(searchStr.lowercased())
                        }
                    }
            },
            set: { users in
                for user in users {
                    if let index = self.users.firstIndex(where: { $0.id == user.id }) {
                        self.users[index] = user
                    }
                }
            }
        )
    }
    
    func sortedUsersNonB(lastNameFilter searchStr: String = "", selectedLocationID: Int, teacherUserID: Int) -> [User] {
        
        self.users
            .sorted { $0.lastName < $1.lastName }
        
            .filter({ usr in
                usr.locationId == selectedLocationID && usr.id != teacherUserID 
            })
            .filter {
                if searchStr.isEmpty  {
                    return  true
                } else {
                    return  $0.lastName.lowercased().contains(searchStr.lowercased())
                }
            }
    }
    func sortedUsersNonBClass(lastNameFilter searchStr: String = "", selectedLocationID: Int, teacherUserID: Int, scGroupid: Int) -> [User] {
        print("location is \(selectedLocationID)")
        print("the group id is \(scGroupid)")
         
        return self.users
             .sorted { $0.lastName < $1.lastName }
         
             .filter({ usr in
                 usr.locationId == selectedLocationID && usr.id != teacherUserID && usr.groupIds.contains(scGroupid)
             })
             .filter {
                 if searchStr.isEmpty  {
                     return  true
                 } else {
                     return  $0.lastName.lowercased().contains(searchStr.lowercased())
                 }
             }
     }

}
