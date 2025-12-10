//
//  SettingsView.swift
//  appi4Manager
//
//  Settings screen with app info and account management
//

import SwiftUI

struct SettingsView: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        List {
            // MARK: - App Info Section
            Section {
                appInfoRow
            } header: {
                Text("About")
            }
            
            // MARK: - Links Section
            Section {
                privacyPolicyLink
            }
            
            // MARK: - Account Section
            Section {
                if authManager.isAuthenticated {
                    authenticatedAccountView
                } else {
                    signInLink
                }
            } header: {
                Text("Account")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - App Info Row
    
    private var appInfoRow: some View {
        HStack(spacing: 16) {
            // App Icon
            Image("iconImage")
                .resizable()
                .frame(width: 60, height: 60)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            // App Name and Version
            VStack(alignment: .leading, spacing: 4) {
                Text("appi4Manager")
                    .font(.headline)
                
                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Privacy Policy Link
    
    private var privacyPolicyLink: some View {
        Button {
            openPrivacyPolicy()
        } label: {
            HStack {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
    }
    
    // MARK: - Sign In Link
    
    private var signInLink: some View {
        NavigationLink {
            TeacherLoginView()
        } label: {
            HStack {
                Label("Sign In", systemImage: "person.crop.circle")
                Spacer()
                Text("Teacher Login")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Authenticated Account View
    
    private var authenticatedAccountView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User Info
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(authManager.authenticatedUser?.name ?? "Teacher")
                        .font(.headline)
                    
                    Text(authManager.authenticatedUser?.username ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            // Sign Out Button
            Button(role: .destructive) {
                authManager.logout()
            } label: {
                HStack {
                    Spacer()
                    Text("Sign Out")
                        .fontWeight(.medium)
                    Spacer()
                }
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Helper Properties
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Actions
    
    private func openPrivacyPolicy() {
        // Replace with your actual privacy policy URL
        guard let url = URL(string: "https://example.com/privacy") else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AuthenticationManager())
    }
}
