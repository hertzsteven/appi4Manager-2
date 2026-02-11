//
//  DeviceActionsManager.swift
//  appi4Manager
//
//  Manages device actions: unlock, restart, lock to app, assign student
//

import Foundation
import FirebaseFirestore

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
    /// Number of students skipped because they had no assigned device (only set by endStudentSessions).
    let noDeviceCount: Int?
    
    init(successCount: Int, failCount: Int, failedDeviceNames: [String], noDeviceCount: Int? = nil) {
        self.successCount = successCount
        self.failCount = failCount
        self.failedDeviceNames = failedDeviceNames
        self.noDeviceCount = noDeviceCount
    }
    
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
    
    /// Ends selected students' sessions: clears restrictions, reassigns each device to its per-device mock student, sets cancelRequested on ActiveSessions, and optionally locks the device to the Student Login app.
    ///
    /// - Parameter lockToLogin: When true, after reassigning the device, locks it to the Student Login app so the student sees the login screen. When false, the device is only cleared and reassigned (unlock behavior).
    /// - Parameter studentIds: Student IDs to process.
    /// - Parameter devices: Class devices (used to find device owned by each student).
    /// - Parameter classUUID: Class UUID (used for mock student lookup/creation).
    /// - Parameter classGroupId: Class group ID for mock student lookup/creation.
    /// - Parameter locationId: Location ID for ActiveSession document ID and mock student creation.
    /// - Parameter timeslot: Current timeslot for ActiveSession document ID.
    /// - Returns: Result with success/fail counts and optional noDeviceCount.
    func endStudentSessions(
        studentIds: [Int],
        devices: [TheDevice],
        classUUID: String,
        classGroupId: Int,
        locationId: Int,
        timeslot: TimeOfDay,
        lockToLogin: Bool = false
    ) async -> DeviceActionResult {
        guard let token = authToken else {
            print("🔓 [EndStudentSessions] No auth token available")
            return DeviceActionResult(successCount: 0, failCount: studentIds.count, failedDeviceNames: studentIds.map { "Student \($0)" })
        }
        guard !studentIds.isEmpty else {
            return DeviceActionResult(successCount: 0, failCount: 0, failedDeviceNames: [])
        }
        
        let progressVerb = lockToLogin ? "Locking" : "Unlocking"
        await setProcessingState(true, message: "\(progressVerb) students...")
        var successCount = 0
        var failedNames: [String] = []
        var noDeviceCount = 0
        
        let date = ActiveSession.todayDateString()
        let timeslotStr = ActiveSession.timeslotString(from: timeslot)
        let companyId = APISchoolInfo.shared.companyId
        
        for (index, studentId) in studentIds.enumerated() {
            await updateProgress("\(progressVerb) \(index + 1) of \(studentIds.count)...")
            
            // First resolve the device; skip entirely if student has no device
            guard let device = devices.first(where: { $0.owner?.id == studentId }) else {
                print("🔓 [EndStudentSessions] No device for student \(studentId), skipping")
                noDeviceCount += 1
                continue
            }
            
            do {
                try await endSingleSession(
                    studentId: studentId,
                    device: device,
                    token: token,
                    classUUID: classUUID,
                    classGroupId: classGroupId,
                    locationId: locationId,
                    date: date,
                    timeslotStr: timeslotStr,
                    companyId: companyId,
                    lockToLogin: lockToLogin
                )
                successCount += 1
            } catch {
                failedNames.append("Student \(studentId)")
                print("🔓 [EndStudentSessions] ❌ Failed for student \(studentId): \(error)")
            }
        }
        
        await setProcessingState(false, message: "")
        return DeviceActionResult(
            successCount: successCount,
            failCount: failedNames.count,
            failedDeviceNames: failedNames,
            noDeviceCount: noDeviceCount > 0 ? noDeviceCount : nil
        )
    }
    
    /// Performs the full session teardown for one student/device: set cancelRequested, clear restrictions, reassign to mock student, optionally lock to login app. Throws on API or Firestore failure.
    private func endSingleSession(
        studentId: Int,
        device: TheDevice,
        token: String,
        classUUID: String,
        classGroupId: Int,
        locationId: Int,
        date: String,
        timeslotStr: String,
        companyId: Int,
        lockToLogin: Bool
    ) async throws {
        // Step A — Signal cancellation to student app before taking any device action
        await setCancelRequested(studentId: studentId, locationId: locationId, date: date, timeslotStr: timeslotStr, companyId: companyId)
        
        // Step B — Clear restrictions
        let _: ClearRestrictionsResponse = try await ApiManager.shared.getData(
            from: .clearRestrictionsStudent(teachAuth: token, students: String(studentId))
        )
        
        // Step C — Resolve per-device mock student (create if needed), then reassign device to it
        let mockStudentId = try await DeviceMockStudentService.getOrCreate(
            deviceUDID: device.UDID,
            classUUID: classUUID,
            locationId: locationId,
            classGroupId: classGroupId
        )
        let _: SetDeviceOwnerResponse = try await ApiManager.shared.getData(
            from: .setDeviceOwner(udid: device.UDID, userId: mockStudentId)
        )
        
        // Step D — Optionally lock device to Student Login app (using mock student as current owner)
        if lockToLogin {
            let _: LockIntoAppResponse = try await ApiManager.shared.getData(
                from: .lockIntoApp(
                    appBundleId: AppConstants.studentLoginBundleId,
                    studentID: String(mockStudentId),
                    teachAuth: token
                )
            )
        }
    }
    
    /// Writes cancelRequested, status "completed", and completedAt to the ActiveSession document for the given student. Logs warning on failure; does not throw.
    private func setCancelRequested(studentId: Int, locationId: Int, date: String, timeslotStr: String, companyId: Int) async {
        let docId = ActiveSession.makeDocumentId(
            companyId: companyId,
            locationId: locationId,
            studentId: studentId,
            date: date,
            timeslot: timeslotStr
        )
        let db = Firestore.firestore()
        do {
            try await db.collection("ActiveSessions").document(docId).updateData([
                "cancelRequested": true,
                "status": "completed",
                "completedAt": FieldValue.serverTimestamp()
            ])
        } catch {
            print("🔓 [EndStudentSessions] ⚠️ Could not set cancelRequested for student \(studentId): \(error)")
        }
    }
    
    /// Ends sessions for the given devices: sets cancelRequested, clears restrictions, reassigns each device to its per-device mock student, and optionally locks to the Student Login app. Devices without an owner are skipped (counted in noDeviceCount).
    func endDeviceSessions(
        devices: [TheDevice],
        classUUID: String,
        classGroupId: Int,
        locationId: Int,
        timeslot: TimeOfDay,
        lockToLogin: Bool = false
    ) async -> DeviceActionResult {
        guard let token = authToken else {
            print("🔓 [EndDeviceSessions] No auth token available")
            return DeviceActionResult(successCount: 0, failCount: devices.count, failedDeviceNames: devices.map { $0.name })
        }
        guard !devices.isEmpty else {
            return DeviceActionResult(successCount: 0, failCount: 0, failedDeviceNames: [])
        }
        
        let progressVerb = lockToLogin ? "Locking" : "Unlocking"
        await setProcessingState(true, message: "\(progressVerb) devices...")
        var successCount = 0
        var failedNames: [String] = []
        var noDeviceCount = 0
        
        let date = ActiveSession.todayDateString()
        let timeslotStr = ActiveSession.timeslotString(from: timeslot)
        let companyId = APISchoolInfo.shared.companyId
        
        let devicesWithOwners = devices.compactMap { device -> (studentId: Int, device: TheDevice)? in
            guard let ownerId = device.owner?.id else { return nil }
            return (studentId: ownerId, device: device)
        }
        
        for (index, pair) in devicesWithOwners.enumerated() {
            await updateProgress("\(progressVerb) \(index + 1) of \(devicesWithOwners.count)...")
            do {
                try await endSingleSession(
                    studentId: pair.studentId,
                    device: pair.device,
                    token: token,
                    classUUID: classUUID,
                    classGroupId: classGroupId,
                    locationId: locationId,
                    date: date,
                    timeslotStr: timeslotStr,
                    companyId: companyId,
                    lockToLogin: lockToLogin
                )
                successCount += 1
            } catch {
                failedNames.append(pair.device.name)
                print("🔓 [EndDeviceSessions] ❌ Failed for device \(pair.device.name): \(error)")
            }
        }
        
        noDeviceCount = devices.count - devicesWithOwners.count
        if noDeviceCount > 0 {
            print("🔓 [EndDeviceSessions] \(noDeviceCount) device(s) had no owner, skipped")
        }
        
        await setProcessingState(false, message: "")
        return DeviceActionResult(
            successCount: successCount,
            failCount: failedNames.count,
            failedDeviceNames: failedNames,
            noDeviceCount: noDeviceCount > 0 ? noDeviceCount : nil
        )
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


