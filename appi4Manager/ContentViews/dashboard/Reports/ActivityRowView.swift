//
//  ActivityRowView.swift
//  appi4Manager
//
//  Displays a single activity session row in the Student Activity Report.
//  Shows app icon, name, duration, time, and status.
//

import SwiftUI

/// Row component for displaying a single ObservableSession
struct ActivityRowView: View {
    let session: ObservableSession
    let deviceApps: [DeviceApp]
    
    /// The matching DeviceApp for this session's bundle ID
    private var matchingApp: DeviceApp? {
        guard let bundleId = session.appBundleId else { return nil }
        return deviceApps.first { $0.identifier == bundleId }
    }
    
    /// Display name for the app
    private var appDisplayName: String {
        if let app = matchingApp {
            return app.displayName
        }
        // Fallback: extract from bundle ID
        if let bundleId = session.appBundleId {
            let components = bundleId.split(separator: ".")
            if let last = components.last {
                return String(last).capitalized
            }
            return bundleId
        }
        return "Unknown App"
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // App Icon
            appIconView
            
            // App Info
            VStack(alignment: .leading, spacing: 4) {
                Text(appDisplayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // Time and timeslot
                HStack(spacing: 8) {
                    if let time = session.formattedTime {
                        Label(time, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("•")
                        .foregroundStyle(.tertiary)
                    
                    Text(session.timeslotDisplayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Duration and Status
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.durationString)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                statusBadge
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var appIconView: some View {
        if let app = matchingApp {
            AsyncImage(url: app.iconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(.rect(cornerRadius: 10))
                default:
                    placeholderIcon
                }
            }
        } else {
            placeholderIcon
        }
    }
    
    private var placeholderIcon: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.accentColor.opacity(0.15))
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: "app.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            )
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        if session.isCompleted {
            Label("Completed", systemImage: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.green)
        } else {
            Label("Session", systemImage: "circle.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

/// Compact version for inline display
struct ActivityRowCompactView: View {
    let session: ObservableSession
    let deviceApps: [DeviceApp]
    
    private var matchingApp: DeviceApp? {
        guard let bundleId = session.appBundleId else { return nil }
        return deviceApps.first { $0.identifier == bundleId }
    }
    
    private var appDisplayName: String {
        if let app = matchingApp {
            return app.displayName
        }
        if let bundleId = session.appBundleId {
            let components = bundleId.split(separator: ".")
            if let last = components.last {
                return String(last).capitalized
            }
            return bundleId
        }
        return "Unknown App"
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Small App Icon
            if let app = matchingApp {
                AsyncImage(url: app.iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 28, height: 28)
                            .clipShape(.rect(cornerRadius: 6))
                    default:
                        smallPlaceholderIcon
                    }
                }
            } else {
                smallPlaceholderIcon
            }
            
            Text(appDisplayName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Spacer()
            
            Text(session.durationString)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var smallPlaceholderIcon: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.accentColor.opacity(0.15))
            .frame(width: 28, height: 28)
            .overlay(
                Image(systemName: "app.fill")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            )
    }
}

// MARK: - Preview

#Preview("Activity Row") {
    let session = ObservableSession(
        studentID: 1,
        companyId: 2001128,
        locationID: 1,
        deviceUUID: "test-uuid",
        name: "John Doe",
        creationDT: Date().addingTimeInterval(-3600),
        appBundleId: "com.sesameworkshop.elmolovesabcs",
        sessionLengthMin: 20,
        timeslot: "morning",
        date: "20260129",
        mssg: "success - session completed",
        processed: true
    )
    
    return VStack(spacing: 16) {
        ActivityRowView(session: session, deviceApps: [])
            .padding(.horizontal)
        
        ActivityRowCompactView(session: session, deviceApps: [])
            .padding(.horizontal)
    }
    .background(Color(.systemGray6))
}
