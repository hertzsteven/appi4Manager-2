//
//  TeacherSidebarView.swift
//  appi4Manager
//
//  A compact vertical sidebar for navigating between teacher dashboard sections.
//  Displays icons with labels and highlights the currently selected section.
//

import SwiftUI

/// A vertical sidebar displaying navigation icons for the teacher dashboard.
struct TeacherSidebarView: View {
    /// The currently selected sidebar section
    @Binding var selectedSection: SidebarSection
    
    var body: some View {
        VStack(spacing: 8) {
            // Primary action at top
            SidebarButton(
                section: .liveClass,
                isSelected: selectedSection == .liveClass
            ) {
                selectedSection = .liveClass
            }
            
            // Divider separating Live Class from utility items
            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            
            // Utility items
            SidebarButton(
                section: .reports,
                isSelected: selectedSection == .reports
            ) {
                selectedSection = .reports
            }
            
            SidebarButton(
                section: .students,
                isSelected: selectedSection == .students
            ) {
                selectedSection = .students
            }
            
            SidebarButton(
                section: .devices,
                isSelected: selectedSection == .devices
            ) {
                selectedSection = .devices
            }
            
            SidebarButton(
                section: .calendar,
                isSelected: selectedSection == .calendar
            ) {
                selectedSection = .calendar
            }
            
            Spacer()
            
            // Setup pinned to bottom
            SidebarButton(
                section: .setup,
                isSelected: selectedSection == .setup
            ) {
                selectedSection = .setup
            }
        }
        .padding(.vertical)
        .frame(width: 80)
        .background(Color(.systemGray6))
    }
}

/// Individual button for a sidebar section
private struct SidebarButton: View {
    let section: SidebarSection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: section.iconName)
                    .font(.title2)
                    .frame(height: 24)
                
                Text(section.label)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            .frame(width: 70, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TeacherSidebarView(selectedSection: .constant(.liveClass))
}
