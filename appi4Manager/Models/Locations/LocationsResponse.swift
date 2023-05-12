//
//  LocationsResponse.swift
//  list the users
//
//  Created by Steven Hertz on 3/20/23.
//

import Foundation

// MARK: - Welcome10
struct LocationsResponse: Codable, Hashable {
    let locations: [Location]
}

// MARK: - Location
struct Location: Codable, Hashable, Identifiable {
    var id: Int
    var name: String
}
