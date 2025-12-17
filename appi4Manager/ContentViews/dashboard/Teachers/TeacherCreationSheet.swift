//
//  TeacherCreationSheet.swift
//  appi4Manager
//
//  Sheet for creating a new teacher user.
//  Creates the user and adds them to the teacher group (acl.teacher = "allow").
//

import SwiftUI

// MARK: - TeacherCreationSheet

/// Sheet for creating a new teacher user.
/// Teacher is created with a username, name, email, and default password.
/// The user is automatically added to the teacher group for the current location.
struct TeacherCreationSheet: View {
    
    // MARK: - Environment & State
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var teacherItems: TeacherItems
    
    let locationId: Int
    let classGroupId: Int
    var onTeacherCreated: ((User) -> Void)?
    
    // Form fields
    @State private var username: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    
    // State
    @State private var isCreating = false
    @State private var hasError = false
    @State private var errorMessage: String?
    
    // Validation
    private var isFormValid: Bool {
        !username.isEmpty && !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        Form {
            // Account Details Section
            Section {
                TextField("Username (Login ID)", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                PasswordInfoRow()
            } header: {
                Text("Account Details")
            } footer: {
                Text("The teacher will use this username and the default password to sign in.")
            }
            
            // Personal Info Section
            Section {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                
                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            } header: {
                Text("Personal Information")
            }
            
            // Info Section
            Section {
                InfoRow(
                    icon: "person.3.fill",
                    title: "Teacher Group",
                    value: "Auto-assigned"
                )
                
                InfoRow(
                    icon: "building.2",
                    title: "Location",
                    value: teacherItems.currentLocation.name
                )
            } header: {
                Text("Assignment")
            } footer: {
                Text("The new teacher will be added to the teacher group, enabling Jamf School Teacher permissions.")
            }
        }
        .navigationTitle("Create Teacher")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .disabled(isCreating)
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        await createTeacher()
                    }
                }
                .fontWeight(.semibold)
                .disabled(!isFormValid || isCreating)
            }
        }
        .overlay {
            if isCreating {
                creatingOverlay
            }
        }
        .alert("Error", isPresented: $hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Failed to create teacher.")
        }
    }
    
    // MARK: - Subviews
    
    private var creatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Creating teacher...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Actions
    
    private func createTeacher() async {
        await MainActor.run { isCreating = true }
        defer { Task { await MainActor.run { isCreating = false } } }
        
        do {
            // Get the teacher group ID for this location
            guard let teacherGroupId = teacherItems.teacherGroupDict[locationId] else {
                await MainActor.run {
                    hasError = true
                    errorMessage = "No teacher group found for this location. Please contact an administrator."
                }
                return
            }
            
            // Create the user with both class group and teacher group
            var newUser = User.makeDefault()
            newUser.username = username
            newUser.firstName = firstName
            newUser.lastName = lastName
            newUser.email = email
            newUser.locationId = locationId
            newUser.groupIds = [classGroupId, teacherGroupId]  // Add to both class group and teacher group
            
            let response: AddAUserResponse = try await ApiManager.shared.getData(
                from: .addUsr(user: newUser)
            )
            
            // Update the user with the returned ID
            newUser.id = response.id
            
            #if DEBUG
            print("✅ Created teacher: \(firstName) \(lastName) with ID: \(response.id)")
            print("   Added to class group: \(classGroupId) and teacher group: \(teacherGroupId)")
            #endif
            
            // Callback
            onTeacherCreated?(newUser)
            
            await MainActor.run { dismiss() }
            
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = error.localizedDescription
            }
            #if DEBUG
            print("❌ Failed to create teacher: \(error)")
            #endif
        }
    }
}

// MARK: - Helper Views

private struct PasswordInfoRow: View {
    var body: some View {
        HStack {
            Text("Password")
            Spacer()
            Text(AppConstants.defaultTeacherPwd)
                .foregroundColor(.secondary)
                .font(.system(.body, design: .monospaced))
            
            Image(systemName: "lock.fill")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TeacherCreationSheet(
            locationId: 1,
            classGroupId: 100
        )
        .environmentObject(TeacherItems())
    }
}
