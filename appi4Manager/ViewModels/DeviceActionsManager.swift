//
//  DeviceActionsManager.swift
//  appi4Manager
//
//  Manages device actions: unlock, restart, lock to app, assign student
//

import Foundation

/// Response model for restart device API call
struct RestartDeviceResponse: Codable {
    let message: String?
    let commandUuid: String?
}

/// Response model for set device owner API call
struct SetDeviceOwnerResponse: Codable {
    let message: String?
}

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

/// Result of a device action operation
struct DeviceActionResult {
    let successCount: Int
    let failCount: Int
    let failedDeviceNames: [String]
    
    var isFullSuccess: Bool { failCount == 0 }
    var isPartialSuccess: Bool { successCount > 0 && failCount > 0 }
    var isFullFailure: Bool { successCount == 0 }
}

/// Manages device actions for single and multiple devices
@Observable
final class DeviceActionsManager {
    
    // MARK: - Observable Properties
    
    var isProcessing: Bool = false
    var progressMessage: String = ""
    var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var authToken: String?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Set the authentication token for API calls
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    // MARK: - Unlock Devices (Clear Restrictions)
    
    /// Unlock a single device by clearing its restrictions
    func unlockDevice(_ device: TheDevice) async -> DeviceActionResult {
        return await unlockDevices([device])
    }
    
    /// Unlock multiple devices by clearing their restrictions
    func unlockDevices(_ devices: [TheDevice]) async -> DeviceActionResult {
        guard let token = authToken else {
            return DeviceActionResult(successCount: 0, failCount: devices.count, failedDeviceNames: devices.map { $0.name })
        }
        
        let devicesWithOwners = devices.filter { $0.owner != nil }
        
        guard !devicesWithOwners.isEmpty else {
            return DeviceActionResult(successCount: 0, failCount: 0, failedDeviceNames: [])
        }
        
        await setProcessingState(true, message: "Unlocking devices...")
        
        var successCount = 0
        var failedNames: [String] = []
        
        for (index, device) in devicesWithOwners.enumerated() {
            guard let ownerId = device.owner?.id else { continue }
            
            await updateProgress("Unlocking \(index + 1) of \(devicesWithOwners.count)...")
            
            do {
                let _: ClearRestrictionsResponse = try await ApiManager.shared.getData(
                    from: .clearRestrictionsStudent(teachAuth: token, students: String(ownerId))
                )
                successCount += 1
            } catch {
                failedNames.append(device.name)
                #if DEBUG
                print("❌ Failed to unlock device \(device.name): \(error)")
                #endif
            }
        }
        
        await setProcessingState(false, message: "")
        
        return DeviceActionResult(successCount: successCount, failCount: failedNames.count, failedDeviceNames: failedNames)
    }
    
    // MARK: - Restart Devices
    
    /// Restart a single device
    func restartDevice(_ device: TheDevice) async -> DeviceActionResult {
        return await restartDevices([device])
    }
    
    /// Restart multiple devices
    func restartDevices(_ devices: [TheDevice]) async -> DeviceActionResult {
        guard authToken != nil else {
            return DeviceActionResult(successCount: 0, failCount: devices.count, failedDeviceNames: devices.map { $0.name })
        }
        
        await setProcessingState(true, message: "Restarting devices...")
        
        var successCount = 0
        var failedNames: [String] = []
        
        for (index, device) in devices.enumerated() {
            await updateProgress("Restarting \(index + 1) of \(devices.count)...")
            
            do {
                let _: RestartDeviceResponse = try await ApiManager.shared.getData(
                    from: .restartDevice(udid: device.UDID)
                )
                successCount += 1
            } catch {
                failedNames.append(device.name)
                #if DEBUG
                print("❌ Failed to restart device \(device.name): \(error)")
                #endif
            }
        }
        
        await setProcessingState(false, message: "")
        
        return DeviceActionResult(successCount: successCount, failCount: failedNames.count, failedDeviceNames: failedNames)
    }
    
    // MARK: - Lock to App
    
    /// Lock a single device to a specific app
    func lockDeviceToApp(_ device: TheDevice, appBundleId: String) async -> DeviceActionResult {
        return await lockDevicesToApp([device], appBundleId: appBundleId)
    }
    
    /// Lock multiple devices to a specific app
    func lockDevicesToApp(_ devices: [TheDevice], appBundleId: String) async -> DeviceActionResult {
        guard let token = authToken else {
            return DeviceActionResult(successCount: 0, failCount: devices.count, failedDeviceNames: devices.map { $0.name })
        }
        
        let devicesWithOwners = devices.filter { $0.owner != nil }
        
        guard !devicesWithOwners.isEmpty else {
            return DeviceActionResult(successCount: 0, failCount: 0, failedDeviceNames: [])
        }
        
        await setProcessingState(true, message: "Locking devices to app...")
        
        var successCount = 0
        var failedNames: [String] = []
        
        for (index, device) in devicesWithOwners.enumerated() {
            guard let ownerId = device.owner?.id else { continue }
            
            await updateProgress("Locking \(index + 1) of \(devicesWithOwners.count)...")
            
            do {
                // First clear any existing restrictions
                let _: ClearRestrictionsResponse = try await ApiManager.shared.getData(
                    from: .clearRestrictionsStudent(teachAuth: token, students: String(ownerId))
                )
                
                // Then lock to the specified app
                let _: LockIntoAppResponse = try await ApiManager.shared.getData(
                    from: .lockIntoApp(appBundleId: appBundleId, studentID: String(ownerId), teachAuth: token)
                )
                successCount += 1
            } catch {
                failedNames.append(device.name)
                #if DEBUG
                print("❌ Failed to lock device \(device.name) to app: \(error)")
                #endif
            }
        }
        
        await setProcessingState(false, message: "")
        
        return DeviceActionResult(successCount: successCount, failCount: failedNames.count, failedDeviceNames: failedNames)
    }
    
    // MARK: - Assign Student to Device
    
    /// Assign a student as owner of a single device
    func assignStudentToDevice(_ device: TheDevice, student: Student) async -> DeviceActionResult {
        return await assignStudentToDevices([device], student: student)
    }
    
    /// Assign a student as owner of multiple devices
    func assignStudentToDevices(_ devices: [TheDevice], student: Student) async -> DeviceActionResult {
        guard authToken != nil else {
            return DeviceActionResult(successCount: 0, failCount: devices.count, failedDeviceNames: devices.map { $0.name })
        }
        
        await setProcessingState(true, message: "Assigning student to devices...")
        
        var successCount = 0
        var failedNames: [String] = []
        
        for (index, device) in devices.enumerated() {
            await updateProgress("Assigning \(index + 1) of \(devices.count)...")
            
            do {
                let _: SetDeviceOwnerResponse = try await ApiManager.shared.getData(
                    from: .setDeviceOwner(udid: device.UDID, userId: student.id)
                )
                successCount += 1
            } catch {
                failedNames.append(device.name)
                #if DEBUG
                print("❌ Failed to assign student to device \(device.name): \(error)")
                #endif
            }
        }
        
        await setProcessingState(false, message: "")
        
        return DeviceActionResult(successCount: successCount, failCount: failedNames.count, failedDeviceNames: failedNames)
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func setProcessingState(_ processing: Bool, message: String) {
        isProcessing = processing
        progressMessage = message
        if !processing {
            errorMessage = nil
        }
    }
    
    @MainActor
    private func updateProgress(_ message: String) {
        progressMessage = message
    }
    
    @MainActor
    func setError(_ message: String) {
        errorMessage = message
    }
    
    @MainActor
    func clearError() {
        errorMessage = nil
    }
}


