//
//  ClassManagementListView.swift
//  appi4Manager
//
//  Main list view for admin class management with CRUD operations.
//  Shows all classes for the current location in alphabetical order.
//

import SwiftUI

// MARK: - ClassManagementListView

/// Admin view for managing classes with full CRUD operations.
/// - List all classes alphabetically
/// - Create, edit, and delete classes
/// - Navigate to ClassEditorView for editing
struct ClassManagementListView: View {
    
    // MARK: - Environment & State
    
    @EnvironmentObject var classesViewModel: ClassesViewModel
    @EnvironmentObject var devicesViewModel: DevicesViewModel
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var teacherItems: TeacherItems
    
    @State private var isLoading = false
    @State private var hasError = false
    @State private var error: ApiError?
    @State private var showCreateSheet = false
    @State private var classToDelete: SchoolClass?
    @State private var showDeleteConfirmation = false
    @State private var searchText = ""
    
    // MARK: - Computed Properties
    
    /// Classes for current location, sorted alphabetically, excluding special classes
    private var filteredClasses: [SchoolClass] {
        let locationId = teacherItems.currentLocation.id
        let picClass = teacherItems.schoolClassDictionaryUUID[locationId] ?? ""
        let groupId = teacherItems.schoolClassDictionaryGroupID[locationId] ?? 0
        
        return classesViewModel.schoolClasses
            .filter { schoolClass in
                schoolClass.locationId == locationId &&
                schoolClass.userGroupId != groupId &&
                schoolClass.uuid != picClass
            }
            .filter { schoolClass in
                searchText.isEmpty || 
                schoolClass.name.lowercased().contains(searchText.lowercased())
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background color
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            Group {
                if isLoading {
                    loadingView
                } else if filteredClasses.isEmpty && searchText.isEmpty {
                    emptyStateView
                } else if filteredClasses.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    classListView
                }
            }
        }
        .navigationTitle("Class Management")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search classes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                locationPicker
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            NavigationStack {
                ClassEditorView(
                    schoolClass: SchoolClass.makeDefault(),
                    isNew: true,
                    onSave: {
                        Task {
                            await loadClasses()
                        }
                    }
                )
            }
        }
        .confirmationDialog(
            "Delete Class",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let classToDelete = classToDelete {
                    Task {
                        await deleteClass(classToDelete)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                classToDelete = nil
            }
        } message: {
            if let classToDelete = classToDelete {
                Text("Are you sure you want to delete \"\(classToDelete.name)\"? This action cannot be undone.")
            }
        }
        .alert(isPresented: $hasError, error: error) {
            Button("OK", role: .cancel) { }
        }
        .task {
            await loadClasses()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading classes...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Classes", systemImage: "rectangle.stack.person.crop.fill")
        } description: {
            Text("You haven't created any classes yet.")
        } actions: {
            Button {
                showCreateSheet = true
            } label: {
                Label("Create Class", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var classListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredClasses) { schoolClass in
                    NavigationLink {
                        ClassEditorView(
                            schoolClass: schoolClass,
                            isNew: false,
                            onSave: {
                                Task {
                                    await loadClasses()
                                }
                            }
                        )
                    } label: {
                        ClassCard(schoolClass: schoolClass)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            classToDelete = schoolClass
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Class", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .refreshable {
            await loadClasses()
        }
    }
    
    private var locationPicker: some View {
        Menu {
            Picker("Location", selection: $teacherItems.selectedLocationIdx) {
                ForEach(0..<teacherItems.MDMlocations.count, id: \.self) { index in
                    Text(teacherItems.MDMlocations[index].name)
                        .tag(index)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "building.2.fill")
                Text(teacherItems.MDMlocations[teacherItems.selectedLocationIdx].name)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundColor(.accentColor)
        }
    }
    
    // MARK: - Actions
    
    private func loadClasses() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await classesViewModel.loadData2()
        } catch {
            if let apiError = error as? ApiError {
                self.hasError = true
                self.error = apiError
            }
        }
    }
    
    private func deleteClass(_ schoolClass: SchoolClass) async {
        do {
            try await ApiManager.shared.getDataNoDecode(from: .deleteaClass(uuid: schoolClass.uuid))
            classesViewModel.delete(schoolClass)
            
            #if DEBUG
            print("✅ Deleted class: \(schoolClass.name)")
            #endif
        } catch {
            if let apiError = error as? ApiError {
                self.hasError = true
                self.error = apiError
            }
            #if DEBUG
            print("❌ Failed to delete class: \(error)")
            #endif
        }
    }
}

// MARK: - ClassCard

/// A modern card design for displaying class information.
private struct ClassCard: View {
    let schoolClass: SchoolClass
    
    var body: some View {
        HStack(spacing: 16) {
            // Class Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.8), .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Class Info
            VStack(alignment: .leading, spacing: 4) {
                Text(schoolClass.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !schoolClass.description.isEmpty {
                    Text(schoolClass.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Group ID badge
                HStack(spacing: 6) {
                    Image(systemName: "number.circle.fill")
                        .font(.caption)
                    Text("Group \(schoolClass.userGroupId)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.purple)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ClassManagementListView()
            .environmentObject(ClassesViewModel())
            .environmentObject(DevicesViewModel())
            .environmentObject(UsersViewModel())
            .environmentObject(TeacherItems())
    }
}
