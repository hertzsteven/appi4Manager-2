//
//  StudentRestrictionsSheet.swift
//  appi4Manager
//
//  Displays current device restrictions for students in a class.
//  Shows which students are locked into specific apps.
//

import SwiftUI

/// Sheet view that fetches and displays current device restrictions for all students in a class
struct StudentRestrictionsSheet: View {
    
    // MARK: - Properties
    
    /// The class to fetch restrictions for
    let classInfo: TeacherClassInfo
    
    /// Teacher auth token for API calls
    let authToken: String
    
    // MARK: - State
    
    /// Loading state
    @State private var isLoading = true
    
    /// Error message if fetch fails
    @State private var errorMessage: String?
    
    /// Fetched restriction profiles
    @State private var restrictionProfiles: [StudentRestrictionProfile] = []
    
    /// Dismiss action
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if restrictionProfiles.isEmpty {
                    emptyView
                } else {
                    restrictionsList
                }
            }
            .navigationTitle("Device Restrictions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await fetchRestrictions()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
        }
        .task {
            await fetchRestrictions()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Fetching device restrictions...")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") {
                Task {
                    await fetchRestrictions()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        ContentUnavailableView(
            "No Restrictions Found",
            systemImage: "lock.open.fill",
            description: Text("No students currently have device restrictions active.")
        )
    }
    
    // MARK: - Restrictions List
    
    private var restrictionsList: some View {
        List {
            // Summary section
            Section {
                HStack {
                    Label("Total Students", systemImage: "person.2.fill")
                    Spacer()
                    Text("\(restrictionProfiles.count)")
                        .foregroundColor(.secondary)
                }
                
                let lockedCount = restrictionProfiles.filter { $0.hasActiveRestrictions }.count
                HStack {
                    Label("Locked Devices", systemImage: "lock.fill")
                    Spacer()
                    Text("\(lockedCount)")
                        .foregroundColor(lockedCount > 0 ? .orange : .secondary)
                }
                
                let unlockedCount = restrictionProfiles.filter { !$0.hasActiveRestrictions }.count
                HStack {
                    Label("Unlocked Devices", systemImage: "lock.open.fill")
                    Spacer()
                    Text("\(unlockedCount)")
                        .foregroundColor(.green)
                }
            } header: {
                Text("Summary")
            }
            
            // Locked students section
            let lockedStudents = restrictionProfiles.filter { $0.hasActiveRestrictions }
            if !lockedStudents.isEmpty {
                Section {
                    ForEach(lockedStudents) { profile in
                        studentRestrictionRow(profile: profile)
                    }
                } header: {
                    Text("Locked (\(lockedStudents.count))")
                }
            }
            
            // Unlocked students section
            let unlockedStudents = restrictionProfiles.filter { !$0.hasActiveRestrictions }
            if !unlockedStudents.isEmpty {
                Section {
                    ForEach(unlockedStudents) { profile in
                        studentRestrictionRow(profile: profile)
                    }
                } header: {
                    Text("Unlocked (\(unlockedStudents.count))")
                }
            }
        }
    }
    
    // MARK: - Student Restriction Row
    
    private func studentRestrictionRow(profile: StudentRestrictionProfile) -> some View {
        HStack(spacing: 12) {
            // Lock status icon
            Image(systemName: profile.hasActiveRestrictions ? "lock.fill" : "lock.open.fill")
                .foregroundColor(profile.hasActiveRestrictions ? .orange : .green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                // Student ID and name lookup
                Text(studentName(for: profile.studentId))
                    .font(.headline)
                
                // Lock status description
                Text(profile.lockStatusDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Lesson ID if present
                if let lessonId = profile.lessonId {
                    Text("Lesson: \(lessonId)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Student ID badge
            Text("ID: \(profile.studentId)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Methods
    
    /// Looks up student name from classInfo by ID
    private func studentName(for studentId: Int) -> String {
        if let student = classInfo.students.first(where: { $0.id == studentId }) {
            return "\(student.firstName) \(student.lastName)"
        }
        return "Student \(studentId)"
    }
    
    /// Fetches restriction profiles from the API using the working implementation approach
    private func fetchRestrictions() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Create custom URLSession (not shared) - matches working implementation
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        
        // Build URL with query parameters
        guard var url = URL(string: "https://developitsnfrEDU.jamfcloud.com/api/teacher/profiles") else {
            await MainActor.run {
                errorMessage = "Invalid URL"
                isLoading = false
            }
            return
        }
        
        // TEST 2: Changed token back to dynamic (all params now dynamic)
        let urlParams = [
            "token": authToken,
            "scope": "class",
            "scopeId": String(classInfo.userGroupID)
        ]
        
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Headers - using the working credentials
        request.addValue("Basic NjUzMTkwNzY6TUNTTUQ2VkM3TUNLVU5OOE1KNUNEQTk2UjFIWkJHQVY=", forHTTPHeaderField: "Authorization")
        request.addValue("4", forHTTPHeaderField: "X-Server-Protocol-Version")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("hash=c683a60c07d2f6e4b1fd4e385d034954", forHTTPHeaderField: "Cookie")
        
        #if DEBUG
        print("🔒 ========================================")
        print("🔒 Fetching restrictions for class: \(classInfo.className)")
        print("🔒 userGroupID (scopeId): \(classInfo.userGroupID)")
        print("🔒 Token: \(authToken)")
        print("🔒 URL: \(url.absoluteString)")
        print("🔒 ========================================")
        #endif
        
        do {
            let (data, response) = try await session.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            #if DEBUG
            print("🔒 HTTP Status: \(statusCode)")
            print("🔒 RAW JSON RESPONSE:")
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
            print("🔒 ========================================")
            #endif
            
            // Decode the response
            let profiles = try JSONDecoder().decode([StudentRestrictionProfile].self, from: data)
            
            #if DEBUG
            print("🔒 ✅ SUCCESS - Received \(profiles.count) restriction profiles")
            for profile in profiles {
                print("🔒 ----------------------------------------")
                print("🔒 Student ID: \(profile.studentId)")
                print("🔒 appWhitelist: \(profile.appWhitelist ?? [])")
                print("🔒 restrictions: \(profile.restrictions ?? [])")
                print("🔒 lessonId: \(String(describing: profile.lessonId))")
                print("🔒 startDate: \(profile.startDate ?? "nil")")
                print("🔒 endDate: \(profile.endDate ?? "nil")")
                print("🔒 hasActiveRestrictions: \(profile.hasActiveRestrictions)")
                print("🔒 lockStatusDescription: \(profile.lockStatusDescription)")
            }
            print("🔒 ========================================")
            #endif
            
            await MainActor.run {
                restrictionProfiles = profiles
                isLoading = false
            }
            
        } catch {
            #if DEBUG
            print("🔒 ❌ FAILED to fetch restrictions")
            print("🔒 Error: \(error)")
            print("🔒 Error localized: \(error.localizedDescription)")
            #endif
            
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    StudentRestrictionsSheet(
        classInfo: TeacherClassInfo(
            id: "test",
            className: "Test Class",
            classUUID: "test-uuid",
            userGroupID: 118,
            userGroupName: "Test Group",
            locationId: 1
        ),
        authToken: "test-token"
    )
}
