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
                section: .classroom,
                isSelected: selectedSection == .classroom
            ) {
                selectedSection = .classroom
            }
            
            // Divider separating Live Class from utility items
            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            
            // Utility items
            SidebarButton(
                section: .activity,
                isSelected: selectedSection == .activity
            ) {
                selectedSection = .activity
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
        .background(.ultraThinMaterial)
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
                    .bold()
                    .frame(height: 24)
                
                Text(section.label)
                    .font(.caption2)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? Color.brandIndigo : .secondary)
            .frame(width: 70, height: 60)
            .background {
                if isSelected {
                    ZStack {
                        // The glass/glow base
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.brandIndigo.opacity(0.2), Color.brandIndigo.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Thin glowing border
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.brandIndigo.opacity(0.5), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: Color.brandIndigo.opacity(0.25), radius: 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3), value: isSelected)
    }
}

#Preview {
    TeacherSidebarView(selectedSection: .constant(.classroom))
}
