//
//  SearchPhotoResponse.swift
//  Virtual-Tourist
//
//  Created by Do Hyung Joo on 19/7/20.
//  Copyright © 2020 Do Hyung Joo. All rights reserved.
//

import Foundation
import CoreData

struct SearchPhotoResponse: Codable {
    
    let photos: Photos
    let stat: String?
   
}

struct Photos: Codable {
    
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [Images]
}

struct Images: Codable {
    
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
    
}
