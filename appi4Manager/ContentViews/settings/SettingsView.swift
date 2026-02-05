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
    
    // Role switching sheet
    @State private var showRoleSwitcher = false
    
    var body: some View {
        List {
            // MARK: - Account Section (Actions first)
            Section {
                if authManager.isAuthenticated {
                    authenticatedAccountView
                    teacherClassInfoLink
                } else {
                    signInLink
                }
            } header: {
                Text("Account")
            } footer: {
                if authManager.isAuthenticated {
                    Text("View your assigned classes, students, and devices.")
                }
            }
            
            // MARK: - App Mode Section
            Section {
                currentRoleRow
                switchRoleButton
            } header: {
                Text("App Mode")
            } footer: {
                Text("Switch between Administrator and Teacher mode.")
            }
            
            // MARK: - Preferences Section (Timeslot Hours)
            Section {
                TimeslotRangeRow(
                    title: "Morning (AM)",
                    startHour: Binding(
                        get: { TimeslotSettings.amStart },
                        set: { TimeslotSettings.setAMRange(start: $0, end: TimeslotSettings.amEnd) }
                    ),
                    endHour: Binding(
                        get: { TimeslotSettings.amEnd },
                        set: { TimeslotSettings.setAMRange(start: TimeslotSettings.amStart, end: $0) }
                    )
                )
                TimeslotRangeRow(
                    title: "Afternoon (PM)",
                    startHour: Binding(
                        get: { TimeslotSettings.pmStart },
                        set: { TimeslotSettings.setPMRange(start: $0, end: TimeslotSettings.pmEnd) }
                    ),
                    endHour: Binding(
                        get: { TimeslotSettings.pmEnd },
                        set: { TimeslotSettings.setPMRange(start: TimeslotSettings.pmStart, end: $0) }
                    )
                )
                TimeslotRangeRow(
                    title: "Home/Evening",
                    startHour: Binding(
                        get: { TimeslotSettings.homeStart },
                        set: { TimeslotSettings.setHomeRange(start: $0, end: TimeslotSettings.homeEnd) }
                    ),
                    endHour: Binding(
                        get: { TimeslotSettings.homeEnd },
                        set: { TimeslotSettings.setHomeRange(start: TimeslotSettings.homeStart, end: $0) }
                    )
                )
                Button("Reset to Defaults") {
                    TimeslotSettings.resetToDefaults()
                }
                .foregroundStyle(.red)
            } header: {
                Text("Preferences")
            } footer: {
                Text("Configure when each session starts and ends. Hours outside these ranges will block student login.")
            }
            
            // MARK: - About Section (Informational - at the bottom)
            Section {
                appInfoRow
                privacyPolicyLink
            } header: {
                Text("About")
            }
            
            // MARK: - Data Maintenance Section (disabled)
            // NOTE: This section has been disabled per request to remove the migration UI.
            // To restore, uncomment the block below.
            // if authManager.isAuthenticated {
            //     Section {
            //         migrateProfilesButton
            //     } header: {
            //         Text("Data Maintenance")
            //     } footer: {
            //         Text("One-time migration to update student profile document IDs to include school ID.")
            //     }
            // }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Migration Result", isPresented: $showMigrationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(migrationResult ?? "")
        }
        .sheet(isPresented: $showRoleSwitcher) {
            RoleSelectionView(
                isFromSettings: true,
                onCancel: {
                    showRoleSwitcher = false
                },
                onRoleSelected: { _ in
                    showRoleSwitcher = false
                }
            )
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
            showRoleSwitcher = true
        } label: {
            HStack {
                Label("Switch Mode", systemImage: "arrow.triangle.2.circlepath")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
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
            }
        }
    }
    
    // MARK: - Migrate Profiles Button (disabled)
    // The migration button has been disabled/hidden. To restore, uncomment this block.
    // private var migrateProfilesButton: some View {
    //     Button {
    //         Task {
    //             await runMigration()
    //         }
    //     } label: {
    //         HStack {
    //             if isMigrating {
    //                 ProgressView()
    //                     .padding(.trailing, 8)
    //                 Text("Migrating...")
    //             } else {
    //                 Label("Migrate Profile IDs", systemImage: "arrow.triangle.2.circlepath.doc.on.clipboard")
    //             }
    //             Spacer()
    //         }
    //     }
    //     .disabled(isMigrating)
    //     .foregroundColor(isMigrating ? .secondary : .primary)
    // }
    
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
    
    // MARK: - Migration Logic (disabled)
    // The migration logic has been disabled. To restore, uncomment this function and its callers.
    // private func runMigration() async {
    //     isMigrating = true
    //
    //     do {
    //         let companyId = APISchoolInfo.shared.companyId
    //         let count = try await FirestoreManager().migrateStudentProfilesToCompositeIds(companyId: companyId)
    //         migrationResult = "Successfully migrated \(count) student profile(s) to new format."
    //     } catch {
    //         migrationResult = "Migration failed: \(error.localizedDescription)"
    //     }
    //
    //     isMigrating = false
    //     showMigrationAlert = true
    // }
}

// MARK: - Timeslot Range Row Component

/// A row component for configuring a timeslot's start and end hours
struct TimeslotRangeRow: View {
    let title: String
    @Binding var startHour: Int
    @Binding var endHour: Int
    
    private let hours = Array(0...24)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                // Start Hour Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Start", selection: $startHour) {
                        ForEach(hours, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // End Hour Picker
                VStack(alignment: .trailing, spacing: 4) {
                    Text("End")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("End", selection: $endHour) {
                        ForEach(hours, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "12:00 AM"
        } else if hour == 12 {
            return "12:00 PM"
        } else if hour == 24 {
            return "Midnight"
        } else if hour < 12 {
            return "\(hour):00 AM"
        } else {
            return "\(hour - 12):00 PM"
        }
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

