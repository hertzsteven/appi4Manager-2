//
//  UserResponse.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import Foundation

struct UserResponse: Codable {
    let code: Int
    let count: Int
    let users: [User]
}

