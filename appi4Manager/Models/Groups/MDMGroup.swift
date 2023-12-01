//
//  Group.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/1/23.
//

import Foundation

struct MDMGroup: Codable {
    struct Acl: Codable {
        let teacher: String
        let parent: String
    }
    let id:             Int
    let locationId:     Int
    let name:           String
    let description:    String
    let userCount:      Int
    let acl:            Acl
    let modified:       String
}
