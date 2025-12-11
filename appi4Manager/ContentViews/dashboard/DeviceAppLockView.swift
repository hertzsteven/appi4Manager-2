//
//  DeviceAppLockView.swift
//  appi4Manager
//
//  View for selecting an app to lock a single device into
//

import SwiftUI

/// View for selecting an app to lock a device into, or unlocking the device
struct DeviceAppLockView: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    let device: TheDevice
    
    @State private var apps: [Appx] = []
    @State private var isLoadingApps: Bool = true
    @State private var isLocking: Bool = false
    @State private var isUnlocking: Bool = false
    @State private var errorMessage: String?
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showOwnerWarning: Bool = false
    
    /// Check if device has a valid owner for locking
    private var hasOwner: Bool {
        device.owner != nil
    }
    
    /// Get the student ID from the device owner
    private var studentId: String? {
        guard let owner = device.owner else { return nil }
        return String(owner.id)
    }
    
    /// Determines the ring color based on the device name
    private var ringColor: Color {
        let lowercasedName = device.name.lowercased()
        if lowercasedName.contains("blue") {
            return .blue
        } else if lowercasedName.contains("silver") || lowercasedName.contains("gray") || lowercasedName.contains("grey") {
            return Color(white: 0.6)
        } else if lowercasedName.contains("gold") {
            return Color.yellow
        } else if lowercasedName.contains("pink") || lowercasedName.contains("rose") {
            return .pink
        } else if lowercasedName.contains("purple") {
            return .purple
        } else if lowercasedName.contains("green") {
            return .green
        } else if lowercasedName.contains("red") {
            return .red
        } else if lowercasedName.contains("orange") {
            return .orange
        } else {
            return .gray
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with device info and unlock button
                deviceHeader
                
                // App list or loading/error state
                if isLoadingApps {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if apps.isEmpty {
                    emptyAppsView
                } else {
                    appListView
                }
            }
            
            // Loading overlay for lock/unlock operations
            if isLocking || isUnlocking {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text(isUnlocking ? "Unlocking device..." : "Locking device to app...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(40)
                .background(Color.gray.opacity(0.9))
                .cornerRadius(16)
            }
        }
        .navigationTitle("Lock to App")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Owner Required", isPresented: $showOwnerWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This device has no owner assigned. Please assign an owner in the MDM before managing app locks.")
        }
        .task {
            await loadApps()
        }
    }
    
    // MARK: - Device Header
    
    private var deviceHeader: some View {
        HStack(spacing: 16) {
            // Device icon with colored ring
            ZStack {
                Circle()
                    .stroke(ringColor, lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "ipad.landscape")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Owner info
                if let owner = device.owner {
                    Text("Owner: \(owner.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text("No owner assigned")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Unlock button
            Button {
                if hasOwner {
                    Task {
                        await unlockDevice()
                    }
                } else {
                    showOwnerWarning = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lock.open.fill")
                        .font(.subheadline)
                    Text("Unlock")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(8)
            }
            .disabled(isLocking || isUnlocking || !hasOwner)
            .opacity((isLocking || isUnlocking || !hasOwner) ? 0.5 : 1.0)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading apps...")
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Error Loading Apps")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await loadApps()
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
    
    // MARK: - Empty Apps View
    
    private var emptyAppsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "app.dashed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Apps Available")
                .font(.headline)
            
            Text("There are no apps configured in the MDM system.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
    
    // MARK: - App List View
    
    private var appListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Instructional header
                HStack(spacing: 8) {
                    Image(systemName: hasOwner ? "hand.tap.fill" : "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundColor(hasOwner ? .secondary : .orange)
                    Text(hasOwner
                        ? "Tap any app to lock the device to it"
                        : "Device has no owner - cannot lock apps")
                        .font(.subheadline)
                        .foregroundColor(hasOwner ? .secondary : .orange)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 4)
                
                // App list
                ForEach(apps) { app in
                    appRow(for: app)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - App Row
    
    private func appRow(for app: Appx) -> some View {
        Button {
            if hasOwner {
                Task {
                    await lockDeviceToApp(app)
                }
            } else {
                showOwnerWarning = true
            }
        } label: {
            HStack(spacing: 16) {
                // App icon
                AsyncImage(url: URL(string: app.icon)) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "app.fill")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(app.bundleId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isLocking || !hasOwner)
        .opacity(hasOwner ? 1.0 : 0.6)
    }
    
    // MARK: - Data Loading
    
    private func loadApps() async {
        await MainActor.run {
            isLoadingApps = true
            errorMessage = nil
        }
        
        do {
            let response: AppResponse = try await ApiManager.shared.getData(from: .getApps)
            
            await MainActor.run {
                apps = response.apps
                isLoadingApps = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoadingApps = false
            }
        }
    }
    
    // MARK: - Lock Device
    
    private func lockDeviceToApp(_ app: Appx) async {
        guard let studentId = studentId,
              let token = authManager.token else {
            await MainActor.run {
                alertTitle = "Error"
                alertMessage = "Unable to lock device. Missing owner or authentication."
                showAlert = true
            }
            return
        }
        
        await MainActor.run {
            isLocking = true
        }
        
        do {
            // First unlock any existing app lock
            let _: ClearRestrictionsResponse = try await ApiManager.shared.getData(
                from: .clearRestrictionsStudent(teachAuth: token, students: studentId)
            )
            
            // Then lock to the selected app
            let _: LockIntoAppResponse = try await ApiManager.shared.getData(
                from: .lockIntoApp(appBundleId: app.bundleId, studentID: studentId, teachAuth: token)
            )
            
            await MainActor.run {
                isLocking = false
                alertTitle = "Success"
                alertMessage = "In a few seconds, \(device.name) will be locked to \(app.name)."
                showAlert = true
            }
        } catch {
            await MainActor.run {
                isLocking = false
                alertTitle = "Error"
                alertMessage = "Failed to lock device: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    // MARK: - Unlock Device
    
    private func unlockDevice() async {
        guard let studentId = studentId,
              let token = authManager.token else {
            await MainActor.run {
                alertTitle = "Error"
                alertMessage = "Unable to unlock device. Missing owner or authentication."
                showAlert = true
            }
            return
        }
        
        await MainActor.run {
            isUnlocking = true
        }
        
        do {
            let _: ClearRestrictionsResponse = try await ApiManager.shared.getData(
                from: .clearRestrictionsStudent(teachAuth: token, students: studentId)
            )
            
            await MainActor.run {
                isUnlocking = false
                alertTitle = "Device Unlocked"
                alertMessage = "\(device.name) has been unlocked."
                showAlert = true
            }
        } catch {
            await MainActor.run {
                isUnlocking = false
                alertTitle = "Error"
                alertMessage = "Failed to unlock device: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

// MARK: - Response Models

/// Response model for clear restrictions API call
struct ClearRestrictionsResponse: Codable {
    let tasks: [ClearRestrictionTask]?
    let message: String?
    
    struct ClearRestrictionTask: Codable {
        let student: String?
        let status: String?
    }
}

/// Response model for lock into app API call
struct LockIntoAppResponse: Codable {
    let message: String?
    let tasks: [LockTask]?
    
    struct LockTask: Codable {
        let student: String?
        let status: String?
    }
}

#Preview {
    NavigationStack {
        DeviceAppLockView(device: TheDevice(
            serialNumber: "ABC123",
            locationId: 1,
            UDID: "00008120-0000000000000001",
            name: "Blue iPad",
            assetTag: "1",
            owner: Owner(id: 143, locationId: 1, name: "John Doe"),
            batteryLevel: 0.85,
            totalCapacity: 64,
            lastCheckin: "2024-01-01",
            modified: "2024-01-01",
            notes: ""
        ))
        .environment(AuthenticationManager())
    }
}
