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
    let description: String?
    let appLock: Bool?
    let appWhitelist: [String]?

//    WebWhiteliststruct
    struct WebWhitelist: Codable {
        let lockInSafari: Bool
        let sites: [URL]
    }
    let webWhitelist: WebWhitelist?

//    Materials
    struct Materials: Codable {
        let lockInSafari: Bool
        let weblock: Bool
        struct Site: Codable {
            let url: URL
            let title: String
        }
        let sites: [Site]?
    }
    let materials: Materials?
    
//      Resrictions
//    let notifications: Any? //TODO: Specify the type to conforms Codable protocol
    struct Restrictions: Codable {
        let allowAppstore: Bool
        let allowCamera: Bool
        let allowChat: Bool
        let allowGamecenter: Bool
        let allowNotifications: Bool
        let allowSafari: Bool
        let allowScreenshots: Bool
        let allowSpellcheck: Bool
        let allowiTunes: Bool
        let allowAirDrop: Bool
    }
    let restrictions: Restrictions
    
    let genres: [String]
}
