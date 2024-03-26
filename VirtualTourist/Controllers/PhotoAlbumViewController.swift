//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 25/03/24.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var coordinates: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PhotoAlbumViewController viewDidLoad()")
    
        mapView.delegate = self
        
        loadLocation()
    }
    
    func loadLocation() {
        print("loadLocation() coordinates \(String(describing: coordinates))")
        
        var annotations = [MKPointAnnotation]()
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        annotations.append(annotation)
    
        mapView.addAnnotations(annotations)
        mapView.showAnnotations(mapView.annotations, animated: true)
    }

}
