//
//  DeviceListResponse.swift
//  Test Making a urlSession
//
//  Created by Steven Hertz on 6/6/19.
//  Copyright © 2019 DIA. All rights reserved.
//

import Foundation


struct DeviceListResponse: Codable {
    let code: Int
    let count: Int
    let devices: [TheDevice]
}
