//
//  LessonDetailResponse.swift
//  appi4Manager
//
//  Created by Steven Hertz on 6/20/23.
//

import Foundation

struct LessonDetailResponse: Codable {
    
    let id: Int
    let name: String
    let description: String
    let colorId: Int
    
    struct AppWhite: Codable {
        let identifier: String
        let name: String
        let icon: URL
    }
    let appWhitelist: [AppWhite]
    
    let restrictedFunctionality: [String]
    let restrictedGenres: [String]
    let weblock: Bool
    
    struct Link: Codable {
        let url: String
        let title: String
    }
    let links: [Link]
    
    let lockInSafari: Bool
    
}

