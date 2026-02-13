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
    let classesWithDevices: [TeacherClassInfo]
    
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
    
    init(classInfo: TeacherClassInfo, classesWithDevices: [TeacherClassInfo], onStudentChanged: (() -> Void)? = nil) {
        self.classInfo = classInfo
        self.classesWithDevices = classesWithDevices
        self.onStudentChanged = onStudentChanged
        // Initialize local students with the passed-in data (excluding dummy students)
        let filtered = classInfo.students.filter { $0.lastName != classInfo.classUUID }
        _localStudents = State(initialValue: filtered)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Student Management")
                .font(.title3)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
                .padding(.bottom , 18)
            // Student list
            if localStudents.isEmpty {
                emptyStateView
            } else {
                studentListView
            }
        }
        .navigationTitle("Students")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGray5))
        .teacherDashboardToolbar(
            activeClass: classInfo,
            classesWithDevices: classesWithDevices
        )
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
                    
//                    if !localStudents.isEmpty {
//                        Divider()
//                        
//                        Button(role: .destructive) {
//                            showUnassignStudents = true
//                        } label: {
//                            Label("Unassign Students", systemImage: "person.badge.minus")
//                        }
//                    }
                } label: {
                    Image(systemName: "plus")
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
    
    // MARK: - Action Header (Removed — replaced by toolbar "+" menu)

    // MARK: - Header View (Removed - replaced by toolbar)
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Students", systemImage: "person.3.fill")
        } description: {
            Text("This class has no students yet.")
        } actions: {
            VStack(spacing: 12) {
                Button {
                    showAddStudent = true
                } label: {
                    Label("Add New Student", systemImage: "person.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    showAssignExisting = true
                } label: {
                    Label("Assign Existing Student", systemImage: "person.2.badge.gearshape")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Student List
    
    private var studentListView: some View {
        List {
            // Student rows
            Section {
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
            } header: {
                Text("Students (\(localStudents.count))")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Student Row
    
    private func studentRow(_ student: Student) -> some View {
        Button {
            studentToEdit = student
        } label: {
            HStack(spacing: 14) {
                // Student photo — matches Activity screen size
                AsyncImage(url: cacheBustedURL(for: student.photo)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(.circle)
                    default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundStyle(.gray)
                    }
                }
                
                // Student info
                VStack(alignment: .leading, spacing: 4) {
                    Text(student.name)
                        .font(.headline)
                    
                    Text(student.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(Color.brandIndigo)

//                Image(systemName: "chevron.right")
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
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

// MARK: - Preview

#Preview("Student Management") {
    let sampleStudents = [
        Student(
            id: 1,
            name: "David Grossman",
            email: "QWERTY@gmail.com",
            username: "david.g",
            firstName: "David",
            lastName: "Grossman",
            photo: URL(string: "https://placehold.co/100")!
        ),
        Student(
            id: 2,
            name: "Yehuda Grossman",
            email: "Ytrewq@gmail.com",
            username: "yehuda.g",
            firstName: "Yehuda",
            lastName: "Grossman",
            photo: URL(string: "https://placehold.co/100")!
        )
    ]

    let sampleClass = TeacherClassInfo(
        id: "preview-uuid",
        className: "Grossman",
        classUUID: "preview-uuid",
        userGroupID: 1,
        userGroupName: "Group A",
        locationId: 1,
        students: sampleStudents
    )

    NavigationStack {
        TeacherStudentManagementSheet(
            classInfo: sampleClass,
            classesWithDevices: [sampleClass]
        )
    }
    .environment(AuthenticationManager())
    .environmentObject(TeacherItems())
}
