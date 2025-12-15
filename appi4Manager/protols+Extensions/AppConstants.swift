//
//  AppConstants.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/3/23.
//

import Foundation
enum AppConstants {
    // Define your static variables here

    // Example: API Endpoints
    static let apiBaseUrl                              = "https://api.example.com"
    static let loginEndpoint                           = "\(apiBaseUrl)/login"
    static let registerEndpoint                        = "\(apiBaseUrl)/register"

    // Example: Default values
    static let defaultTimeoutInterval: TimeInterval    = 60
    static let defaultLocationId                       = 1

    // Example: UI Constants
    static let primaryButtonColorHex                   = "#1A73E8"
    static let defaultFontSize: CGFloat                = 14.0

    // Example: Error Messages
    static let networkErrorMessage                     = "Unable to connect to the network. Please try again later."
    static let generalErrorMessage                     = "Something went wrong. Please try again."

    // Add other literals and constants as needed
    static let teacherUserName                         = "**appi4Teacher-NoModification**"
    static let teacherGroupName                        = "**appi4TeacherGroup-NoModification**"
    static let pictureClassName                        = "**appi4PictureClass-NoModification**"
    static let defaultTeacherPwd                       = "123456"
    static let defaultUserPwd                          = "123456"
    
    // Student Login App Bundle ID for device locking
    static let studentLoginBundleId                    = "com.dia.studentLoginFire"
}
