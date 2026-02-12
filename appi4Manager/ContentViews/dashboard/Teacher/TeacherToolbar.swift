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
    
    /// When `true`, the class name is shown as a tappable dropdown menu for switching classes.
    /// When `false`, the class name is displayed as a static label with no interaction.
    var isClassSwitchable: Bool = false
    
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
                        HStack(spacing: 8) {
                            // Class name — interactive dropdown on Home, static label elsewhere
                            if isClassSwitchable {
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
                                    classNameCapsule(classInfo: classInfo, showChevron: classesWithDevices.count > 1)
                                }
                                .disabled(classesWithDevices.count <= 1)
                            } else {
                                classNameCapsule(classInfo: classInfo, showChevron: false)
                            }
                            
                            // Stats pills — separate from class capsule so they never get compressed
                            HStack(spacing: 4) {
                                Image(systemName: "person.2")
                                Text("\(filteredStudentCount(for: classInfo))")
                            }
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(.capsule)
                            .fixedSize()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "ipad")
                                Text("\(classInfo.devices.count)")
                            }
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(.capsule)
                            .fixedSize()
                        }
                    }
                }
                
                // MARK: - Trailing: Greeting & Profile
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Greeting
                        Text("Hi \(authManager.authenticatedUser?.firstName ?? "Teacher")")
                            .font(.subheadline)
                            .bold()
                            .padding(.leading , 8)
                        
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
    
    /// Capsule displaying the class name, optionally with a dropdown chevron.
    private func classNameCapsule(classInfo: TeacherClassInfo, showChevron: Bool) -> some View {
        HStack(spacing: 4) {
            Text(classInfo.className)
                .font(.headline)
                .foregroundStyle(.primary)
            
            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .clipShape(.capsule)
    }
    
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
    ///
    /// - Parameter isClassSwitchable: When `true`, the class name acts as a dropdown to switch classes.
    ///   Defaults to `false`, showing the class name as a static label.
    func teacherDashboardToolbar(
        activeClass: TeacherClassInfo?,
        classesWithDevices: [TeacherClassInfo],
        isClassSwitchable: Bool = false,
        isSelectionMode: Binding<Bool>? = nil
    ) -> some View {
        self.modifier(TeacherToolbarModifier(
            activeClass: activeClass,
            classesWithDevices: classesWithDevices,
            isClassSwitchable: isClassSwitchable,
            isSelectionMode: isSelectionMode
        ))
    }
}
