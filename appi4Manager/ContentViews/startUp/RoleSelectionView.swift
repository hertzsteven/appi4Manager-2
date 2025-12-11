//
//  RoleSelectionView.swift
//  appi4Manager
//
//  View for selecting user role (Admin or Teacher)
//

import SwiftUI

struct RoleSelectionView: View {
    @Environment(RoleManager.self) private var roleManager
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image("iconImage")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(16)
                    .shadow(radius: 4)
                
                Text("Welcome to appi4Manager")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("How will you be using this app?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Role Cards
            VStack(spacing: 20) {
                ForEach(UserRole.allCases, id: \.self) { role in
                    RoleCard(role: role) {
                        roleManager.selectRole(role)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Footer
            Text("You can change this later in Settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Role Card

struct RoleCard: View {
    let role: UserRole
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(role == .admin ? Color.blue : Color.green)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: role.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(role.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoleSelectionView()
        .environment(RoleManager())
}
