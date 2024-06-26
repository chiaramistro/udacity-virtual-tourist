//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 26/03/24.
//

import Foundation

class FlickrClient {
    
    enum Endpoints {
        static let api_key = "your_api_key"
        static let base = "https://api.flickr.com/services/rest"
        
        case searchPhotos(Double, Double, Int)
        case photoSizes(String)
        
        var stringValue: String {
            switch self {
            case .searchPhotos(let lat, let lon, let page): return Endpoints.base + "?method=flickr.photos.search" + "&format=json&api_key=" + Endpoints.api_key + "&lat=\(lat)&lon=\(lon)&page=\(page)"
            case .photoSizes(let id): return Endpoints.base + "?method=flickr.photos.getSizes" + "&format=json&api_key=" + Endpoints.api_key + "&photo_id=\(id)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }

    }
    
    // MARK: - GET list of images from a location
    
    class func getPhotosOnLocation(lat: Double, lon: Double, page: Int, completion: @escaping (PhotosInfo?, Error?) -> Void) {
        taskForGETRequest(url: Endpoints.searchPhotos(lat, lon, page).url, responseType: PhotosResponse.self) { response, error in
            if let response = response {
                completion(response.photos, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    // MARK: - GET image URLs from ID
    
    class func getPhotoSize(id: String, completion: @escaping (PhotoSizeInfo?, Error?) -> Void) {
        taskForGETRequest(url: Endpoints.photoSizes(id).url, responseType: PhotoSizeResponse.self) { response, error in
            if let response = response {
                completion(response.sizes, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    // MARK: - GET image from URL
    
    class func getImage(url: URL, completion: @escaping (Data?, Error?) -> Void) {
         let download = URLSession.shared.dataTask(with: url) { data, response, error in
             if let data = data {
                 completion(data, nil)
             } else {
                 completion(nil, error)
             }
         }
         download.resume()
     }
    
    // MARK: - Generic GET request method

    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        debugPrint("Request started for URL: \(url)")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                debugPrint("Data not valid")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let range = 14..<(data.count-1)
            let newData = data.subdata(in: range)
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(responseType, from: newData)
                DispatchQueue.main.async {
                    completion(response, nil)
                }
            } catch {
                debugPrint("Parsing not valid")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }

        task.resume()
    }
}
