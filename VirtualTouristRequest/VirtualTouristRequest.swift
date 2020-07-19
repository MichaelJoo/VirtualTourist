//
//  VirtualTouristRequest.swift
//  Virtual-Tourist
//
//  Created by Do Hyung Joo on 19/7/20.
//  Copyright © 2020 Do Hyung Joo. All rights reserved.
//

import Foundation
import CoreData

struct SearchPhotoRequest: Codable {
    
    static let api_key: String = "8f7087ed10dd7c828b3911e41c54598f"
    
    let lat: Double
    let lon: Double
    
}
