//
//  TeacherStudentManagementSheet.swift
//  appi4Manager
//
//  Sheet for managing students in a class (viewing, editing, adding, deleting)
//

import SwiftUI

// MARK: - Teacher Student Management Sheet

/// Sheet for managing students in a class (viewing, editing, adding, deleting)
struct TeacherStudentManagementSheet: View {
    let classInfo: TeacherClassInfo
    
    /// Callback to refresh student data after changes (updates parent view)
    var onStudentChanged: (() -> Void)?
    
    // MARK: - State
    
    /// Local copy of students for immediate UI updates
    @State private var localStudents: [Student]
    @State private var showAddStudent = false
    @State private var showAssignExisting = false
    @State private var showUnassignStudents = false
    @State private var studentToEdit: Student?
    @State private var studentToDelete: Student?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var isRefreshing = false
    @State private var photoCacheBuster = UUID()
    
    @Environment(AuthenticationManager.self) private var authManager
    
    // MARK: - Initialization
    
    init(classInfo: TeacherClassInfo, onStudentChanged: (() -> Void)? = nil) {
        self.classInfo = classInfo
        self.onStudentChanged = onStudentChanged
        // Initialize local students with the passed-in data (excluding dummy students)
        let filtered = classInfo.students.filter { $0.lastName != classInfo.classUUID }
        _localStudents = State(initialValue: filtered)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with student count
            headerView
            
            // Student list
            if localStudents.isEmpty {
                emptyStateView
            } else {
                studentListView
            }
        }
        .navigationTitle("Students")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showAddStudent = true
                    } label: {
                        Label("Add New Student", systemImage: "person.badge.plus")
                    }
                    
                    Button {
                        showAssignExisting = true
                    } label: {
                        Label("Assign Existing Student", systemImage: "person.2.badge.gearshape")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showUnassignStudents = true
                    } label: {
                        Label("Unassign Students", systemImage: "person.badge.minus")
                    }
                    .disabled(localStudents.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddStudent) {
            TeacherStudentEditorView(
                student: nil,
                classInfo: classInfo,
                onComplete: {
                    // Refresh local students list
                    Task {
                        await refreshStudents()
                    }
                    // Also notify parent to refresh its data
                    onStudentChanged?()
                }
            )
        }
        .sheet(item: $studentToEdit) { student in
            TeacherStudentEditorView(
                student: student,
                classInfo: classInfo,
                onComplete: {
                    // Refresh local students list
                    Task {
                        await refreshStudents()
                    }
                    // Also notify parent to refresh its data
                    onStudentChanged?()
                }
            )
        }
        .sheet(isPresented: $showAssignExisting) {
            StudentAssignmentPickerSheet(
                classInfo: classInfo,
                onComplete: {
                    // Refresh local students list
                    Task {
                        await refreshStudents()
                    }
                    // Also notify parent to refresh its data
                    onStudentChanged?()
                }
            )
        }
        .sheet(isPresented: $showUnassignStudents) {
            StudentUnassignSheet(
                classInfo: classInfo,
                onComplete: {
                    // Refresh local students list
                    Task {
                        await refreshStudents()
                    }
                    // Also notify parent to refresh its data
                    onStudentChanged?()
                }
            )
        }
        .confirmationDialog(
            "Delete Student?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Student", role: .destructive) {
                if let student = studentToDelete {
                    Task {
                        await deleteStudent(student)
                    }
                }
            }
        } message: {
            if let student = studentToDelete {
                Text("Are you sure you want to delete \(student.name)? This action cannot be undone.")
            }
        }
        .overlay {
            if isDeleting {
                deletingOverlay
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 4) {
            Text("Manage Students")
                .font(.headline)
            
            HStack(spacing: 8) {
                Text(classInfo.className)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                // Count excludes dummy students (already filtered in localStudents)
                Text("\(localStudents.count) student\(localStudents.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Students", systemImage: "person.3.fill")
        } description: {
            Text("This class has no students yet.")
        } actions: {
            Button {
                showAddStudent = true
            } label: {
                Text("Add Student")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Student List
    
    private var studentListView: some View {
        List {
            ForEach(localStudents, id: \.id) { student in
                studentRow(student)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            studentToDelete = student
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            studentToEdit = student
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Student Row
    
    private func studentRow(_ student: Student) -> some View {
        Button {
            studentToEdit = student
        } label: {
            HStack(spacing: 12) {
                // Student photo
                AsyncImage(url: cacheBustedURL(for: student.photo)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.gray)
                    }
                }
                
                // Student info
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(student.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Disclosure indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
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
    
    // MARK: - Delete Action
    
    private func deleteStudent(_ student: Student) async {
        await MainActor.run {
            isDeleting = true
        }
        
        do {
            let _ = try await ApiManager.shared.getDataNoDecode(
                from: .deleteaUser(id: student.id)
            )
            
            #if DEBUG
            print("🗑️ Deleted student: \(student.name)")
            #endif
            
            // Always refresh from backend to ensure consistency
            await refreshStudents()
            
            await MainActor.run {
                isDeleting = false
                studentToDelete = nil
                onStudentChanged?()
            }
        } catch {
            await MainActor.run {
                isDeleting = false
                studentToDelete = nil
                #if DEBUG
                print("❌ Failed to delete student: \(error)")
                #endif
            }
            
            // Pull fresh data to reflect backend truth (in case delete failed)
            await refreshStudents()
        }
    }
    
    // MARK: - Refresh Students
    
    /// Fetches fresh student data from the API
    private func refreshStudents() async {
        await MainActor.run {
            isRefreshing = true
        }
        
        do {
            let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(
                from: .getStudents(uuid: classInfo.classUUID)
            )
            
            await MainActor.run {
                // Filter out dummy students (lastName matches classUUID)
                localStudents = classDetailResponse.class.students.filter { $0.lastName != classInfo.classUUID }
                photoCacheBuster = UUID() // bust AsyncImage cache after updates
                URLCache.shared.removeAllCachedResponses()
                isRefreshing = false
            }
            
            #if DEBUG
            print("🔄 Refreshed student list: \(localStudents.count) students")
            #endif
        } catch {
            await MainActor.run {
                isRefreshing = false
                #if DEBUG
                print("⚠️ Failed to refresh students: \(error)")
                #endif
            }
        }
    }
}

// MARK: - Student Extension for Identifiable Sheet

extension Student: Identifiable { }

// MARK: - Cache Busting Helper

private extension TeacherStudentManagementSheet {
    func cacheBustedURL(for url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: "cb", value: photoCacheBuster.uuidString))
        components?.queryItems = queryItems
        return components?.url ?? url
    }
}
