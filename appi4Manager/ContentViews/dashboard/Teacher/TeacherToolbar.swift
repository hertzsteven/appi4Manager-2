//
//  TeacherToolbar.swift
//  appi4Manager
//
//  A reusable toolbar component for teacher dashboard views to ensure visual consistency.
//  Includes class switcher, student/device stats, and teacher profile information.
//

import SwiftUI

/// A view modifier that applies the standard teacher dashboard toolbar.
struct TeacherToolbarModifier: ViewModifier {
    @Environment(AuthenticationManager.self) private var authManager
    @EnvironmentObject var teacherItems: TeacherItems
    
    let activeClass: TeacherClassInfo?
    let classesWithDevices: [TeacherClassInfo]
    
    /// Optional binding for selection mode (e.g. for bulk actions in Live Class)
    var isSelectionMode: Binding<Bool>? = nil
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                // MARK: - Leading: Select Button (Optional)
                if let isSelectionMode = isSelectionMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation(.spring()) {
                                isSelectionMode.wrappedValue.toggle()
                            }
                        } label: {
                            Text(isSelectionMode.wrappedValue ? "Cancel" : "Select")
                        }
                        .disabled(activeClass == nil)
                    }
                }
                
                // MARK: - Center: Class Switcher & Stats
                ToolbarItem(placement: .principal) {
                    if let classInfo = activeClass {
                        HStack(spacing: 12) {
                            // Class name with dropdown
                            Menu {
                                ForEach(classesWithDevices) { cls in
                                    Button {
                                        teacherItems.selectedClass = cls
                                    } label: {
                                        HStack {
                                            Text(cls.className)
                                            if cls.id == classInfo.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(classInfo.className)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    if classesWithDevices.count > 1 {
                                        Image(systemName: "chevron.down")
                                            .font(.caption2)
                                            .bold()
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .disabled(classesWithDevices.count <= 1)
                            
                            // Stats grouped with class (student + device counts in subtle pills)
                            HStack(spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2")
                                    Text("\(filteredStudentCount(for: classInfo))")
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(.systemGray5))
                                .clipShape(.capsule)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "ipad")
                                    Text("\(classInfo.devices.count)")
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(.systemGray5))
                                .clipShape(.capsule)
                            }
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 12)
                        .padding(.trailing, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .clipShape(.capsule)
                    }
                }
                
                // MARK: - Trailing: Greeting & Profile
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Greeting
                        Text("Hi \(authManager.authenticatedUser?.firstName ?? "Teacher")")
                            .font(.subheadline)
                            .bold()
                        
                        // Profile Initials Circle
                        profileInitialsCircle
                        
                        // Settings Gear
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape")
                                .bold()
                        }
                    }
                }
            }
    }
    
    // MARK: - Helper Views
    
    private var profileInitialsCircle: some View {
        let name = authManager.authenticatedUser?.firstName ?? "Teacher"
        let initial = String(name.prefix(1)).uppercased()
        
        return ZStack {
            Circle()
                .fill(Color.brandIndigo.opacity(0.15))
                .frame(width: 32, height: 32)
            
            Text(initial)
                .font(.subheadline)
                .bold()
                .foregroundStyle(Color.brandIndigo)
        }
    }
    
    private func filteredStudentCount(for classInfo: TeacherClassInfo) -> Int {
        classInfo.students.filter { $0.lastName != classInfo.classUUID }.count
    }
}

extension View {
    /// Applies the standard teacher dashboard toolbar with class switching and profile info.
    func teacherDashboardToolbar(
        activeClass: TeacherClassInfo?,
        classesWithDevices: [TeacherClassInfo],
        isSelectionMode: Binding<Bool>? = nil
    ) -> some View {
        self.modifier(TeacherToolbarModifier(
            activeClass: activeClass,
            classesWithDevices: classesWithDevices,
            isSelectionMode: isSelectionMode
        ))
    }
}
