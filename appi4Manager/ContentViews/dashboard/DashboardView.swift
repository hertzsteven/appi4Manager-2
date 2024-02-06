//
//  ContentView.swift
//  Think about lazy grid and lazy stack
//
//  Created by Steven Hertz on 3/24/23.
//

import SwiftUI

struct Category: Identifiable, Hashable {
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id = UUID().uuidString
    let name: String
    let color: Color
    let image: Image
    let count: Int
}


struct DashboardView: View {
    @State private var isLoading = true // Example loading state

    @EnvironmentObject var devicesViewModel: DevicesViewModel
    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var usersViewModel:  UsersViewModel
    @EnvironmentObject var teacherItems: TeacherItems

    @State private var hasError = false
    @State private var error: ApiError?

    @State var path: NavigationPath = NavigationPath()
    
    let categories = [
        Category(name: "Devices", color: .blue, image: Image(systemName: "ipad.and.iphone"), count: 5),
        Category(name: "Categories", color: .green, image: Image(systemName: "folder.fill"), count: 12),
//        Category(name: "Apps", color: .red, image: Image(systemName: "apps.ipad"), count: 3),
//        Category(name: "NavigateToStudentAppProfile", color: .purple, image: Image(systemName: "person.3.sequence.fill"), count: 8),
        Category(name: "Classes", color: .orange, image: Image(systemName: "person.3.sequence.fill"), count: 2),
        Category(name: "Students", color: .yellow, image: Image(systemName: "person.crop.square"), count: 6)
    ]
    
    var body: some View {
        ZStack {
            NavigationStack(path:$path ) {
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
//                        TestSchoolListView()
                            //                    TestDestFromClassView(mssg: 2323)
                                                DeviceListVW(isPresented: .constant(true))
                            //                    TestOutView()
                    case "Categories":
                        CategoryListView( newAppCategory: AppCategory.makeDefault())
                        
                    case "Students":
                        if classesViewModel.isLoaded && usersViewModel.isLoaded {
                            let firstClassGroupId =
                            classesViewModel.filterSchoolClassesinLocation2(
                                teacherItems.currentLocation.id,
                                dummyPicClassToIgnore: teacherItems.getpicClass() ,
                                schoolClassGroupID: teacherItems.schoolClassDictionaryGroupID[teacherItems.currentLocation.id]!).first?.userGroupId ?? 0
                            
                            UserListDup(path: $path,
                                        newUser: User.makeDefault(),
                                        filteredClasses: classesViewModel.filterSchoolClassesinLocation2(
                                            teacherItems.currentLocation.id,
                                            dummyPicClassToIgnore: teacherItems.getpicClass() ,
                                            schoolClassGroupID: teacherItems.schoolClassDictionaryGroupID[teacherItems.currentLocation.id]! ),
                                        filteredStudents:  usersViewModel.sortedUsersNonBClass(
                                            lastNameFilter: "",
                                            selectedLocationID: teacherItems.selectedLocationIdx,
                                            teacherUserID: teacherItems.teacherUserDict[teacherItems.selectedLocationIdx]!,
                                            scGroupid: firstClassGroupId)
                            )
                            .alert(isPresented: $hasError,
                                   error: error) {
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
                        SchoolListDup( newClass: SchoolClass.makeDefault())
                            .task {
                                await loadTheUsers()
                                await loadTheDevices()
                            }
                        
                    case "Apps":
                        AppxView()
                            //                    MockFromStudentScreenView(path: $path)
                        
                    case "NavigateTo":
                        MockFromStudentScreenView(path: $path)

                        
                    default:
                        Text("Nothing setup yet")
                    }
                }
                
                .navigationDestination(for: String.self) { theNbr in
                    TestDestFromClassView(mssg: theNbr)
                }
                
                
                .background(Color(.systemGray5))
                .edgesIgnoringSafeArea(.bottom)
                .navigationTitle("Dashboard")
                .navigationViewStyle(StackNavigationViewStyle())
            }
                // Translucent Progress View
            if !teacherItems.isLoaded {
                    //                 if isLoading {
                ProgressView()
                    .scaleEffect(2) // Increase the size of the progress view
                    .progressViewStyle(CircularProgressViewStyle(tint: .white)) // Custom style
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.7)) // Translucent background
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            Task {
                await teacherItems.exSetup() // Call exSetup on the instance
                await loadTheClasses()
                await loadTheUsers()
            }
        }
    }
}


private extension DashboardView {
    
    func loadTheClasses() async {
        do {
            try await classesViewModel.loadData2()
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }
    
    func loadTheUsers() async {
        do {
            try await usersViewModel.loadData2()
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }
    
    func loadTheDevices() async {
        do {
            try await devicesViewModel.loadData2()
            dump(devicesViewModel)
            print("pause")
        } catch  {
            if let xerror = error as? ApiError {
                self.hasError   = true
                self.error      = xerror
            }
        }
    }
}


struct CategoryView: View {
    let category: Category

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .frame(width: 150, height: 80)
                .shadow(radius: 5)
                .overlay(

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(category.color)
                            .frame(width: 30, height: 30)
                        
                        category.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                            .foregroundColor(.white)
                    }
                    .padding([.bottom],8)

                    Text(category.name)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.secondary)
//
//                        .font(.body)
//                        .bold()
//                        .foregroundColor(.secondary)
                }
                .padding([.leading],4)
                
                Spacer()
                
                VStack {
                    Text("\(category.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .padding([.top], 4)
                        .padding([.trailing], 18)
                        .hidden() // rmmove to show the number
                    Spacer()
                }
            }
            .padding(.leading, 10)
            )
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}

