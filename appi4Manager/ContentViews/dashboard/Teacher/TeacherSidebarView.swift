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
            ForEach(SidebarSection.allCases) { section in
                SidebarButton(
                    section: section,
                    isSelected: selectedSection == section
                ) {
                    selectedSection = section
                }
            }
            
            Spacer()
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
