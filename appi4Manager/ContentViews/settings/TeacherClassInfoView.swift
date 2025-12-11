//
//  TeacherClassInfoView.swift
//  appi4Manager
//
//  Displays class and group information for authenticated teachers
//

import SwiftUI

/// Represents a class that the teacher teaches with its associated group info
struct TeacherClassInfo: Identifiable {
    let id: String  // Using class UUID as id
    let className: String
    let classUUID: String
    let userGroupID: Int
    let userGroupName: String?
    var students: [Student] = []
    var devices: [TheDevice] = []
}

struct TeacherClassInfoView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @EnvironmentObject var teacherItems: TeacherItems
    
    @State private var isLoading = false
    @State private var teacherClasses: [TeacherClassInfo] = []
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            // MARK: - Teacher Info Section
            Section {
                teacherInfoRow
            } header: {
                Text("Authenticated Teacher")
            }
            
            // MARK: - Classes Section
            Section {
                if isLoading {
                    loadingRow
                } else if let error = errorMessage {
                    errorRow(message: error)
                } else if teacherClasses.isEmpty {
                    noClassesRow
                } else {
                    ForEach(teacherClasses) { classInfo in
                        classInfoSection(classInfo)
                    }
                }
            } header: {
                Text("Classes You Teach")
            } footer: {
                if !teacherClasses.isEmpty {
                    Text("The class UUID and Group ID are used for API integration.")
                }
            }
            
            // MARK: - Refresh Button
            Section {
                refreshButton
            }
        }
        .navigationTitle("Teacher Class Info")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadTeacherClasses()
        }
    }
    
    // MARK: - Teacher Info Row
    
    private var teacherInfoRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 36))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(authManager.authenticatedUser?.name ?? "Teacher")
                    .font(.headline)
                
                Text(authManager.authenticatedUser?.username ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Loading Row
    
    private var loadingRow: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }
    
    // MARK: - Error Row
    
    private func errorRow(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - No Classes Row
    
    private var noClassesRow: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            Text("No classes assigned to this teacher.")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Class Info Section
    
    @ViewBuilder
    private func classInfoSection(_ classInfo: TeacherClassInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Class Name Header
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.accentColor)
                Text(classInfo.className)
                    .font(.headline)
            }
            
            Divider()
            
            // Class UUID
            copyableInfoRow(
                label: "Class UUID",
                value: classInfo.classUUID
            )
            
            // User Group ID
            copyableInfoRow(
                label: "Group ID",
                value: String(classInfo.userGroupID)
            )
            
            // User Group Name (if available)
            if let groupName = classInfo.userGroupName {
                infoRow(
                    label: "Group Name",
                    value: groupName
                )
            }
            
            Divider()
            
            // MARK: - Students Section
            DisclosureGroup {
                if classInfo.students.isEmpty {
                    Text("No students in this class")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(classInfo.students, id: \.id) { student in
                        studentRow(student)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                    Text("Students")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(classInfo.students.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // MARK: - Devices Section
            DisclosureGroup {
                if classInfo.devices.isEmpty {
                    Text("No devices assigned to this class")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(classInfo.devices, id: \.UDID) { device in
                        deviceRow(device)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "ipad.landscape")
                        .foregroundColor(.green)
                    Text("Devices")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(classInfo.devices.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Student Row
    
    private func studentRow(_ student: Student) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: student.photo) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 36, height: 36)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.gray)
                @unknown default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.gray)
                }
            }
            
            Text(student.name)
                .font(.subheadline)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Device Row
    
    private func deviceRow(_ device: TheDevice) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "ipad")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(device.serialNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Views
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .fontWeight(.medium)
                .lineLimit(1)
            Spacer()
        }
        .font(.subheadline)
    }
    
    private func copyableInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .fontWeight(.medium)
                .lineLimit(1)
                .textSelection(.enabled)
            Spacer()
            Button {
                UIPasteboard.general.string = value
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
    }
    
    // MARK: - Refresh Button
    
    private var refreshButton: some View {
        Button {
            Task {
                await loadTeacherClasses()
            }
        } label: {
            HStack {
                Spacer()
                Label("Refresh Data", systemImage: "arrow.clockwise")
                Spacer()
            }
        }
        .disabled(isLoading)
    }
    
    // MARK: - Data Loading
    
    private func loadTeacherClasses() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            teacherClasses = []
        }
        
        guard let teacherId = authManager.authenticatedUser?.id else {
            await MainActor.run {
                errorMessage = "No authenticated teacher found."
                isLoading = false
            }
            return
        }
        
        do {
            // 1. Fetch the teacher's user details to get their teacherGroups
            let userDetailResponse: UserDetailResponse = try await ApiManager.shared.getData(
                from: .getaUser(id: teacherId)
            )
            let teacherGroupIds = userDetailResponse.user.teacherGroups
            
            #if DEBUG
            print("📚 Teacher's teacherGroups: \(teacherGroupIds)")
            #endif
            
            // 2. Fetch all school classes
            let classesResponse: SchoolClassResponse = try await ApiManager.shared.getData(
                from: .getSchoolClasses
            )
            
            // 3. Filter classes where userGroupId is in the teacher's teacherGroups
            let matchingClasses = classesResponse.classes.filter { schoolClass in
                teacherGroupIds.contains(schoolClass.userGroupId)
            }
            
            #if DEBUG
            print("📚 Found \(matchingClasses.count) classes for this teacher")
            #endif
            
            // 4. Fetch all groups to get group names
            let groupsResponse: MDMGroupsResponse = try await ApiManager.shared.getData(
                from: .getGroups
            )
            
            // 5. Build the TeacherClassInfo array with students and devices
            var classInfos: [TeacherClassInfo] = []
            
            for schoolClass in matchingClasses {
                let groupName = groupsResponse.groups.first { $0.id == schoolClass.userGroupId }?.name
                
                // 5a. Fetch students for this class using the class UUID
                var students: [Student] = []
                do {
                    let classDetailResponse: ClassDetailResponse = try await ApiManager.shared.getData(
                        from: .getStudents(uuid: schoolClass.uuid)
                    )
                    students = classDetailResponse.class.students
                    #if DEBUG
                    print("📚 Fetched \(students.count) students for class \(schoolClass.name)")
                    #endif
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to fetch students for class \(schoolClass.name): \(error)")
                    #endif
                }
                
                // 5b. Fetch devices for this class using the userGroupId as asset tag filter
                var devices: [TheDevice] = []
                do {
                    let deviceResponse: DeviceListResponse = try await ApiManager.shared.getData(
                        from: .getDevices(assettag: String(schoolClass.userGroupId))
                    )
                    devices = deviceResponse.devices
                    #if DEBUG
                    print("📚 Fetched \(devices.count) devices for class \(schoolClass.name) with asset tag \(schoolClass.userGroupId)")
                    #endif
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to fetch devices for class \(schoolClass.name): \(error)")
                    #endif
                }
                
                var info = TeacherClassInfo(
                    id: schoolClass.uuid,
                    className: schoolClass.name,
                    classUUID: schoolClass.uuid,
                    userGroupID: schoolClass.userGroupId,
                    userGroupName: groupName
                )
                info.students = students
                info.devices = devices
                
                classInfos.append(info)
            }
            
            // Sort by class name
            classInfos.sort { $0.className < $1.className }
            
            await MainActor.run {
                teacherClasses = classInfos
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load class info: \(error.localizedDescription)"
                isLoading = false
            }
            #if DEBUG
            print("❌ Error loading teacher classes: \(error)")
            #endif
        }
    }
}

#Preview {
    NavigationStack {
        TeacherClassInfoView()
            .environment(AuthenticationManager())
            .environmentObject(TeacherItems())
    }
}
