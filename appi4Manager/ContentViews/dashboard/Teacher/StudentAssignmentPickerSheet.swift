//
//  StudentAssignmentPickerSheet.swift
//  appi4Manager
//
//  Sheet for selecting existing students to assign to a class.
//  Supports multi-select, search filtering, and location filtering.
//

import SwiftUI

// MARK: - Student Assignment Picker Sheet

/// Sheet for picking existing students to assign to a class.
/// Shows students not currently in the class, with filtering options.
struct StudentAssignmentPickerSheet: View {
    
    // MARK: - Properties
    
    let classInfo: TeacherClassInfo
    
    /// Callback when assignment completes to refresh parent view
    var onComplete: (() -> Void)?
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var teacherItems: TeacherItems
    
    // MARK: - State
    
    /// All students fetched from API
    @State private var allStudents: [User] = []
    
    /// IDs of students currently in the class (to exclude from picker)
    @State private var studentsInClassIds: Set<Int> = []
    
    /// Selected student IDs for assignment
    @State private var selectedStudentIds: Set<Int> = []
    
    /// Search text for filtering
    @State private var searchText = ""
    
    
    /// UI state
    @State private var isLoading = true
    @State private var isAssigning = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // MARK: - Computed Properties
    
    /// Students available for assignment (not already in class)
    private var availableStudents: [User] {
        allStudents.filter { user in
            // Exclude students already in this class
            guard !studentsInClassIds.contains(user.id) else { return false }
            
            // Only include students (exclude teachers by checking if they have teacherGroups)
            guard user.teacherGroups.isEmpty else { return false }
            
            // Exclude dummy students (lastName is a UUID pattern)
            guard UUID(uuidString: user.lastName) == nil else { return false }
            
            // Only show students from the same location
            guard user.locationId == classInfo.locationId else { return false }
            
            return true
        }
    }
    
    /// Filtered students based on search text
    private var filteredStudents: [User] {
        if searchText.isEmpty {
            return availableStudents.sorted { $0.nameToDisplay < $1.nameToDisplay }
        }
        return availableStudents
            .filter { $0.nameToDisplay.localizedStandardContains(searchText) }
            .sorted { $0.nameToDisplay < $1.nameToDisplay }
    }
    
    /// Count of selected students
    private var selectedCount: Int {
        selectedStudentIds.count
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter controls
                filterSection
                
                Divider()
                
                // Student list
                if isLoading {
                    loadingView
                } else if filteredStudents.isEmpty {
                    emptyStateView
                } else {
                    studentListView
                }
            }
            .navigationTitle("Assign Students")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isAssigning)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Assign \(selectedCount)") {
                        Task {
                            await assignSelectedStudents()
                        }
                    }
                    .disabled(selectedCount == 0 || isAssigning)
                    .fontWeight(.semibold)
                }
            }
            .searchable(text: $searchText, prompt: "Search students")
            .overlay {
                if isAssigning {
                    assigningOverlay
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            .task {
                await loadStudents()
            }
        }
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Assign to: \(classInfo.className)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Showing students from the same location.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading students...")
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Students Available", systemImage: "person.3.fill")
        } description: {
            Text("No students from this location are available to assign, or all students are already assigned to this class.")
        }
    }
    
    // MARK: - Student List
    
    private var studentListView: some View {
        List {
            Section {
                ForEach(filteredStudents, id: \.id) { student in
                    studentRow(student)
                }
            } header: {
                Text("\(filteredStudents.count) student\(filteredStudents.count == 1 ? "" : "s") available")
            } footer: {
                if selectedCount > 0 {
                    Text("\(selectedCount) student\(selectedCount == 1 ? "" : "s") selected for assignment")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Student Row
    
    private func studentRow(_ student: User) -> some View {
        Button {
            toggleSelection(for: student.id)
        } label: {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: selectedStudentIds.contains(student.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selectedStudentIds.contains(student.id) ? .blue : .secondary)
                
                // Student photo placeholder
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.gray)
                
                // Student info
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.nameToDisplay)
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
    
    // MARK: - Assigning Overlay
    
    private var assigningOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Assigning students...")
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
    
    // MARK: - Data Loading
    
    private func loadStudents() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Fetch all users from API
            let userResponse: UserResponse = try await ApiManager.shared.getData(from: .getUsers)
            
            // Get current students in the class
            let currentStudentIds = Set(classInfo.students.map { $0.id })
            
            await MainActor.run {
                allStudents = userResponse.users
                studentsInClassIds = currentStudentIds
                isLoading = false
            }
            
            #if DEBUG
            print("📚 Loaded \(userResponse.users.count) total users")
            print("📚 \(currentStudentIds.count) students already in class")
            #endif
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to load students: \(error.localizedDescription)"
                showError = true
            }
            
            #if DEBUG
            print("❌ Failed to load students: \(error)")
            #endif
        }
    }
    
    // MARK: - Assignment
    
    private func assignSelectedStudents() async {
        guard !selectedStudentIds.isEmpty else { return }
        
        await MainActor.run {
            isAssigning = true
        }
        
        do {
            // First, fetch the current class details to get the list of teachers
            // We need to preserve teachers when updating class membership since PUT replaces everything
            let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(
                from: .getStudents(uuid: classInfo.classUUID)
            )
            
            // Get current teacher IDs to preserve them
            let currentTeacherIds = classDetailResponse.class.teachers.map { $0.id }
            
            // Combine existing students with newly selected ones
            let existingStudentIds = classInfo.students.map { $0.id }
            let allStudentIds = existingStudentIds + Array(selectedStudentIds)
            
            #if DEBUG
            print("📚 Current teachers: \(currentTeacherIds)")
            print("📚 Assigning students: \(allStudentIds)")
            #endif
            
            // Call the API to assign students
            // IMPORTANT: Include current teachers to preserve them!
            let _ = try await ApiManager.shared.getDataNoDecode(
                from: .assignToClass(
                    uuid: classInfo.classUUID,
                    students: allStudentIds,
                    teachers: currentTeacherIds
                )
            )
            
            #if DEBUG
            print("✅ Assigned \(selectedStudentIds.count) students to class")
            #endif
            
            await MainActor.run {
                isAssigning = false
                onComplete?()
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                isAssigning = false
                errorMessage = "Failed to assign students: \(error.localizedDescription)"
                showError = true
            }
            
            #if DEBUG
            print("❌ Failed to assign students: \(error)")
            #endif
        }
    }
}
