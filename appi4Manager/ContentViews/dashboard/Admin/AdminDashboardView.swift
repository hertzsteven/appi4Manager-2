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
        Category(
            name: "Device Management",
            color: .teal,
            image: Image(systemName: "ipad.landscape"),
            count: 0,
            subtitle: "Manage iPads and device assignments"
        ),
        Category(
            name: "Class Management",
            color: .purple,
            image: Image(systemName: "rectangle.stack.person.crop.fill"),
            count: 0,
            subtitle: "Configure classes, teachers, and devices"
        ),
        Category(
            name: "Student Management",
            color: .orange,
            image: Image(systemName: "person.2.fill"),
            count: 0,
            subtitle: "Manage student accounts and enrollments"
        )
    ]
    
    // MARK: - Hidden Category (Available for Restoration)
    // The Categories feature is still available in the codebase but hidden from the dashboard.
    // To restore, add for example:
    // Category(name: "Categories", color: .green, image: Image(systemName: "folder.fill"), count: 12, subtitle: "Manage app categories")
    
    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(categories) { category in
                            NavigationLink(value: category, label: {
                                CategoryView(category: category)
                            })
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .navigationDestination(for: Category.self) { category in
                    switch category.name {
                    case "Categories":
                        CategoryListView(newAppCategory: AppCategory.makeDefault())
                    case "Class Management":
                        ClassManagementListView()
                    case "Device Management":
                        DeviceManagementListView()
                    case "Student Management":
                        // Placeholder for future Student Management view
                        VStack(spacing: 20) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.orange)
                            Text("Coming Soon")
                                .font(.title)
                                .bold()
                            Text("Student Management features are under development.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .navigationTitle("Student Management")
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
                .navigationTitle("Administrative Management Dashboard")
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
