//
//  StudentDetailView.swift
//  appi4Manager
//
//  Read-only student detail for teacher management. Push destination from student list;
//  Edit and Delete actions present sheet or confirmation, then refresh list on complete.
//

import SwiftUI

// MARK: - Teacher Student Detail View

/// Read-only detail view for a student in the teacher management flow.
/// Presented via push navigation; Edit presents the editor as a sheet; Delete pops back after confirmation.
struct TeacherStudentDetailView: View {
    let student: Student
    let classInfo: TeacherClassInfo
    /// Called after save or delete so the parent list can refresh.
    let onComplete: () -> Void
    /// Called when the view disappears (e.g. back button) so parent can clear navigation state.
    var onDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    // Local copies of student data so the detail view can refresh after editing
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var notes: String = ""
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    /// Set to true by the editor's onComplete; checked in onDismiss to avoid unnecessary reloads on Cancel.
    @State private var didSaveChanges = false
    /// Set to true only when the editor uploaded a new photo.
    @State private var didChangePhoto = false
    /// Changes on each edit to force AsyncImage to bypass its cache
    @State private var photoCacheBuster = UUID()

    var body: some View {
        Form {
            photoSection
            nameSection
            notesSection
            deleteSection
        }
        .navigationTitle(student.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet, onDismiss: {
            guard didSaveChanges else { return }
            didSaveChanges = false

            // Only bust the image cache when the photo was actually changed
            if didChangePhoto {
                didChangePhoto = false
                URLCache.shared.removeAllCachedResponses()
                photoCacheBuster = UUID()
            }

            // Reload text data from backend
            Task {
                await loadUserData()
            }
        }) {
            TeacherStudentEditorView(
                student: student,
                classInfo: classInfo,
                onComplete: { photoChanged in
                    didSaveChanges = true
                    didChangePhoto = photoChanged
                    onComplete()
                }
            )
        }
        .confirmationDialog(
            "Delete Student?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Student", role: .destructive) {
                Task {
                    await deleteStudent()
                }
            }
        } message: {
            Text("This action cannot be undone. The student will be removed from the system.")
        }
        .overlay {
            if isDeleting {
                deletingOverlay
            }
        }
        .task {
            await loadUserData()
        }
        .onDisappear {
            onDismiss?()
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        Section {
            HStack {
                Spacer()
                AsyncImage(url: cacheBustedURL(for: student.photo)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.brandIndigo, lineWidth: 2)
                            )
                    default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(.gray)
                    }
                }
                // Force SwiftUI to destroy and recreate AsyncImage so it refetches the photo
                .id(photoCacheBuster)
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        Section(header: Text("Name")) {
            LabeledContent("First Name", value: firstName)
            LabeledContent("Last Name", value: lastName)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section(header: Text("Details")) {
            LabeledContent("Email", value: student.email)
            LabeledContent("Username", value: student.username)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 8)
            } else if let error = loadError {
                Text("Could not load details: \(error)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(.body)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
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

    // MARK: - Deleting Overlay

    private var deletingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Deleting...")
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

    // MARK: - Load User Data

    /// Fetches the full user record from the backend and updates all local display state.
    private func loadUserData() async {
        do {
            let response: UserDetailResponse = try await ApiManager.shared.getData(
                from: .getaUser(id: student.id)
            )
            await MainActor.run {
                firstName = response.user.firstName
                lastName = response.user.lastName
                notes = response.user.notes
                isLoading = false
                loadError = nil
            }
        } catch {
            await MainActor.run {
                // Fall back to the Student struct values on error
                if firstName.isEmpty {
                    firstName = student.firstName
                    lastName = student.lastName
                }
                isLoading = false
                loadError = error.localizedDescription
            }
        }
    }

    // MARK: - Cache Busting

    /// Appends a unique query parameter so AsyncImage treats the URL as new after a photo upload.
    private func cacheBustedURL(for url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: "cb", value: photoCacheBuster.uuidString))
        components?.queryItems = queryItems
        return components?.url ?? url
    }

    // MARK: - Delete Action

    private func deleteStudent() async {
        await MainActor.run {
            isDeleting = true
        }

        do {
            _ = try await ApiManager.shared.getDataNoDecode(
                from: .deleteaUser(id: student.id)
            )

            await MainActor.run {
                isDeleting = false
                onComplete()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isDeleting = false
            }
        }
    }
}
