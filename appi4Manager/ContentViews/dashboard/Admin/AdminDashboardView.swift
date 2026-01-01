//
//  AdminDashboardView.swift
//  appi4Manager
//
//  Admin dashboard for full management access.
//  Shows category tiles (Devices, Classes, Students, Apps, Categories) that navigate
//  to their respective management views.
//

import SwiftUI

// MARK: - AdminDashboardView

/// Dashboard for admin users with full access to all management features.
///
/// **Category Tiles:**
/// - Devices: View and manage all MDM-enrolled devices
/// - Categories: Manage app categories
/// - Apps: View available apps and configure profiles
/// - Classes: Manage school classes
/// - Students: View and manage student users
///
/// **Toolbar:**
/// - Settings: Opens the settings view
struct AdminDashboardView: View {
    // MARK: - Environment & State
    
    @EnvironmentObject var devicesViewModel: DevicesViewModel
    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var teacherItems: TeacherItems
    
    /// True if an API error occurred
    @State private var hasError = false
    
    /// The API error for alert presentation
    @State private var error: ApiError?
    
    /// Navigation path for programmatic navigation
    @State var path: NavigationPath = NavigationPath()
    
    // MARK: - Categories
    
    /// The main category tiles displayed on the dashboard.
    /// Each category navigates to its respective management view.
    let categories = [
        Category(name: "Devices", color: .blue, image: Image(systemName: "ipad.and.iphone"), count: 5),
        Category(name: "Device Management", color: .teal, image: Image(systemName: "ipad.landscape"), count: 0),
        Category(name: "Categories", color: .green, image: Image(systemName: "folder.fill"), count: 12),
        Category(name: "Apps", color: .red, image: Image(systemName: "apps.ipad"), count: 3),
        Category(name: "Classes", color: .orange, image: Image(systemName: "person.3.sequence.fill"), count: 2),
        Category(name: "Class Management", color: .purple, image: Image(systemName: "rectangle.stack.person.crop.fill"), count: 0),
        Category(name: "Students", color: .yellow, image: Image(systemName: "person.crop.square"), count: 6)
    ]
    
    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 250), spacing: 20)], spacing: 20) {
                        ForEach(categories) { category in
                            NavigationLink(value: category, label: {
                                CategoryView(category: category)
                            })
                            .isDetailLink(false)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                    .navigationViewStyle(StackNavigationViewStyle())
                }
                .navigationDestination(for: Category.self) { category in
                    switch category.name {
                    case "Devices":
                        DeviceListVW(isPresented: .constant(true))
                    case "Categories":
                        CategoryListView(newAppCategory: AppCategory.makeDefault())
                    case "Students":
                        if classesViewModel.isLoaded && usersViewModel.isLoaded {
                            let firstClassGroupId =
                            classesViewModel.filterSchoolClassesinLocation2(
                                teacherItems.currentLocation.id,
                                dummyPicClassToIgnore: teacherItems.getpicClass(),
                                schoolClassGroupID: teacherItems.schoolClassDictionaryGroupID[teacherItems.currentLocation.id]!).first?.userGroupId ?? 0
                            
                            UserListDup(path: $path,
                                        newUser: User.makeDefault(),
                                        filteredClasses: classesViewModel.filterSchoolClassesinLocation2(
                                            teacherItems.currentLocation.id,
                                            dummyPicClassToIgnore: teacherItems.getpicClass(),
                                            schoolClassGroupID: teacherItems.schoolClassDictionaryGroupID[teacherItems.currentLocation.id]!),
                                        filteredStudents: usersViewModel.sortedUsersNonBClass(
                                            lastNameFilter: "",
                                            selectedLocationID: teacherItems.selectedLocationIdx,
                                            teacherUserID: teacherItems.teacherUserDict[teacherItems.selectedLocationIdx]!,
                                            scGroupid: firstClassGroupId)
                            )
                            .alert(isPresented: $hasError, error: error) {
                                Button {
                                    Task {
                                        await loadTheClasses()
                                    }
                                } label: {
                                    Text("Retry")
                                }
                            }
                        }
                    case "Classes":
                        SchoolListDup(newClass: SchoolClass.makeDefault())
                            .task {
                                await loadTheUsers()
                                await loadTheDevices()
                            }
                    case "Apps":
                        MockFromStudentScreenView(path: $path)
                    case "Class Management":
                        ClassManagementListView()
                    case "Device Management":
                        DeviceManagementListView()
                    default:
                        Text("Nothing setup yet")
                    }
                }
                .navigationDestination(for: String.self) { value in
                    switch value {
                    case "Settings":
                        SettingsView()
                    default:
                        TestDestFromClassView(mssg: value)
                    }
                }
                .background(Color(.systemGray5))
                .edgesIgnoringSafeArea(.bottom)
                .navigationTitle("Admin Dashboard")
                .navigationViewStyle(StackNavigationViewStyle())
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(value: "Settings") {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            
            // Loading overlay
            if !teacherItems.isLoaded {
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.7))
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            Task {
                await teacherItems.exSetup()
                await loadTheClasses()
                await loadTheUsers()
            }
        }
    }
}

// MARK: - Data Loading

/// Extension containing async functions to load data from the API.
private extension AdminDashboardView {
    /// Loads all school classes from the API
    func loadTheClasses() async {
        do {
            try await classesViewModel.loadData2()
        } catch {
            if let xerror = error as? ApiError {
                self.hasError = true
                self.error = xerror
            }
        }
    }
    
    /// Loads all users/students from the API
    func loadTheUsers() async {
        do {
            try await usersViewModel.loadData2()
        } catch {
            if let xerror = error as? ApiError {
                self.hasError = true
                self.error = xerror
            }
        }
    }
    
    /// Loads all devices from the API
    func loadTheDevices() async {
        do {
            try await devicesViewModel.loadData2()
        } catch {
            if let xerror = error as? ApiError {
                self.hasError = true
                self.error = xerror
            }
        }
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(DevicesViewModel())
        .environmentObject(ClassesViewModel())
        .environmentObject(UsersViewModel())
        .environmentObject(TeacherItems())
}
