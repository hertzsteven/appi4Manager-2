//
//  DeviceMockStudentService.swift
//  appi4Manager
//
//  Creates or deletes per-device mock students when assigning/unassigning devices to classes.
//

import Foundation

enum DeviceMockStudentService {

    /// Fetches users in the class group; if a device mock for this UDID exists, returns its ID.
    /// Otherwise creates one via the API and returns the new user's ID. Throws on API failure.
    /// - Returns: The mock student's user ID (existing or newly created).
    static func getOrCreate(
        deviceUDID: String,
        classUUID: String,
        locationId: Int,
        classGroupId: Int
    ) async throws -> Int {
        let response: UserResponse = try await ApiManager.shared.getData(
            from: .getUsersInGroup(groupID: classGroupId)
        )
        let match = response.users.first { $0.username == deviceUDID && $0.firstName == "device" }
        if let existing = match {
            return existing.id
        }
        let newUser = User.createDeviceMockStudent(
            deviceUDID: deviceUDID,
            classUUID: classUUID,
            locationId: locationId,
            classGroupId: classGroupId
        )
        let addResponse: AddAUserResponse = try await ApiManager.shared.getData(from: .addUsr(user: newUser))
        return addResponse.id
    }

    /// If a device mock for this UDID exists in the class group, deletes it.
    /// Never throws; errors are logged only (mock may never have been created).
    static func deleteIfExists(deviceUDID: String, classGroupId: Int) async {
        do {
            let response: UserResponse = try await ApiManager.shared.getData(
                from: .getUsersInGroup(groupID: classGroupId)
            )
            guard let match = response.users.first(where: { $0.username == deviceUDID && $0.firstName == "device" }) else {
                return
            }
            _ = try await ApiManager.shared.getDataNoDecode(from: .deleteaUser(id: match.id))
        } catch {
            #if DEBUG
            print("⚠️ Device mock student deleteIfExists (non-fatal): \(error)")
            #endif
        }
    }
}
