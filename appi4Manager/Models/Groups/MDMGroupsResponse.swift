//
//  GroupsResponse.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/1/23.
//

import Foundation

struct MDMGroupsResponse: Codable {
    let code: Int
    let count: Int
    let groups: [MDMGroup]
}
