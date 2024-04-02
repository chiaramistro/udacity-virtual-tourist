//
//  TravelLocationsMapViewController+MKMapViewDelegate.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 02/04/24.
//

import UIKit
import MapKit

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    // MARK: - Map view delegate methods
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let regionLat: Double = mapView.region.center.latitude
        let regionLon: Double = mapView.region.center.longitude
        let zoom: MKCoordinateSpan = mapView.region.span
        UserDefaults.standard.set(regionLat, forKey: "mapRegionLat")
        UserDefaults.standard.set(regionLon, forKey: "mapRegionLon")
        UserDefaults.standard.set(zoom.latitudeDelta, forKey: "mapRegionLatDelta")
        UserDefaults.standard.set(zoom.longitudeDelta, forKey: "mapRegionLonDelta")
        UserDefaults.standard.synchronize()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let detailedAnnotation = view.annotation as? MKPointAnnotationDetailed

         let photoAlbumController = self.storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        photoAlbumController.pin = detailedAnnotation?.pin
        photoAlbumController.dataController = dataController
        self.navigationController?.pushViewController(photoAlbumController, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView

        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.glyphTintColor = .white
            pinView!.markerTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
}
