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
    /// Re-fetches device data to get current owner before unlocking
    func unlockDevices(_ devices: [TheDevice]) async -> DeviceActionResult {
        guard let token = authToken else {
            print("🔓 [Unlock] No auth token available")
            return DeviceActionResult(successCount: 0, failCount: devices.count, failedDeviceNames: devices.map { $0.name })
        }
        
        guard !devices.isEmpty else {
            print("🔓 [Unlock] No devices provided")
            return DeviceActionResult(successCount: 0, failCount: 0, failedDeviceNames: [])
        }
        
        await setProcessingState(true, message: "Fetching current device info...")
        
        print("🔓 [Unlock] Starting unlock for \(devices.count) device(s)")
        
        var successCount = 0
        var failedNames: [String] = []
        
        for (index, device) in devices.enumerated() {
            await updateProgress("Unlocking \(index + 1) of \(devices.count)...")
            
            print("🔓 [Unlock] Processing device: \(device.name) (UDID: \(device.UDID))")
            
            // Fetch fresh device data to get current owner
            do {
                let deviceResponse: DeviceListResponse = try await ApiManager.shared.getData(
                    from: .getDevices(assettag: nil)
                )
                
                // Find this specific device in the response
                guard let freshDevice = deviceResponse.devices.first(where: { $0.UDID == device.UDID }) else {
                    print("🔓 [Unlock] ❌ Device \(device.name) not found in fresh device list")
                    failedNames.append(device.name)
                    continue
                }
                
                // Check if device has an owner
                guard let owner = freshDevice.owner else {
                    print("🔓 [Unlock] ⚠️ Device \(device.name) has no owner assigned - skipping")
                    failedNames.append(device.name)
                    continue
                }
                
                print("🔓 [Unlock] ✓ Fresh owner data retrieved:")
                print("   - Owner ID: \(owner.id)")
                print("   - Owner Name: \(owner.name)")
                print("   - First Name: \(owner.firstName ?? "N/A")")
                print("   - Last Name: \(owner.lastName ?? "N/A")")
                print("   - Username: \(owner.username ?? "N/A")")
                
                // Send the unlock (clearRestrictions) command
                print("🔓 [Unlock] Sending clearRestrictionsStudent API call:")
                print("   - Endpoint: /teacher/lessons/stop")
                print("   - Student ID: \(owner.id)")
                print("   - Token: \(String(token.prefix(8)))...")
                
                let _: ClearRestrictionsResponse = try await ApiManager.shared.getData(
                    from: .clearRestrictionsStudent(teachAuth: token, students: String(owner.id))
                )
                
                print("🔓 [Unlock] ✅ Successfully unlocked device \(device.name) for owner \(owner.name)")
                successCount += 1
                
            } catch {
                failedNames.append(device.name)
                print("🔓 [Unlock] ❌ Failed to unlock device \(device.name): \(error)")
            }
        }
        
        await setProcessingState(false, message: "")
        
        print("🔓 [Unlock] Completed: \(successCount) succeeded, \(failedNames.count) failed")
        if !failedNames.isEmpty {
            print("🔓 [Unlock] Failed devices: \(failedNames.joined(separator: ", "))")
        }
        
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
    /// Re-fetches device data to get current owner before locking
    func lockDevicesToApp(_ devices: [TheDevice], appBundleId: String) async -> DeviceActionResult {
        guard let token = authToken else {
            print("🔒 [Lock to App] No auth token available")
            return DeviceActionResult(successCount: 0, failCount: devices.count, failedDeviceNames: devices.map { $0.name })
        }
        
        guard !devices.isEmpty else {
            print("🔒 [Lock to App] No devices provided")
            return DeviceActionResult(successCount: 0, failCount: 0, failedDeviceNames: [])
        }
        
        await setProcessingState(true, message: "Fetching current device info...")
        
        print("🔒 [Lock to App] Starting lock to app '\(appBundleId)' for \(devices.count) device(s)")
        
        var successCount = 0
        var failedNames: [String] = []
        
        for (index, device) in devices.enumerated() {
            await updateProgress("Locking \(index + 1) of \(devices.count)...")
            
            print("🔒 [Lock to App] Processing device: \(device.name) (UDID: \(device.UDID))")
            
            // Fetch fresh device data to get current owner
            do {
                let deviceResponse: DeviceListResponse = try await ApiManager.shared.getData(
                    from: .getDevices(assettag: nil)
                )
                
                // Find this specific device in the response
                guard let freshDevice = deviceResponse.devices.first(where: { $0.UDID == device.UDID }) else {
                    print("🔒 [Lock to App] ❌ Device \(device.name) not found in fresh device list")
                    failedNames.append(device.name)
                    continue
                }
                
                // Check if device has an owner
                guard let owner = freshDevice.owner else {
                    print("🔒 [Lock to App] ⚠️ Device \(device.name) has no owner assigned - skipping")
                    failedNames.append(device.name)
                    continue
                }
                
                print("🔒 [Lock to App] ✓ Fresh owner data retrieved:")
                print("   - Owner ID: \(owner.id)")
                print("   - Owner Name: \(owner.name)")
                print("   - First Name: \(owner.firstName ?? "N/A")")
                print("   - Last Name: \(owner.lastName ?? "N/A")")
                print("   - Username: \(owner.username ?? "N/A")")
                
                // First clear any existing restrictions
                print("🔒 [Lock to App] Clearing existing restrictions for student \(owner.id)...")
                let _: ClearRestrictionsResponse = try await ApiManager.shared.getData(
                    from: .clearRestrictionsStudent(teachAuth: token, students: String(owner.id))
                )
                
                // Then lock to the specified app
                print("🔒 [Lock to App] Sending lockIntoApp API call:")
                print("   - Endpoint: /teacher/apply/applock")
                print("   - App Bundle ID: \(appBundleId)")
                print("   - Student ID: \(owner.id)")
                print("   - Token: \(String(token.prefix(8)))...")
                
                let _: LockIntoAppResponse = try await ApiManager.shared.getData(
                    from: .lockIntoApp(appBundleId: appBundleId, studentID: String(owner.id), teachAuth: token)
                )
                
                print("🔒 [Lock to App] ✅ Successfully locked device \(device.name) to app for owner \(owner.name)")
                successCount += 1
                
            } catch {
                failedNames.append(device.name)
                print("🔒 [Lock to App] ❌ Failed to lock device \(device.name) to app: \(error)")
            }
        }
        
        await setProcessingState(false, message: "")
        
        print("🔒 [Lock to App] Completed: \(successCount) succeeded, \(failedNames.count) failed")
        if !failedNames.isEmpty {
            print("🔒 [Lock to App] Failed devices: \(failedNames.joined(separator: ", "))")
        }
        
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


