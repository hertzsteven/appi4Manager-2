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
    }
    
//    @StateObject var appWorkViewModel           = AppWorkViewModel()
    @StateObject var usersViewModel             = UsersViewModel()
    @StateObject var classDetailViewModel       = ClassDetailViewModel()
    @StateObject var studentPicStubViewModel    = StudentPicStubViewModel()
    @StateObject var classesViewModel           = ClassesViewModel()
    @StateObject var appxViewModel              = AppxViewModel()
    @StateObject var categoryViewModel          = CategoryViewModel()
    @StateObject var appsViewModel              = AppsViewModel()
    @StateObject var teacherItems               = TeacherItems()
    @StateObject var studentAppProfileManager   = StudentAppProfileManager()
    @StateObject var devicesViewModel           = DevicesViewModel()
    
    // Authentication Manager using @Observable pattern
    @State private var authManager              = AuthenticationManager()
    
    // Role Manager for role-based navigation
    @State private var roleManager              = RoleManager()
    
    // TEMP: Config debug alert - remove when done testing
    @State private var showConfigAlert          = true

    var body: some Scene {
        WindowGroup {
//            MockFromStudentScreenView(path: <#T##Binding<NavigationPath>#>, profilesx: <#T##[StudentAppProfilex]#>)
//            MockToStudentScreenView(studentId: <#Int#>, profileManager: <#StudentAppProfileManager#>, studentAppprofile: <#StudentAppProfilex#>)
//            TestOutView()
// NavigateToStudentAppProfile()

//            if appWorkViewModel.isLoaded && teacherItems.isLoaded {
//            if teacherItems.isLoaded {
            
//            MockBareBones(studentId: 5, locationID: 1)
//            TestMVVMView(studentId: 5, locationID: 1)
//                .environmentObject(studentAppProfileManager)


            DashboardView()
                    .environment(roleManager)
                    .environment(authManager)
                    .environmentObject(usersViewModel)
                    .environmentObject(classDetailViewModel)
                    .environmentObject(studentPicStubViewModel)
                    .environmentObject(classesViewModel)
                    .environmentObject(appxViewModel)
                    .environmentObject(categoryViewModel)
                    .environmentObject(appsViewModel)
                    .environmentObject(teacherItems)
                    .environmentObject(studentAppProfileManager)
                    .environmentObject(devicesViewModel)
                    // TEMP: Config debug alert - remove when done testing
                    .alert("App Configuration", isPresented: $showConfigAlert) {
                        Button("OK") { }
                    } message: {
                        Text("""
                        Version: \(APISchoolInfo.shared.appVersion)
                        Config Source: \(APISchoolInfo.shared.configSource.displayName)
                        
                        Company URL: \(APISchoolInfo.shared.companyUrl)
                        Company ID: \(APISchoolInfo.shared.companyId)
                        """)
                    }


            
            
//            } else {
//                ProgressView()
//                    .onAppear {
//                        Task {
//                            await teacherItems.exSetup() // Call exSetup on the instance
//                        }
//                    }
//            }
 /*
            if appWorkViewModel.isLoaded  {
                TestOutView()
                    .environmentObject(TeacherItems.shared)
                    .onAppear {
                        Task {
                            await TeacherItems.shared.exSetup()
                        }
                    }

            } else {
                ProgressView()
            }
*/
 
 
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
