//
//  MultiDeviceAppLockView.swift
//  appi4Manager
//
//  View for selecting an app to lock multiple devices into
//

import SwiftUI

/// View for selecting an app to lock multiple devices into, or unlocking all devices
struct MultiDeviceAppLockView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    
    let devices: [TheDevice]
    
    @State private var apps: [Appx] = []
    @State private var isLoadingApps: Bool = true
    @State private var isLocking: Bool = false
    @State private var isUnlocking: Bool = false
    @State private var errorMessage: String?
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var lockingProgress: String = ""
    
    /// Devices that have valid owners
    private var devicesWithOwners: [TheDevice] {
        devices.filter { $0.owner != nil }
    }
    
    /// Devices without owners (can't be locked)
    private var devicesWithoutOwners: [TheDevice] {
        devices.filter { $0.owner == nil }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with device count and unlock button
                    devicesHeader
                    
                    // Warning for devices without owners
                    if !devicesWithoutOwners.isEmpty {
                        ownerWarningBanner
                    }
                    
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
                        Text(isUnlocking ? "Unlocking devices..." : "Locking devices...")
                            .font(.headline)
                            .foregroundColor(.white)
                        if !lockingProgress.isEmpty {
                            Text(lockingProgress)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(40)
                    .background(Color.gray.opacity(0.9))
                    .cornerRadius(16)
                }
            }
            .navigationTitle("Lock \(devices.count) Device\(devices.count == 1 ? "" : "s")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertTitle == "Success" || alertTitle.contains("Unlocked") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .task {
                await loadApps()
            }
        }
    }
    
    // MARK: - Devices Header
    
    private var devicesHeader: some View {
        HStack(spacing: 16) {
            // Device count indicator
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 50, height: 50)
                
                Text("\(devicesWithOwners.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(devicesWithOwners.count) iPad\(devicesWithOwners.count == 1 ? "" : "s") selected")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if devicesWithOwners.count < devices.count {
                    Text("\(devicesWithoutOwners.count) device\(devicesWithoutOwners.count == 1 ? "" : "s") skipped (no owner)")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("All devices ready to lock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Unlock all button
            Button {
                Task {
                    await unlockAllDevices()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lock.open.fill")
                        .font(.subheadline)
                    Text("Unlock All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(8)
            }
            .disabled(isLocking || isUnlocking || devicesWithOwners.isEmpty)
            .opacity((isLocking || isUnlocking || devicesWithOwners.isEmpty) ? 0.5 : 1.0)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Owner Warning Banner
    
    private var ownerWarningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(devicesWithoutOwners.count) device\(devicesWithoutOwners.count == 1 ? " has" : "s have") no owner")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(devicesWithoutOwners.map { $0.name }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
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
                    Image(systemName: devicesWithOwners.isEmpty ? "exclamationmark.triangle.fill" : "hand.tap.fill")
                        .font(.subheadline)
                        .foregroundColor(devicesWithOwners.isEmpty ? .orange : .secondary)
                    Text(devicesWithOwners.isEmpty
                        ? "No devices with owners to lock"
                        : "Tap any app to lock all \(devicesWithOwners.count) device\(devicesWithOwners.count == 1 ? "" : "s") to it")
                        .font(.subheadline)
                        .foregroundColor(devicesWithOwners.isEmpty ? .orange : .secondary)
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
            Task {
                await lockAllDevicesToApp(app)
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
        .disabled(isLocking || devicesWithOwners.isEmpty)
        .opacity(devicesWithOwners.isEmpty ? 0.6 : 1.0)
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
    
    // MARK: - Lock All Devices
    
    private func lockAllDevicesToApp(_ app: Appx) async {
        guard let token = authManager.token else {
            await MainActor.run {
                alertTitle = "Error"
                alertMessage = "No authentication token available."
                showAlert = true
            }
            return
        }
        
        guard !devicesWithOwners.isEmpty else {
            await MainActor.run {
                alertTitle = "Error"
                alertMessage = "No devices with owners to lock."
                showAlert = true
            }
            return
        }
        
        await MainActor.run {
            isLocking = true
            lockingProgress = ""
        }
        
        var successCount = 0
        var failCount = 0
        
        for (index, device) in devicesWithOwners.enumerated() {
            guard let studentId = device.owner?.id else { continue }
            
            await MainActor.run {
                lockingProgress = "Processing \(index + 1) of \(devicesWithOwners.count)..."
            }
            
            do {
                // First unlock any existing app lock
                let _: ClearRestrictionsResponse = try await ApiManager.shared.getData(
                    from: .clearRestrictionsStudent(teachAuth: token, students: String(studentId))
                )
                
                // Then lock to the selected app
                let _: LockIntoAppResponse = try await ApiManager.shared.getData(
                    from: .lockIntoApp(appBundleId: app.bundleId, studentID: String(studentId), teachAuth: token)
                )
                
                successCount += 1
            } catch {
                failCount += 1
                #if DEBUG
                print("Failed to lock device \(device.name): \(error)")
                #endif
            }
        }
        
        await MainActor.run {
            isLocking = false
            lockingProgress = ""
            
            if failCount == 0 {
                alertTitle = "Success"
                alertMessage = "All \(successCount) device\(successCount == 1 ? "" : "s") will be locked to \(app.name) in a few seconds."
            } else if successCount == 0 {
                alertTitle = "Error"
                alertMessage = "Failed to lock all devices. Please try again."
            } else {
                alertTitle = "Partial Success"
                alertMessage = "\(successCount) device\(successCount == 1 ? "" : "s") locked to \(app.name). \(failCount) device\(failCount == 1 ? "" : "s") failed."
            }
            showAlert = true
        }
    }
    
    // MARK: - Unlock All Devices
    
    private func unlockAllDevices() async {
        guard let token = authManager.token else {
            await MainActor.run {
                alertTitle = "Error"
                alertMessage = "No authentication token available."
                showAlert = true
            }
            return
        }
        
        guard !devicesWithOwners.isEmpty else {
            await MainActor.run {
                alertTitle = "Error"
                alertMessage = "No devices with owners to unlock."
                showAlert = true
            }
            return
        }
        
        await MainActor.run {
            isUnlocking = true
            lockingProgress = ""
        }
        
        var successCount = 0
        var failCount = 0
        
        for (index, device) in devicesWithOwners.enumerated() {
            guard let studentId = device.owner?.id else { continue }
            
            await MainActor.run {
                lockingProgress = "Processing \(index + 1) of \(devicesWithOwners.count)..."
            }
            
            do {
                let _: ClearRestrictionsResponse = try await ApiManager.shared.getData(
                    from: .clearRestrictionsStudent(teachAuth: token, students: String(studentId))
                )
                
                successCount += 1
            } catch {
                failCount += 1
                #if DEBUG
                print("Failed to unlock device \(device.name): \(error)")
                #endif
            }
        }
        
        await MainActor.run {
            isUnlocking = false
            lockingProgress = ""
            
            if failCount == 0 {
                alertTitle = "Devices Unlocked"
                alertMessage = "All \(successCount) device\(successCount == 1 ? " has" : "s have") been unlocked."
            } else if successCount == 0 {
                alertTitle = "Error"
                alertMessage = "Failed to unlock all devices. Please try again."
            } else {
                alertTitle = "Partial Success"
                alertMessage = "\(successCount) device\(successCount == 1 ? "" : "s") unlocked. \(failCount) device\(failCount == 1 ? "" : "s") failed."
            }
            showAlert = true
        }
    }
}

#Preview {
    MultiDeviceAppLockView(devices: [
        TheDevice(
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
        ),
        TheDevice(
            serialNumber: "DEF456",
            locationId: 1,
            UDID: "00008120-0000000000000002",
            name: "Green iPad",
            assetTag: "2",
            owner: Owner(id: 144, locationId: 1, name: "Jane Smith"),
            batteryLevel: 0.65,
            totalCapacity: 64,
            lastCheckin: "2024-01-01",
            modified: "2024-01-01",
            notes: ""
        )
    ])
    .environment(AuthenticationManager())
}
