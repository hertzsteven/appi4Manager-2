//
//  StudentUnassignSheet.swift
//  appi4Manager
//
//  Sheet for selecting students to unassign from a class.
//  Supports multi-select with confirmation before unassigning.
//

import SwiftUI

// MARK: - Student Unassign Sheet

/// Sheet for picking students to unassign from a class.
/// Students are removed from the class but not deleted from the system.
struct StudentUnassignSheet: View {
    
    // MARK: - Properties
    
    let classInfo: TeacherClassInfo
    
    /// Callback when unassignment completes to refresh parent view
    var onComplete: (() -> Void)?
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    /// Students currently in the class (excluding dummy students)
    @State private var studentsInClass: [Student] = []
    
    /// Selected student IDs for unassignment
    @State private var selectedStudentIds: Set<Int> = []
    
    /// Search text for filtering
    @State private var searchText = ""
    
    /// UI state
    @State private var isUnassigning = false
    @State private var showConfirmation = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // MARK: - Computed Properties
    
    /// Filtered students based on search text
    private var filteredStudents: [Student] {
        if searchText.isEmpty {
            return studentsInClass.sorted { $0.name < $1.name }
        }
        return studentsInClass
            .filter { $0.name.localizedStandardContains(searchText) }
            .sorted { $0.name < $1.name }
    }
    
    /// Count of selected students
    private var selectedCount: Int {
        selectedStudentIds.count
    }
    
    /// Names of selected students for confirmation message
    private var selectedStudentNames: String {
        let names = studentsInClass
            .filter { selectedStudentIds.contains($0.id) }
            .map { $0.name }
        
        if names.count <= 3 {
            return names.joined(separator: ", ")
        } else {
            let first = names.prefix(2).joined(separator: ", ")
            return "\(first), and \(names.count - 2) more"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header info
                headerSection
                
                Divider()
                
                // Student list
                if studentsInClass.isEmpty {
                    emptyStateView
                } else if filteredStudents.isEmpty {
                    noResultsView
                } else {
                    studentListView
                }
            }
            .navigationTitle("Unassign Students")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isUnassigning)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Unassign \(selectedCount)") {
                        showConfirmation = true
                    }
                    .disabled(selectedCount == 0 || isUnassigning)
                    .fontWeight(.semibold)
                }
            }
            .searchable(text: $searchText, prompt: "Search students")
            .overlay {
                if isUnassigning {
                    unassigningOverlay
                }
            }
            .confirmationDialog(
                "Unassign Students?",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Unassign \(selectedCount) Student\(selectedCount == 1 ? "" : "s")", role: .destructive) {
                    Task {
                        await unassignSelectedStudents()
                    }
                }
            } message: {
                Text("Remove \(selectedStudentNames) from \(classInfo.className)? They will remain in the system but will no longer be part of this class.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            .onAppear {
                // Filter out dummy students
                studentsInClass = classInfo.students.filter { $0.lastName != classInfo.classUUID }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Unassign from: \(classInfo.className)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Students will be removed from this class but not deleted from the system.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Students", systemImage: "person.3.fill")
        } description: {
            Text("This class has no students to unassign.")
        }
    }
    
    // MARK: - No Results View
    
    private var noResultsView: some View {
        ContentUnavailableView.search(text: searchText)
    }
    
    // MARK: - Student List
    
    private var studentListView: some View {
        List {
            Section {
                ForEach(filteredStudents, id: \.id) { student in
                    studentRow(student)
                }
            } header: {
                Text("\(studentsInClass.count) student\(studentsInClass.count == 1 ? "" : "s") in class")
            } footer: {
                if selectedCount > 0 {
                    Text("\(selectedCount) student\(selectedCount == 1 ? "" : "s") selected for removal")
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Student Row
    
    private func studentRow(_ student: Student) -> some View {
        Button {
            toggleSelection(for: student.id)
        } label: {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: selectedStudentIds.contains(student.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selectedStudentIds.contains(student.id) ? .red : .secondary)
                
                // Student photo
                AsyncImage(url: student.photo) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(.circle)
                    default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.gray)
                    }
                }
                
                // Student info
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Text(student.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Unassigning Overlay
    
    private var unassigningOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Unassigning students...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
            )
        }
    }
    
    // MARK: - Actions
    
    private func toggleSelection(for studentId: Int) {
        if selectedStudentIds.contains(studentId) {
            selectedStudentIds.remove(studentId)
        } else {
            selectedStudentIds.insert(studentId)
        }
    }
    
    // MARK: - Unassignment
    
    private func unassignSelectedStudents() async {
        print("🚨 [UNASSIGN] Function called")
        print("🚨 [UNASSIGN] selectedStudentIds: \(selectedStudentIds)")
        print("🚨 [UNASSIGN] classInfo.userGroupID: \(classInfo.userGroupID)")
        
        guard !selectedStudentIds.isEmpty else {
            print("🚨 [UNASSIGN] EARLY RETURN - selectedStudentIds is empty!")
            return
        }
        
        await MainActor.run {
            isUnassigning = true
        }
        
        var successCount = 0
        var failCount = 0
        
        // Unassign each selected student by removing the class group from their groupIds
        for studentId in selectedStudentIds {
            do {
                print("🚨 [UNASSIGN] Processing student ID: \(studentId)")
                
                // 1. Fetch the user's current data
                let userResponse: UserDetailResponse = try await ApiManager.shared.getData(
                    from: .getaUser(id: studentId)
                )
                
                print("🚨 [UNASSIGN] Current groupIds: \(userResponse.user.groupIds)")
                
                // 2. Remove the class's userGroupID from their groupIds
                var updatedGroupIds = userResponse.user.groupIds.removingDuplicates()
                
                guard let idx = updatedGroupIds.firstIndex(of: classInfo.userGroupID) else {
                    print("⚠️ [UNASSIGN] Student \(studentId) not in group \(classInfo.userGroupID), skipping")
                    continue
                }
                updatedGroupIds.remove(at: idx)
                
                print("🚨 [UNASSIGN] Updated groupIds: \(updatedGroupIds)")
                
                // 3. Update the user with the modified groupIds
                let _ = try await ApiManager.shared.getDataNoDecode(
                    from: .updateaUser(
                        id: userResponse.user.id,
                        username: userResponse.user.username,
                        password: AppConstants.defaultUserPwd,
                        email: userResponse.user.email,
                        firstName: userResponse.user.firstName,
                        lastName: userResponse.user.lastName,
                        notes: userResponse.user.notes,
                        locationId: userResponse.user.locationId,
                        groupIds: updatedGroupIds,
                        teacherGroups: userResponse.user.teacherGroups
                    )
                )
                
                print("✅ [UNASSIGN] Successfully unassigned student \(studentId)")
                successCount += 1
                
            } catch {
                print("❌ [UNASSIGN] Failed to unassign student \(studentId): \(error)")
                failCount += 1
            }
        }
        
        print("🚨 [UNASSIGN] Complete: \(successCount) succeeded, \(failCount) failed")
        
        await MainActor.run {
            isUnassigning = false
            
            if failCount > 0 && successCount == 0 {
                errorMessage = "Failed to unassign students"
                showError = true
            } else {
                onComplete?()
                dismiss()
            }
        }
    }
}
