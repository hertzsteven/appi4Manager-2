//
//  AdminDashboardView.swift
//  appi4Manager
//
//  Dashboard for admin users - shows all management categories
//

import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var devicesViewModel: DevicesViewModel
    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var teacherItems: TeacherItems
    
    @State private var hasError = false
    @State private var error: ApiError?
    @State var path: NavigationPath = NavigationPath()
    
    let categories = [
        Category(name: "Devices", color: .blue, image: Image(systemName: "ipad.and.iphone"), count: 5),
        Category(name: "Categories", color: .green, image: Image(systemName: "folder.fill"), count: 12),
        Category(name: "Apps", color: .red, image: Image(systemName: "apps.ipad"), count: 3),
        Category(name: "Classes", color: .orange, image: Image(systemName: "person.3.sequence.fill"), count: 2),
        Category(name: "Students", color: .yellow, image: Image(systemName: "person.crop.square"), count: 6)
    ]
    
    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 20) {
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

private extension AdminDashboardView {
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
