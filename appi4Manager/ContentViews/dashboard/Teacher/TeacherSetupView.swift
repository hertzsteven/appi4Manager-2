//
//  TeacherSetupView.swift
//  appi4Manager
//
//  Placeholder view for the Setup section in the teacher sidebar.
//  Will contain class configuration and teacher settings in the future.
//

import SwiftUI

/// Placeholder view for the Setup section
struct TeacherSetupView: View {
    let activeClass: TeacherClassInfo?
    let classesWithDevices: [TeacherClassInfo]
    
    var body: some View {
        ContentUnavailableView(
            "Setup",
            systemImage: "gearshape",
            description: Text("Class configuration and settings will appear here.")
        )
        .navigationBarTitleDisplayMode(.inline)
        .teacherDashboardToolbar(
            activeClass: activeClass,
            classesWithDevices: classesWithDevices
        )
    }
}

#Preview {
    TeacherSetupView(activeClass: nil, classesWithDevices: [])
}
