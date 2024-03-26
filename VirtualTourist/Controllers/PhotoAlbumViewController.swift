//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 25/03/24.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController {

    var coordinates: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PhotoAlbumViewController viewDidLoad()")
        
        print("PhotoAlbumViewController viewDidLoad() coordinates \(coordinates)")
    }

}

