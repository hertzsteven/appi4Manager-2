//
//  Student.swift
//  list the users
//
//  Created by Steven Hertz on 2/15/23.
//

import Foundation

struct Student: Codable, Hashable {
    let id: Int
    let name: String
    let email: String
    let username: String
    let firstName: String
    let lastName: String
    let photo: URL
}
