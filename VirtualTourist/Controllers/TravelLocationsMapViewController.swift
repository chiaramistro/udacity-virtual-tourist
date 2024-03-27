//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 25/03/24.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("TravelLocationsMapViewController viewDidLoad()")
    
        setupFetchedResultsController()
        initMapView()
        loadLocations()
    }
    
    fileprivate func setupFetchedResultsController() {
        print("setupFetchedResultsController()")
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
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
    
    func loadLocations() {
        print("loadLocations()")
        var annotations = [MKPointAnnotationDetailed]()
        
        if let locations = fetchedResultsController.fetchedObjects {
            
            for location in locations {
                let lat = CLLocationDegrees(location.latitude)
                let long = CLLocationDegrees(location.longitude)
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                let annotation = MKPointAnnotationDetailed()
                annotation.coordinate = coordinate
                annotation.pin = location

                annotations.append(annotation)
            }
        }
        
        mapView.addAnnotations(annotations)
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
        
        let annotation : MKPointAnnotationDetailed = MKPointAnnotationDetailed()
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
        
        savePin(annotation: annotation)

        let region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        mapView.setRegion(region, animated: true)
    }
    
    func savePin(annotation: MKPointAnnotationDetailed) {
        print("savePin() \(annotation)")
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        do {
          try dataController.viewContext.save()
            print("Pin saved successfully")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("mapView didSelect()")
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

class MKPointAnnotationDetailed: MKPointAnnotation {
    var pin: Pin!
}
