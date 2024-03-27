//
//  PhotoSizeResponse.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 27/03/24.
//

import Foundation

struct PhotoSizeResponse: Codable {
    let sizes: PhotoSizeInfo
    let stat: String
}

struct PhotoSizeInfo: Codable {
    let canblog: Int
    let canprint: Int
    let candownload: Int
    let size: [PhotoSize]
}

struct PhotoSize: Codable {
    let label: String
    let width: Int
    let height: Int
    let source: String
    let url: String
    let media: String
}
