//
//  TeacherCalendarView.swift
//  appi4Manager
//
//  Calendar/Planning view accessed from the sidebar.
//

import SwiftUI

/// View for calendar and planning features from the sidebar.
struct TeacherCalendarView: View {
    var body: some View {
        ContentUnavailableView(
            "Calendar",
            systemImage: "calendar",
            description: Text("Calendar and planning features coming soon.")
        )
        .navigationTitle("Calendar")
    }
}

#Preview {
    NavigationStack {
        TeacherCalendarView()
    }
}
