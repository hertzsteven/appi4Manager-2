//
//  ListLessonsResponse.swift
//  appi4Manager
//
//  Created by Steven Hertz on 6/19/23.
//

import Foundation
struct LessonsListResponse: Codable {
    let lessons: [Lesson]
}



    struct Lesson: Codable {
        let id: Int
        let name: String
        let description: String
        let appLock: [String]?
        let appWhitelist: [String]?
//        let webWhitelist: [String]?
        struct Materials: Codable {
            let weblock: Bool
            struct Site: Codable {
                let url: String
                let title: String
            }
            let sites: [Site]
            let lockInSafari: Bool
        }
        let materials: Materials?
        let notifications: [String]?
        struct Restrictions: Codable {
            let allowAppstore: Bool?
            let allowCamera: Bool
            let allowChat: Bool?
            let allowGamecenter: Bool?
            let allowNotifications: Bool?
            let allowSafari: Bool?
            let allowScreenshots: Bool?
            let allowSpellcheck: Bool?
            let allowiMessage: Bool?
            let allowiTunes: Bool?
            let allowAirDrop: Bool?
        }
        let restrictions: Restrictions?
        let genres: [String]?
    }
