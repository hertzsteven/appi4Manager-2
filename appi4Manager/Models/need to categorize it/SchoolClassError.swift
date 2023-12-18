//
//  SchoolClassError.swift
//  appi4Manager
//
//  Created by Steven Hertz on 12/18/23.
//

import Foundation

enum SchoolClassError: Error {
    case fetchError
    case createClassError
    case dictCreationError
    case retreiveLocationsError
    case other(Error)
    
    var localizedDescription: String {
        switch self {
        case .fetchError:
            return "Failed to fetch school classes."
        case .createClassError:
            return "Failed to create a class."
        case .dictCreationError:
            return "Failed to create a dictionary of classes."
        case .retreiveLocationsError:
            return "Failed to retreive locations"
        case .other(let error):
            return error.localizedDescription
        }
    }
}
