//
//  SelectableStudentCard.swift
//  appi4Manager
//
//  Wrapper that adds selection overlay to StudentProfileCard when in selection mode.
//

import SwiftUI

/// Wraps a StudentProfileCard and adds selection behavior when in selection mode.
struct DashboardSelectableStudentCard: View {
    let student: Student
    let timeslot: TimeOfDay
    let dayString: String
    let dataProvider: StudentAppProfileDataProvider
    let classDevices: [TheDevice]
    let dashboardMode: DashboardMode
    let locationId: Int
    let activeSession: ActiveSession?
    
    /// Whether selection mode is active
    let isSelectionMode: Bool
    
    /// Whether this student is currently selected
    let isSelected: Bool
    
    /// Called when card is tapped in selection mode
    let onSelect: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Always use the full StudentProfileCard content
            if isSelectionMode {
                // In selection mode, show the card but intercept taps with overlay
                StudentProfileCard(
                    student: student,
                    timeslot: timeslot,
                    dayString: dayString,
                    dataProvider: dataProvider,
                    classDevices: classDevices,
                    dashboardMode: dashboardMode,
                    locationId: locationId,
                    activeSession: activeSession
                )
                .overlay {
                    // Invisible overlay to capture taps for selection
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture {
                            onSelect()
                        }
                }
            } else {
                // Normal mode - use the original card with navigation
                StudentProfileCard(
                    student: student,
                    timeslot: timeslot,
                    dayString: dayString,
                    dataProvider: dataProvider,
                    classDevices: classDevices,
                    dashboardMode: dashboardMode,
                    locationId: locationId,
                    activeSession: activeSession
                )
            }
            
            // Selection checkmark overlay
            if isSelectionMode {
                Circle()
                    .fill(isSelected ? Color.accentColor : Color(.systemGray4))
                    .frame(width: 26, height: 26)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(8)
            }
        }
        .overlay {
            // Blue border when selected
            if isSelectionMode && isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 3)
            }
        }
    }
}
