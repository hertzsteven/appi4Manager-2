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
    let subtitle: String?
    
    init(name: String, color: Color, image: Image, count: Int, subtitle: String? = nil) {
        self.name = name
        self.color = color
        self.image = image
        self.count = count
        self.subtitle = subtitle
    }
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
                    TeacherSidebarContainerView()
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
                .overlay(

            HStack(spacing: 16) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(category.color.gradient)
                        .frame(width: 50, height: 50)
                    
                    category.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.white)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let subtitle = category.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
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
