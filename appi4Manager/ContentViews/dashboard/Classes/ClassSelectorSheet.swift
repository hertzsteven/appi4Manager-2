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
    
    // MARK: - Helper Methods
    
    /// Checks if a class has devices assigned
    private func hasDevices(_ classInfo: TeacherClassInfo) -> Bool {
        !classInfo.devices.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(classes) { classInfo in
                    let isDisabled = !hasDevices(classInfo)
                    
                    Button {
                        selectedClass = classInfo
                        isPresented = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(classInfo.className)
                                    .font(.headline)
                                    .foregroundStyle(isDisabled ? .secondary : .primary)
                                HStack(spacing: 12) {
                                    // Filter out dummy students (lastName == classUUID)
                                    let realStudentCount = classInfo.students.filter { $0.lastName != classInfo.classUUID }.count
                                    Label("\(realStudentCount) students", systemImage: "person.2.fill")
                                    Label("\(classInfo.devices.count) devices", systemImage: "ipad.landscape")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                
                                // Show reason why class is disabled
                                if isDisabled {
                                    Label("No device assigned", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            Spacer()
                            if selectedClass?.id == classInfo.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                                    .font(.title2)
                            }
                        }
                        .contentShape(Rectangle())
                        .opacity(isDisabled ? 0.6 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
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
