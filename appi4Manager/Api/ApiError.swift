//
//  ApiError.swift
//  list the users
//
//  Created by Steven Hertz on 2/8/23.
//

import Foundation


    /// Define your custom errors
    enum ApiError: Error {
        case invalidPath
        case clientBadRequest(hTTPuRLResponse: HTTPURLResponse)
        case clientUnauthorized(hTTPuRLResponse: HTTPURLResponse)
        case clientForbidden(hTTPuRLResponse: HTTPURLResponse)
        case clientNotFound(hTTPuRLResponse: HTTPURLResponse)
        case serverError(hTTPuRLResponse: HTTPURLResponse)
        case unexpected (hTTPuRLResponse: HTTPURLResponse)
        case decodingError(decodingStatus: Error)
    }

    extension ApiError {
        
        var description: String {
            switch self {
            case .invalidPath:
                return "Invalid Path"
            case .clientBadRequest:
                return "Bad Request"
            case .clientUnauthorized:
                return "Unauthorized access to API resource"
            case .clientForbidden:
                return "client lacks the necessary authorization to access the resource"
            case .clientNotFound:
                return "API resource not found"
            case .serverError(hTTPuRLResponse: let hTTPuRLResponse):
                return "Server Error code: \(hTTPuRLResponse)"
            case .unexpected(hTTPuRLResponse: let hTTPuRLResponse):
                return "Unexpected Error code: \(hTTPuRLResponse)"
            case .decodingError(decodingStatus: let decodingStatus):
                return "Decoding Error code: \(decodingStatus)"
            }
        }

    }
