//
//  TimeslotRowView.swift
//  appi4Manager
//
//  Reusable row component for displaying a single timeslot's app configuration.
//  Shows timeslot name, assigned apps, session length slider, and change button.
//

import SwiftUI

// MARK: - TimeslotRowView

/// A row displaying one timeslot (AM, PM, or Home) with its app configuration.
///
/// **Features:**
/// - Timeslot label with time range
/// - App icon(s) with "Change" button for quick reassignment
/// - Inline session length slider for direct editing
/// - Saves changes immediately via dataProvider
struct TimeslotRowView: View {
    
    // MARK: - Properties
    
    let studentId: Int
    let timeslot: TimeOfDay
    let dayString: String
    let dataProvider: StudentAppProfileDataProvider
    let deviceApps: [DeviceApp]
    
    /// Callback when the "Change" button is tapped
    var onChangeAppsTapped: () -> Void = {}
    
    @State private var sessionLength: Double = 30
    @State private var apps: [DeviceApp] = []
    @State private var isSaving = false
    @State private var showAppsListSheet = false
    
    // MARK: - Computed Properties
    
    private var session: Session? {
        dataProvider.getSession(for: studentId, day: dayString, timeslot: timeslot)
    }
    
    private var timeslotLabel: String {
        switch timeslot {
        case .am: return "AM"
        case .pm: return "PM"
        case .home: return "Home"
        }
    }
    
    private var timeRangeLabel: String {
        switch timeslot {
        case .am: return "9:00-11:59"
        case .pm: return "12:00-4:59"
        case .home: return "5:00+"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Timeslot name and time range
            HStack {
                Text(timeslotLabel)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("(\(timeRangeLabel))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // App row with Change button
            HStack(spacing: 12) {
                // App icons
                if apps.isEmpty {
                    Image(systemName: "app.dashed")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 40, height: 40)
                    
                    Text("No apps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    // Show first app icon
                    AsyncImage(url: apps.first?.iconURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            Image(systemName: "app.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                                .frame(width: 40, height: 40)
                        }
                    }
                    
                    // App name or count with View button
                    if apps.count == 1 {
                        Text(apps.first?.displayName ?? "App")
                            .font(.subheadline)
                            .lineLimit(1)
                    } else {
                        Button {
                            showAppsListSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("\(apps.count) apps")
                                    .font(.subheadline)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                // Change button
                Button {
                    onChangeAppsTapped()
                } label: {
                    Text("Change")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            // Session length slider
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                
                Text("\(Int(sessionLength)) min")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .frame(width: 55, alignment: .leading)
                    .contentTransition(.numericText())
                
                Slider(value: $sessionLength, in: 5...60, step: 5)
                    .tint(.orange)
                    .onChange(of: sessionLength) { _, newValue in
                        saveSessionLength(newValue)
                    }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .onAppear {
            loadData()
        }
        .onChange(of: dayString) { _, _ in
            loadData()
        }
        .onChange(of: timeslot) { _, _ in
            loadData()
        }
        .onChange(of: dataProvider.updateCounter) { _, _ in
            // Reload when any session is saved (triggers from other TimeslotRowViews)
            loadData()
        }
        .sensoryFeedback(.selection, trigger: sessionLength)
        .sheet(isPresented: $showAppsListSheet) {
            NavigationStack {
                List(apps) { app in
                    HStack(spacing: 12) {
                        AsyncImage(url: app.iconURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            default:
                                Image(systemName: "app.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text(app.displayName)
                                .font(.body)
                            if let vendor = app.vendor, !vendor.isEmpty {
                                Text(vendor)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("\(timeslotLabel) Apps")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showAppsListSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        if let session = session {
            sessionLength = session.sessionLength
            // Match bundle IDs to device apps
            apps = session.apps.compactMap { bundleId in
                deviceApps.first { $0.identifier == bundleId }
            }
        } else {
            sessionLength = 30
            apps = []
        }
    }
    
    // MARK: - Saving
    
    private func saveSessionLength(_ newLength: Double) {
        guard !isSaving else { return }
        isSaving = true
        
        Task {
            // Get current apps or empty array
            let currentApps = session?.apps ?? []
            
            // Save updated session using the correct method name
            do {
                try await dataProvider.updateAndSaveSession(
                    for: studentId,
                    day: dayString,
                    timeslot: timeslot,
                    apps: currentApps,
                    sessionLength: newLength
                )
            } catch {
                #if DEBUG
                print("❌ Failed to save session: \(error)")
                #endif
            }
            
            await MainActor.run {
                isSaving = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TimeslotRowView(
        studentId: 1,
        timeslot: .am,
        dayString: "Mon",
        dataProvider: StudentAppProfileDataProvider(),
        deviceApps: []
    )
    .padding()
    .background(Color(.systemGray6))
}
