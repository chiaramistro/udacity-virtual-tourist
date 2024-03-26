//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 25/03/24.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("TravelLocationsMapViewController viewDidLoad()")
        
        mapView.delegate = self
        initializeGestureRecognizer()
    }
    
    func initializeGestureRecognizer() {
        print("initializeGestureRecognizer()")
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMapTap(gestureRecognizer:)))
        
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func handleMapTap(gestureRecognizer: UILongPressGestureRecognizer) {
        print("handleMapTap()")
        
        let location: CGPoint = gestureRecognizer.location(in: mapView)
                    
        let coordinates: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        
        let annotation : MKPointAnnotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
        
        print("annotation \(annotation)")
        let region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        mapView.setRegion(region, animated: true)
    }

}

