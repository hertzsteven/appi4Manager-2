//
//  StudentSelectionActionBar.swift
//  appi4Manager
//
//  Stationary bottom action bar for bulk operations on selected students.
//  Appears when in selection mode with buttons for Set App, Lock, Unlock, Re-login, Activity.
//

import SwiftUI

/// Stationary action bar for bulk operations on selected students.
struct StudentSelectionActionBar: View {
    /// Number of currently selected students
    let selectedCount: Int
    
    /// Current re-login state of the first qualifying selected student.
    /// - `nil` = no selected student has a session (button disabled)
    /// - `false` = re-login not yet allowed → button shows "Re-login"
    /// - `true` = re-login already allowed → button shows "Stop Re-login"
    let reloginAllowed: Bool?
    
    /// Callbacks for each action
    let onSetApp: () -> Void
    let onLock: () -> Void
    let onUnlock: () -> Void
    let onRelogin: () -> Void
    let onActivity: () -> Void
    
    /// Whether actions are enabled (at least one student selected)
    private var isEnabled: Bool {
        selectedCount > 0
    }
    
    /// Whether the re-login button is enabled (at least one qualifying student)
    private var isReloginEnabled: Bool {
        isEnabled && reloginAllowed != nil
    }
    
    /// Adaptive label for the re-login button based on current state
    private var reloginTitle: String {
        reloginAllowed == true ? "Stop Re-login" : "Re-login"
    }
    
    /// Adaptive icon for the re-login button based on current state
    private var reloginIcon: String {
        reloginAllowed == true ? "xmark.circle" : "arrow.counterclockwise"
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
                title: reloginTitle,
                systemImage: reloginIcon,
                isEnabled: isReloginEnabled,
                action: onRelogin
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
            reloginAllowed: false,
            onSetApp: {},
            onLock: {},
            onUnlock: {},
            onRelogin: {},
            onActivity: {}
        )
    }
}
