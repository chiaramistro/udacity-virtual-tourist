//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 25/03/24.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("TravelLocationsMapViewController viewDidLoad()")
    
        initMapView()
    }
    
    func initMapView() {
        print("initMapView()")
        mapView.delegate = self
        
        let regionLat: Double = UserDefaults.standard.double(forKey: "mapRegionLat")
        let regionLon: Double = UserDefaults.standard.double(forKey: "mapRegionLon")
        let latitudeDelta: Double = UserDefaults.standard.double(forKey: "mapRegionLatDelta")
        let longitudeDelta: Double = UserDefaults.standard.double(forKey: "mapRegionLonDelta")
        
        let coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: regionLat, longitude: regionLon)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
        mapView.setRegion(region, animated: true)
        
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

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    // MARK: - Map view delegate methods
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("mapView regionDidChangeAnimated()")
        let regionLat: Double = mapView.region.center.latitude
        let regionLon: Double = mapView.region.center.longitude
        let zoom: MKCoordinateSpan = mapView.region.span
        UserDefaults.standard.set(regionLat, forKey: "mapRegionLat")
        UserDefaults.standard.set(regionLon, forKey: "mapRegionLon")
        UserDefaults.standard.set(zoom.latitudeDelta, forKey: "mapRegionLatDelta")
        UserDefaults.standard.set(zoom.longitudeDelta, forKey: "mapRegionLonDelta")
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        print("mapView() didSelect \(annotation.coordinate)")
        
        let coordinates: CLLocationCoordinate2D = annotation.coordinate
        let photoAlbumController = self.storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        photoAlbumController.coordinates = coordinates
        self.navigationController?.pushViewController(photoAlbumController, animated: true)
    }
    
}
