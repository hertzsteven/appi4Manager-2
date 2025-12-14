//
//  TeacherStudentEditorView.swift
//  appi4Manager
//
//  A simplified student editor for teachers to create, edit, or delete students.
//

import SwiftUI
import PhotosUI

// MARK: - Teacher Student Editor View

/// A simplified student editor for teachers to create, edit, or delete students.
/// - Create new students: Pass `student: nil`
/// - Edit existing students: Pass the student to edit
struct TeacherStudentEditorView: View {
    
    // MARK: - Properties
    
    /// The student to edit (nil if creating new student)
    let student: Student?
    
    /// The class information (used for adding new students to the class)
    let classInfo: TeacherClassInfo
    
    /// Callback when save/delete completes to refresh parent view
    let onComplete: () -> Void
    
    /// Whether this is a new student (create mode)
    var isNew: Bool { student == nil }
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthenticationManager.self) private var authManager
    @EnvironmentObject var teacherItems: TeacherItems
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var studentAppProfileManager: StudentAppProfileManager
    
    // MARK: - Photo State
    
    @StateObject private var imagePicker = ImagePicker()
    
    // MARK: - Form State
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var notes: String = ""
    
    // MARK: - UI State
    
    @State private var isSaving = false
    @State private var isLoadingUser = false
    @State private var showDeleteConfirmation = false
    @State private var showDiscardConfirmation = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var originalNotes: String = ""  // Track original notes for edit mode
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Photo Section
                studentPhotoSection
                
                // Name Section
                studentNameSection
                
                // Notes Section
                studentNotesSection
                
                // Delete Section (only for existing students)
                if !isNew {
                    studentDeleteSection
                }
            }
            .navigationTitle(isNew ? "Add Student" : "Edit Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges {
                            showDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Add" : "Save") {
                        Task {
                            await saveStudent()
                        }
                    }
                    .disabled(!canSave || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .overlay {
                if isSaving {
                    editorSavingOverlay
                }
            }
            .confirmationDialog(
                "Discard Changes?",
                isPresented: $showDiscardConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
            }
            .confirmationDialog(
                "Delete Student?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Student", role: .destructive) {
                    Task {
                        await deleteStudentAction()
                    }
                }
            } message: {
                Text("This action cannot be undone. The student will be removed from the system.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            .onAppear {
                setupInitialValues()
            }
            .task {
                // Load full user data (including notes) when editing
                if !isNew {
                    await loadUserData()
                }
            }
        }
    }
    
    // MARK: - Photo Section
    
    private var studentPhotoSection: some View {
        Section(header: Text("Photo")) {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Photo display
                    if let image = imagePicker.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 2)
                            )
                    } else if let student = student {
                        AsyncImage(url: student.photo) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.accentColor, lineWidth: 2)
                                    )
                            default:
                                editorDefaultPhotoView
                            }
                        }
                    } else {
                        editorDefaultPhotoView
                    }
                    
                    // Photo picker button
                    PhotosPicker(
                        selection: $imagePicker.imageSelection,
                        matching: .images
                    ) {
                        Text("Select Photo")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    private var editorDefaultPhotoView: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: 100, height: 100)
            .foregroundColor(.gray)
    }
    
    // MARK: - Name Section
    
    private var studentNameSection: some View {
        Section(header: Text("Name")) {
            TextField("First Name", text: $firstName)
                .textContentType(.givenName)
            
            TextField("Last Name", text: $lastName)
                .textContentType(.familyName)
        }
    }
    
    // MARK: - Notes Section
    
    private var studentNotesSection: some View {
        Section(header: Text("Notes")) {
            TextEditor(text: $notes)
                .frame(minHeight: 80)
        }
    }
    
    // MARK: - Delete Section
    
    private var studentDeleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Delete Student")
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Saving Overlay
    
    private var editorSavingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text(isNew ? "Adding Student..." : "Saving...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var hasChanges: Bool {
        if isNew {
            return !firstName.isEmpty || !lastName.isEmpty || !notes.isEmpty || imagePicker.image != nil
        } else {
            guard let student = student else { return false }
            let originalFirstName = student.firstName
            let originalLastName = student.lastName
            return firstName != originalFirstName ||
                   lastName != originalLastName ||
                   imagePicker.image != nil
        }
    }
    
    // MARK: - Setup
    
    private func setupInitialValues() {
        if let student = student {
            firstName = student.firstName
            lastName = student.lastName
            // notes will be loaded async in loadUserData()
        }
    }
    
    /// Fetch full User data to get notes (Student model doesn't have notes)
    private func loadUserData() async {
        guard let student = student else { return }
        
        await MainActor.run {
            isLoadingUser = true
        }
        
        do {
            let userResponse: UserDetailResponse = try await ApiManager.shared.getData(
                from: .getaUser(id: student.id)
            )
            
            await MainActor.run {
                notes = userResponse.user.notes
                originalNotes = userResponse.user.notes
                isLoadingUser = false
            }
        } catch {
            await MainActor.run {
                isLoadingUser = false
                #if DEBUG
                print("⚠️ Failed to load user notes: \(error)")
                #endif
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveStudent() async {
        await MainActor.run {
            isSaving = true
        }
        
        do {
            if isNew {
                try await createStudent()
            } else {
                try await updateStudent()
            }
            
            await MainActor.run {
                isSaving = false
                onComplete()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func createStudent() async throws {
        // Generate unique username
        let username = String(Array(UUID().uuidString.split(separator: "-")).last!)
        
        // Get location and group IDs from teacher context
        let locationId = teacherItems.currentLocation.id
        let groupId = classInfo.userGroupID
        
        // Create user object
        var newUser = User.makeDefault()
        newUser.username = username
        newUser.firstName = firstName.trimmingCharacters(in: .whitespaces)
        newUser.lastName = lastName.trimmingCharacters(in: .whitespaces)
        newUser.notes = notes
        newUser.locationId = locationId
        newUser.groupIds = [groupId]
        
        // Add to MDM system
        let response: AddAUserResponse = try await ApiManager.shared.getData(
            from: .addUsr(user: newUser)
        )
        
        let newStudentId = response.id
        
        // Upload photo if selected
        if imagePicker.thereIsAPicToUpdate, let token = authManager.token {
            await imagePicker.loadTransferable2Update(teachAuth: token, studentId: newStudentId)
        }
        
        // Create default app profile
        let defaultProfile = StudentAppProfileManager.makeDefaultfor(newStudentId, locationId: locationId)
        await studentAppProfileManager.addStudentAppProfile(newProfile: defaultProfile)
        
        #if DEBUG
        print("✅ Created new student: \(firstName) \(lastName) with ID: \(newStudentId)")
        #endif
    }
    
    private func updateStudent() async throws {
        guard let student = student else { return }
        
        // Fetch current user data to preserve all fields
        let userResponse: UserDetailResponse = try await ApiManager.shared.getData(
            from: .getaUser(id: student.id)
        )
        let userToUpdate = userResponse.user
        
        // Prepare updated values
        let updatedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let updatedLastName = lastName.trimmingCharacters(in: .whitespaces)
        let updatedNotes = notes
        
        // Call update API
        let _ = try await ApiManager.shared.getDataNoDecode(
            from: .updateaUser(
                id: userToUpdate.id,
                username: userToUpdate.username,
                password: AppConstants.defaultUserPwd,
                email: userToUpdate.email,
                firstName: updatedFirstName,
                lastName: updatedLastName,
                notes: updatedNotes,
                locationId: userToUpdate.locationId,
                groupIds: userToUpdate.groupIds,
                teacherGroups: userToUpdate.teacherGroups
            )
        )
        
        // Upload photo if changed
        if imagePicker.thereIsAPicToUpdate, let token = authManager.token {
            await imagePicker.loadTransferable2Update(teachAuth: token, studentId: student.id)
        }
        
        #if DEBUG
        print("✅ Updated student: \(firstName) \(lastName)")
        #endif
    }
    
    private func deleteStudentAction() async {
        guard let student = student else { return }
        
        await MainActor.run {
            isSaving = true
        }
        
        do {
            let _ = try await ApiManager.shared.getDataNoDecode(
                from: .deleteaUser(id: student.id)
            )
            
            #if DEBUG
            print("🗑️ Deleted student: \(student.name)")
            #endif
            
            await MainActor.run {
                isSaving = false
                onComplete()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
