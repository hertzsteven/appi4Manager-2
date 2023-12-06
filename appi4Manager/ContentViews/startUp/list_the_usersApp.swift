//
//  list_the_usersApp.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import SwiftUI
import FirebaseCore

class AppState: ObservableObject {
    @Published private(set) var hasOnboarded: Bool = true
    
    func setHasOnboarded(to hasOnboarded: Bool)  {
        self.hasOnboarded = hasOnboarded
    }
}

  @main
struct list_the_usersApp: App {
    
    init() {
        FirebaseApp.configure()
        print("Configured Firebase")
        Task {
                 await TeacherItems.shared.exSetup()
        }

    }
    
    @StateObject var appWorkViewModel           = AppWorkViewModel.instantiate()
    @StateObject var usersViewModel             = UsersViewModel()
    @StateObject var classDetailViewModel       = ClassDetailViewModel()
    @StateObject var studentPicStubViewModel    = StudentPicStubViewModel()
    @StateObject var classesViewModel           = ClassesViewModel()
    @StateObject var appxViewModel              = AppxViewModel()
    @StateObject var categoryViewModel          = CategoryViewModel()
    @StateObject var appsViewModel              = AppsViewModel()
    
    


    var body: some Scene {
        WindowGroup {
//            TestOutView()
// NavigateToStudentAppProfile()
            if appWorkViewModel.isLoaded  {
                DashboardView()
                    .environmentObject(usersViewModel)
                    .environmentObject(classDetailViewModel)
                    .environmentObject(studentPicStubViewModel)
                    .environmentObject(classesViewModel)
                    .environmentObject(appWorkViewModel)
                    .environmentObject(appxViewModel)
                    .environmentObject(categoryViewModel)
                    .environmentObject(appsViewModel)


            } else {
                ProgressView()
            }
 
            
//             if appWorkViewModel.isLoaded {
//                TabBarController()
//                    .environmentObject(usersViewModel)
//                    .environmentObject(classDetailViewModel)
//                    .environmentObject(classesViewModel)
//                    .environmentObject(appWorkViewModel)
//            } else {
//                ProgressView()
//            }

//             TestOutView()
            
            
            
//            TabBarController()
////            UserListContent(newUser: User.makeDefault())
//                .environmentObject(usersViewModel)
//                .environmentObject(classDetailViewModel)
//                .environmentObject(classesViewModel)
//                .environmentObject(appWorkViewModel)
        }
    }
}
