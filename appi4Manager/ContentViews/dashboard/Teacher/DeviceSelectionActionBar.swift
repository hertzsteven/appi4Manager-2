//
//  DeviceSelectionActionBar.swift
//  appi4Manager
//
//  Stationary bottom action bar for bulk operations on selected devices.
//  Appears when in selection mode with buttons for Lock, Unlock, and Restart.
//  Modeled after StudentSelectionActionBar for visual consistency.
//

import SwiftUI

/// Stationary action bar for bulk operations on selected devices.
///
/// Displays three action buttons (Lock, Unlock, Restart) that mirror the
/// device management actions available in `MultiDeviceAppLockView`, but
/// presented inline at the bottom of the Devices screen instead of in a sheet.
struct DeviceSelectionActionBar: View {
    /// Number of currently selected devices
    let selectedCount: Int
    
    /// Callbacks for each action
    let onLock: () -> Void
    let onUnlock: () -> Void
    let onRestart: () -> Void
    
    /// Whether actions are enabled (at least one device selected)
    private var isEnabled: Bool {
        selectedCount > 0
    }
    
    var body: some View {
        HStack(spacing: 0) {
            DeviceActionButton(
                title: "Lock",
                systemImage: "lock.fill",
                isEnabled: isEnabled,
                action: onLock
            )
            
            DeviceActionButton(
                title: "Unlock",
                systemImage: "lock.open.fill",
                isEnabled: isEnabled,
                action: onUnlock
            )
            
            DeviceActionButton(
                title: "Restart",
                systemImage: "arrow.clockwise",
                isEnabled: isEnabled,
                action: onRestart
            )
        }
        .frame(height: 60)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

// MARK: - Device Action Button

/// Individual action button for the device action bar.
private struct DeviceActionButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title2)
                
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isEnabled ? .blue : .secondary.opacity(0.5))
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        DeviceSelectionActionBar(
            selectedCount: 2,
            onLock: {},
            onUnlock: {},
            onRestart: {}
        )
    }
}
