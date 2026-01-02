//
//  ClassManagementListView.swift
//  appi4Manager
//
//  Main list view for admin class management with CRUD operations.
//  Shows all classes for the current location in alphabetical order.
//

import SwiftUI

// MARK: - ClassFilterType

/// Filter options for class management list
enum ClassFilterType: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case inactive = "Inactive"
}

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
    @State private var selectedFilter: ClassFilterType = .all
    
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
            // Apply active/inactive filter
            .filter { schoolClass in
                switch selectedFilter {
                case .all: return true
                case .active: return isClassActive(schoolClass)
                case .inactive: return !isClassActive(schoolClass)
                }
            }
            .filter { schoolClass in
                searchText.isEmpty ||
                schoolClass.name.localizedStandardContains(searchText)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    /// Checks if a class has devices assigned via assetTag
    private func hasDevices(_ schoolClass: SchoolClass) -> Bool {
        let matchingDevices = devicesViewModel.devices.filter { $0.assetTag == String(schoolClass.userGroupId) }
        #if DEBUG
        if !matchingDevices.isEmpty {
            print("📱 Class \(schoolClass.name) has \(matchingDevices.count) devices with assetTag=\(schoolClass.userGroupId)")
        }
        #endif
        return !matchingDevices.isEmpty
    }
    
    /// A class is active if it has both a teacher and a device assigned
    private func isClassActive(_ schoolClass: SchoolClass) -> Bool {
        let hasTeacher = schoolClass.teacherCount > 0
        let hasDevice = hasDevices(schoolClass)
        #if DEBUG
        print("🔍 Class \(schoolClass.name): teacherCount=\(schoolClass.teacherCount), hasDevice=\(hasDevice), isActive=\(hasTeacher && hasDevice)")
        #endif
        return hasTeacher && hasDevice
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background color
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Search & Filter Area
                VStack(spacing: 16) {
                    // Search Bar handled by .searchable, but we can add custom header elements if needed
                    
                    // Modern Chip Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ClassFilterType.allCases, id: \.self) { filter in
                                Button {
                                    withAnimation(.snappy) {
                                        selectedFilter = filter
                                    }
                                } label: {
                                    Text(filter.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(selectedFilter == filter ? Color.primary : Color(.systemBackground))
                                        .foregroundColor(selectedFilter == filter ? Color(.systemBackground) : Color.primary)
                                        .clipShape(Capsule())
                                        .shadow(color: .black.opacity(selectedFilter == filter ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 8)
                }
                .padding(.top, 8)
                .background(Color(.systemGroupedBackground))
                
                Group {
                    if isLoading {
                        loadingView
                    } else if filteredClasses.isEmpty && searchText.isEmpty && selectedFilter == .all {
                        emptyStateView
                    } else if filteredClasses.isEmpty {
                        ContentUnavailableView.search(text: searchText.isEmpty ? selectedFilter.rawValue : searchText)
                    } else {
                        classListView
                    }
                }
            }
        }
        .navigationTitle("Class Management")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search classes")
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
            // Ensure devices are loaded for active/inactive filtering
            if devicesViewModel.devices.isEmpty {
                do {
                    try await devicesViewModel.loadData2()
                    #if DEBUG
                    print("📱 Loaded \(devicesViewModel.devices.count) devices for filtering")
                    #endif
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to load devices: \(error)")
                    #endif
                }
            }
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
            LazyVStack(spacing: 16) {
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
                        ClassCard(schoolClass: schoolClass, isActive: isClassActive(schoolClass))
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
            .padding(.vertical, 16)
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
