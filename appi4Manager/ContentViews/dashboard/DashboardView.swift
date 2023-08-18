//
//  ContentView.swift
//  Think about lazy grid and lazy stack
//
//  Created by Steven Hertz on 3/24/23.
//

import SwiftUI


struct DashboardView: View {

    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var usersViewModel:  UsersViewModel
    @State private var hasError = false
    @State private var error: ApiError?

    @State var path: NavigationPath = NavigationPath()
    
    let categories = [
        Category(name: "Devices", color: .blue, image: Image(systemName: "ipad.and.iphone"), count: 5),
        Category(name: "Categories", color: .green, image: Image(systemName: "person.fill"), count: 12),
        Category(name: "Apps", color: .red, image: Image(systemName: "apps.ipad"), count: 3),
        Category(name: "NavigateToStudentAppProfile", color: .purple, image: Image(systemName: "person.3.sequence.fill"), count: 8),
        Category(name: "SchoolListDup", color: .orange, image: Image(systemName: "airplane"), count: 2),
        Category(name: "UserDup", color: .yellow, image: Image(systemName: "dollarsign.circle.fill"), count: 6)
    ]
    
//    @StateObject var model          = CategoryViewModel()
//    @StateObject var appsViewModel  = AppsViewModel()


    var body: some View {
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
            .navigationDestination(for: Category.self, destination: { category in
                switch category.name {
                case "Devices":
                    ParentAppPickerView()
                case "Categories":
                    CategoryListView( newAppCategory: AppCategory.makeDefault())
//                        .environmentObject(model)
//                        .environmentObject(appsViewModel)
                

//                    UserListContent(newUser: User.makeDefault())
//                        .task {
//                            await loadTheClasses()
//                        }
//                        .alert(isPresented: $hasError,
//                               error: error) {
//                            Button {
//                                Task {
//                                    await loadTheClasses()
//                                }
//                            } label: {
//                                Text("Retry")
//                            }
//                        }
//
                case "UserDup":
                    UserListDup(newUser: User.makeDefault())
                        .task {
                            await loadTheClasses()
                        }
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
                    
               case "SchoolListDup":
                    
                    SchoolListDup( newClass: SchoolClass.makeDefault())
                        .task {
                            await loadTheUsers()
                       }

                case "Apps":
                    AppxView()
   
                case "NavigateToStudentAppProfile":
                    DummyStudentProfileLauncherView()
   
                default:
                    SchoolListContent(path: $path, newClass: SchoolClass.makeDefault())
                }
            })
            .background(Color(.systemGray5))
            .edgesIgnoringSafeArea(.bottom)
            .navigationTitle("Dashboard")
            .navigationViewStyle(StackNavigationViewStyle())
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
                        .font(.body)
                        .bold()
                        .foregroundColor(.secondary)
                }
                .padding([.leading],4)
                
                Spacer()
                
                VStack {
                    Text("\(category.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .padding([.top], 4)
                        .padding([.trailing], 18)
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

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
