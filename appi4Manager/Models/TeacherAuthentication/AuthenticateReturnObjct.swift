//
//  AuthenticateReturnObjct.swift
//  Stub to test url session commands
//
//  Created by Steven Hertz on 11/15/21.
//

import Foundation

struct AuthenticateReturnObjct: Codable {
    let code: Int
    let token: String
    let feature: String
    struct AuthenticatedAs: Codable {
        let id: Int
        let companyId: Int
        let username: String
        let firstName: String
        let lastName: String
        let name: String
    }
    let authenticatedAs: AuthenticatedAs
}

// MARK: - Token Validation Response

/// Response from the /teacher/validate endpoint
struct TokenValidationResponse: Codable {
    let code: Int
    let message: String
    
    /// Check if the token is valid
    var isValid: Bool {
        return code == 200 && message == "ValidToken"
    }
}
