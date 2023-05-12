//
//  ClassDetailResponse.swift
//  Test Making a urlSession
//
//  Created by Steven Hertz on 1/12/21.
//  Copyright © 2021 DIA. All rights reserved.
//

import Foundation

struct ClassDetailResponse: Codable {
    
     let code: Int
     struct Clss: Codable {
        let uuid: String
        let name: String
        let description: String
        let locationId: Int
        let source: String
            //        public let image: String
            //        public let classAsmIdentifier: String
            //        public let userGroupId: Int
        public let studentCount: Int
//        public struct Student: Codable {
//            public let id: Int
//            public let name: String
//            public let email: String
//            public let username: String
//            public let firstName: String
//            public let lastName: String
//            public let photo: URL
//        }
        let students: [Student]
        let teachers: [Student]
        let teacherCount: Int
        let deviceCount: Int
    }
    public let `class`: Clss
    
}

    


