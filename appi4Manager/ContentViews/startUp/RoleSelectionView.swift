//
//  RoleSelectionView.swift
//  appi4Manager
//
//  View for selecting user role (Admin or Teacher)
//

import SwiftUI

struct RoleSelectionView: View {
    @Environment(RoleManager.self) private var roleManager
    
    /// Whether this view is being presented from Settings (vs. onboarding)
    var isFromSettings: Bool = false
    
    /// Called when user taps cancel (only available when isFromSettings is true)
    var onCancel: (() -> Void)?
    
    /// Called after a role is selected (allows custom handling like dismissing a sheet)
    var onRoleSelected: ((UserRole) -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image("iconImage")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(.rect(cornerRadius: 16))
                        .shadow(radius: 4)
                    
                    Text(isFromSettings ? "Switch Mode" : "Welcome to appi4Manager")
                        .font(.title)
                        .bold()
                    
                    Text("How will you be using this app?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, isFromSettings ? 20 : 40)
                
                // Role Cards
                VStack(spacing: 20) {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        RoleCard(role: role) {
                            roleManager.selectRole(role)
                            onRoleSelected?(role)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Footer
                if !isFromSettings {
                    Text("You can change this later in Settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                if isFromSettings {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            onCancel?()
                        }
                    }
                }
            }
        }
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
                        .foregroundStyle(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(role.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Onboarding") {
    RoleSelectionView()
        .environment(RoleManager())
}

#Preview("From Settings") {
    RoleSelectionView(
        isFromSettings: true,
        onCancel: { print("Cancelled") },
        onRoleSelected: { role in print("Selected: \(role)") }
    )
    .environment(RoleManager())
}
