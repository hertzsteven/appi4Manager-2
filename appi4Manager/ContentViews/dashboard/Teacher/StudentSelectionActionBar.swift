//
//  StudentSelectionActionBar.swift
//  appi4Manager
//
//  Stationary bottom action bar for bulk operations on selected students.
//  Appears when in selection mode with buttons for Set App, Lock, Unlock, Activity.
//

import SwiftUI

/// Stationary action bar for bulk operations on selected students.
struct StudentSelectionActionBar: View {
    /// Number of currently selected students
    let selectedCount: Int
    
    /// Callbacks for each action
    let onSetApp: () -> Void
    let onLock: () -> Void
    let onUnlock: () -> Void
    let onActivity: () -> Void
    
    /// Whether actions are enabled (at least one student selected)
    private var isEnabled: Bool {
        selectedCount > 0
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ActionButton(
                title: "Set App",
                systemImage: "square.grid.2x2",
                isEnabled: isEnabled,
                action: onSetApp
            )
            
            ActionButton(
                title: "Lock",
                systemImage: "lock",
                isEnabled: isEnabled,
                action: onLock
            )
            
            ActionButton(
                title: "Unlock",
                systemImage: "lock.open",
                isEnabled: isEnabled,
                action: onUnlock
            )
            
            ActionButton(
                title: "Activity",
                systemImage: "chart.bar",
                isEnabled: isEnabled,
                action: onActivity
            )
        }
        .frame(height: 72)
        .background(.background)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

/// Individual action button for the action bar
private struct ActionButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .contentTransition(.symbolEffect(.replace))
                
                Text(title)
                    .font(.caption)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isEnabled ? Color.brandIndigo : .secondary.opacity(0.3))
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        StudentSelectionActionBar(
            selectedCount: 3,
            onSetApp: {},
            onLock: {},
            onUnlock: {},
            onActivity: {}
        )
    }
}
