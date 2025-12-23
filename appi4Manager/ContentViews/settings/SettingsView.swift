//
//  SettingsView.swift
//  appi4Manager
//
//  Settings screen with app info and account management
//

import SwiftUI

struct SettingsView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(RoleManager.self) private var roleManager
    @EnvironmentObject var teacherItems: TeacherItems
    
    // Migration state
    @State private var isMigrating = false
    @State private var migrationResult: String?
    @State private var showMigrationAlert = false
    
    var body: some View {
        List {
            // MARK: - Current Role Section
            Section {
                currentRoleRow
                switchRoleButton
            } header: {
                Text("App Mode")
            } footer: {
                Text("Switch between Administrator and Teacher mode.")
            }
            
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
            
            // MARK: - Teacher Class Info Section (only visible when authenticated)
            if authManager.isAuthenticated {
                Section {
                    teacherClassInfoLink
                } header: {
                    Text("Teacher Data")
                } footer: {
                    Text("View class UUID and group ID information for API integration.")
                }
            }
            // MARK: - Data Maintenance Section (only visible when authenticated)
            if authManager.isAuthenticated {
                Section {
                    migrateProfilesButton
                } header: {
                    Text("Data Maintenance")
                } footer: {
                    Text("One-time migration to update student profile document IDs to include school ID.")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Migration Result", isPresented: $showMigrationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(migrationResult ?? "")
        }
    }
    
    // MARK: - Current Role Row
    
    private var currentRoleRow: some View {
        HStack {
            Label {
                Text("Current Mode")
            } icon: {
                Image(systemName: roleManager.currentRole?.iconName ?? "questionmark.circle")
                    .foregroundColor(roleManager.isAdmin ? .blue : .green)
            }
            
            Spacer()
            
            Text(roleManager.currentRole?.displayName ?? "Not Selected")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Switch Role Button
    
    private var switchRoleButton: some View {
        Button {
            roleManager.clearRole()
        } label: {
            HStack {
                Label("Switch Mode", systemImage: "arrow.triangle.2.circlepath")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
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
    
    // MARK: - Teacher Class Info Link
    
    private var teacherClassInfoLink: some View {
        NavigationLink {
            TeacherClassInfoView()
        } label: {
            HStack {
                Label("Class & Group Info", systemImage: "info.circle.fill")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Migrate Profiles Button
    
    private var migrateProfilesButton: some View {
        Button {
            Task {
                await runMigration()
            }
        } label: {
            HStack {
                if isMigrating {
                    ProgressView()
                        .padding(.trailing, 8)
                    Text("Migrating...")
                } else {
                    Label("Migrate Profile IDs", systemImage: "arrow.triangle.2.circlepath.doc.on.clipboard")
                }
                Spacer()
            }
        }
        .disabled(isMigrating)
        .foregroundColor(isMigrating ? .secondary : .primary)
    }
    
    private func runMigration() async {
        isMigrating = true
        
        do {
            let companyId = APISchoolInfo.shared.companyId
            let count = try await FirestoreManager().migrateStudentProfilesToCompositeIds(companyId: companyId)
            migrationResult = "Successfully migrated \(count) student profile(s) to new format."
        } catch {
            migrationResult = "Migration failed: \(error.localizedDescription)"
        }
        
        isMigrating = false
        showMigrationAlert = true
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
            .environment(RoleManager())
            .environment(AuthenticationManager())
            .environmentObject(TeacherItems())
    }
}
