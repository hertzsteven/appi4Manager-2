//
//  ClassSelectorSheet.swift
//  appi4Manager
//
//  Sheet for selecting which class to work with when a teacher has multiple classes.
//

import SwiftUI

// MARK: - Class Selector Sheet

struct ClassSelectorSheet: View {
    let classes: [TeacherClassInfo]
    @Binding var selectedClass: TeacherClassInfo?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(classes) { classInfo in
                    Button {
                        selectedClass = classInfo
                        isPresented = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(classInfo.className)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                HStack(spacing: 12) {
                                    // Filter out dummy students (lastName == classUUID)
                                    let realStudentCount = classInfo.students.filter { $0.lastName != classInfo.classUUID }.count
                                    Label("\(realStudentCount) students", systemImage: "person.2.fill")
                                    Label("\(classInfo.devices.count) devices", systemImage: "ipad.landscape")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedClass?.id == classInfo.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title2)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Switch Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
