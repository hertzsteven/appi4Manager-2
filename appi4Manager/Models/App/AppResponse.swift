//
//  AppResponse.swift
//  appi4Manager
//
//  Created by Steven Hertz on 7/24/23.
//

import Foundation

struct AppResponse: Codable {
    struct Ap: Codable {
        let id: Int
        let locationId: Int
        let isBook: Bool
        let bundleId: String
        let icon: String
        let name: String
//        let version: Date
//        let shortVersion: String
//        let extVersion: Int
//        let supportsiBooks: Bool
//        let canAutoUpdate: Bool
//        let canToggleRemovable: Bool
//        let platform: String
//        let type: String
//        let showInTeacher: Bool
//        let allowTeacherDistribution: Bool
//      //  let teacherGroups: [Any] //TODO: Specify the type to conforms Codable protocol
//        let showInParent: Bool
//        let manageApp: Bool
//        let mediaPriority: Int
//        let removeWithProfile: Bool
//        let disableBackup: Bool
//        let lastModified: String
//      //  let automaticReinstallWhenRemoved: Any? //TODO: Specify the type to conforms Codable protocol
//     //   let automaticUpdate: Any? //TODO: Specify the type to conforms Codable protocol
//      //  let nonRemovable: Any? //TODO: Specify the type to conforms Codable protocol
//       // let associatedDirectDownload: Any? //TODO: Specify the type to conforms Codable protocol
//      //  let associatedDomains: Any? //TODO: Specify the type to conforms Codable protocol
//        let adamId: Date
        let description: String?
//        let externalVersion: Int
//        let html: String
//        let vendor: String
//        let price: Int
//        let isDeleted: Bool
//        let isDeviceAssignable: Bool
//        let is32BitOnly: Bool
//        let isCustomB2B: Bool
//        let deviceFamilies: [String]
//        let isTvOSCompatible: Bool
//        let isMacOsCompatible: Bool
    }
    let apps: [Ap]
}

