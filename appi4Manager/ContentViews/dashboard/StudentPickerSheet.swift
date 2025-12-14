//
//  StudentPickerSheet.swift
//  appi4Manager
//
//  Sheet view for selecting a student to assign to device(s)
//

import SwiftUI

/// Sheet view for selecting a student to assign to device(s)
struct StudentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let students: [Student]
    let onSelect: (Student) -> Void
    
    @State private var searchText = ""
    
    /// Filtered students based on search text
    private var filteredStudents: [Student] {
        if searchText.isEmpty {
            return students.sorted { $0.firstName < $1.firstName }
        }
        return students.filter { student in
            student.firstName.localizedCaseInsensitiveContains(searchText) ||
            student.lastName.localizedCaseInsensitiveContains(searchText) ||
            student.name.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.firstName < $1.firstName }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if students.isEmpty {
                    ContentUnavailableView(
                        "No Students",
                        systemImage: "person.3.fill",
                        description: Text("No students available in this class.")
                    )
                } else if filteredStudents.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredStudents, id: \.id) { student in
                            Button {
                                onSelect(student)
                                dismiss()
                            } label: {
                                StudentRow(student: student)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Select Student")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search students")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Student Row

struct StudentRow: View {
    let student: Student
    
    var body: some View {
        HStack(spacing: 12) {
            // Student photo
            AsyncImage(url: student.photo) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(ProgressView().scaleEffect(0.8))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                case .failure:
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(student.firstName.prefix(1) + student.lastName.prefix(1))
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        )
                @unknown default:
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 44, height: 44)
                }
            }
            
            // Student info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(student.firstName) \(student.lastName)")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(student.username)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    StudentPickerSheet(
        students: [
            Student(
                id: 1,
                name: "John Smith",
                email: "john@school.edu",
                username: "jsmith",
                firstName: "John",
                lastName: "Smith",
                photo: URL(string: "https://via.placeholder.com/100")!
            ),
            Student(
                id: 2,
                name: "Jane Doe",
                email: "jane@school.edu",
                username: "jdoe",
                firstName: "Jane",
                lastName: "Doe",
                photo: URL(string: "https://via.placeholder.com/100")!
            ),
            Student(
                id: 3,
                name: "Bob Wilson",
                email: "bob@school.edu",
                username: "bwilson",
                firstName: "Bob",
                lastName: "Wilson",
                photo: URL(string: "https://via.placeholder.com/100")!
            )
        ],
        onSelect: { student in
            print("Selected: \(student.name)")
        }
    )
}
