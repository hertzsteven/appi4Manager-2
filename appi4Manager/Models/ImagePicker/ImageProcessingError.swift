//
//  ImageProcessingError.swift
//  appi4Manager
//
//  Created by Steven Hertz on 6/4/23.
//

import Foundation
enum ImageProcessingError: LocalizedError {
    case loadTransferablefailed
    case missingInformation
    case invalidImageData
    case invalidResizedImageData

    var errorDescription: String? {
        switch self {
         case .loadTransferablefailed:
            return "LoadTransferable Failed."
        case .missingInformation:
            return "Required information is missing."
        case .invalidImageData:
            return "The provided image data is invalid."
        case .invalidResizedImageData:
            return "The resized image data is invalid."
        }
    }
}
