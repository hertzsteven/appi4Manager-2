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
    @Environment(RoleManager.self) private var roleManager
    
    var body: some View {
        Group {
            if let role = roleManager.currentRole {
                switch role {
                case .admin:
                    AdminDashboardView()
                case .teacher:
                    TeacherDashboardView()
                }
            } else {
                // No role selected - show role selection
                RoleSelectionView()
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
                }
                .padding([.leading],4)
                
                Spacer()
                
                VStack {
                    Text("\(category.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .padding([.top], 4)
                        .padding([.trailing], 18)
                        .hidden() // remove to show the number
                    Spacer()
                }
            }
            .padding(.leading, 10)
            )
        }
    }
}


#Preview {
    DashboardView()
        .environment(RoleManager())
        .environment(AuthenticationManager())
        .environmentObject(DevicesViewModel())
        .environmentObject(ClassesViewModel())
        .environmentObject(UsersViewModel())
        .environmentObject(TeacherItems())
}
