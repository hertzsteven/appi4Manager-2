//
//  TeacherPickerSheet.swift
//  appi4Manager
//
//  Sheet for selecting existing teachers to assign to a class.
//  Shows all users in the teacher group for the current location.
//

import SwiftUI

// MARK: - TeacherPickerSheet

/// Sheet for picking existing teachers to assign to a class.
/// Loads users from the teacher group (where acl.teacher = "allow").
struct TeacherPickerSheet: View {
    
    // MARK: - Environment & State
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var teacherItems: TeacherItems
    
    let classUUID: String
    let currentlyAssignedTeacherIds: Set<Int>
    var onTeachersSelected: (([User]) -> Void)?
    
    @State private var availableTeachers: [User] = []
    @State private var selectedTeacherIds: Set<Int> = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var hasError = false
    @State private var errorMessage: String?
    
    // MARK: - Computed Properties
    
    private var filteredTeachers: [User] {
        if searchText.isEmpty {
            return availableTeachers
        }
        return availableTeachers.filter { teacher in
            teacher.firstName.lowercased().contains(searchText.lowercased()) ||
            teacher.lastName.lowercased().contains(searchText.lowercased()) ||
            teacher.username.lowercased().contains(searchText.lowercased()) ||
            teacher.email.lowercased().contains(searchText.lowercased())
        }
    }
    
    private var selectedTeachersList: [User] {
        availableTeachers.filter { selectedTeacherIds.contains($0.id) }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if availableTeachers.isEmpty {
                emptyStateView
            } else if filteredTeachers.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                teacherListView
            }
        }
        .navigationTitle("Select Teachers")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by name or username")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Add (\(selectedTeacherIds.count))") {
                    onTeachersSelected?(selectedTeachersList)
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(selectedTeacherIds.isEmpty)
            }
        }
        .alert("Error", isPresented: $hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Failed to load teachers.")
        }
        .task {
            await loadAvailableTeachers()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading teachers...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Teachers Available", systemImage: "person.crop.circle.badge.questionmark")
        } description: {
            Text("No teachers found in the teacher group. Create a new teacher first.")
        }
    }
    
    private var teacherListView: some View {
        List {
            Section {
                ForEach(filteredTeachers, id: \.id) { teacher in
                    TeacherPickerRow(
                        teacher: teacher,
                        isSelected: selectedTeacherIds.contains(teacher.id),
                        isAlreadyAssigned: currentlyAssignedTeacherIds.contains(teacher.id),
                        onToggle: {
                            toggleSelection(teacher)
                        }
                    )
                }
            } header: {
                Text("\(filteredTeachers.count) Teacher\(filteredTeachers.count == 1 ? "" : "s") Available")
            } footer: {
                Text("Teachers already assigned to this class are shown as disabled.")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Actions
    
    private func loadAvailableTeachers() async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        do {
            // Get the teacher group ID for current location
            guard let teacherGroupId = teacherItems.teacherGroupDict[teacherItems.currentLocation.id] else {
                await MainActor.run {
                    hasError = true
                    errorMessage = "No teacher group found for this location."
                }
                return
            }
            
            // Get all users in the teacher group
            let response: UserResponse = try await ApiManager.shared.getData(
                from: .getUsersInGroup(groupID: teacherGroupId)
            )
            
            // Filter out the system teacher user (username starts with teacherUserName constant)
            let teachers = response.users.filter { user in
                !user.username.contains(AppConstants.teacherUserName)
            }
            
            await MainActor.run {
                availableTeachers = teachers.sorted { 
                    "\($0.lastName) \($0.firstName)" < "\($1.lastName) \($1.firstName)" 
                }
            }
            
            #if DEBUG
            print("👩‍🏫 Found \(teachers.count) available teachers in teacher group")
            #endif
            
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = error.localizedDescription
            }
            #if DEBUG
            print("❌ Failed to load teachers: \(error)")
            #endif
        }
    }
    
    private func toggleSelection(_ teacher: User) {
        // Don't allow selecting already assigned teachers
        guard !currentlyAssignedTeacherIds.contains(teacher.id) else { return }
        
        if selectedTeacherIds.contains(teacher.id) {
            selectedTeacherIds.remove(teacher.id)
        } else {
            selectedTeacherIds.insert(teacher.id)
        }
    }
}

// MARK: - TeacherPickerRow

private struct TeacherPickerRow: View {
    let teacher: User
    let isSelected: Bool
    let isAlreadyAssigned: Bool
    var onToggle: (() -> Void)?
    
    var body: some View {
        Button {
            onToggle?()
        } label: {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: selectionIcon)
                    .font(.title2)
                    .foregroundColor(selectionColor)
                
                // Teacher icon
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)
                
                // Teacher info
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(teacher.firstName) \(teacher.lastName)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isAlreadyAssigned ? .secondary : .primary)
                    
                    Text(teacher.username)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !teacher.email.isEmpty {
                        Text(teacher.email)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isAlreadyAssigned {
                    Text("Assigned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isAlreadyAssigned)
    }
    
    private var selectionIcon: String {
        if isAlreadyAssigned {
            return "checkmark.circle.fill"
        }
        return isSelected ? "checkmark.circle.fill" : "circle"
    }
    
    private var selectionColor: Color {
        if isAlreadyAssigned {
            return .gray
        }
        return isSelected ? .accentColor : .gray
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TeacherPickerSheet(
            classUUID: "test-uuid",
            currentlyAssignedTeacherIds: []
        )
        .environmentObject(TeacherItems())
    }
}
