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
    
    // MARK: - Fetched results controller
    
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
    
    // MARK: - Map view

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
        let pin = savePin(annotation: annotation)
        annotation.pin = pin
        
        mapView.addAnnotation(annotation)

        let region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Save PIN
    
    func savePin(annotation: MKPointAnnotationDetailed) -> Pin {
        print("savePin() \(annotation)")
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        try? dataController.viewContext.save()
        print("Pin saved successfully")
        return pin
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
}
