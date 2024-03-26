//
//  PhotosResponse.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 26/03/24.
//

import Foundation

struct PhotosResponse: Codable {
    let photos: PhotosInfo
    let stat: String
}

struct PhotosInfo: Codable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: Int
    let photo: [Photo]
    
    enum CodingKeys: String, CodingKey {
        case page,
             pages,
             total,
             photo
        case perPage = "perpage"
    }
}
struct Photo: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let isPublic: Int
    let isFriend: Int
    let isFamily: Int
    
    enum CodingKeys: String, CodingKey {
        case id,
             owner,
             secret,
             server,
             farm,
             title
        case isPublic = "ispublic"
        case isFriend = "isfriend"
        case isFamily = "isfamily"
    }
}
