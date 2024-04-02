//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 25/03/24.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var noImagesText: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var pin: Pin!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var numOfDownloadedPhotos: Int = 0
    var totalNumOfPhotos: Int = 0
    var numOfPages: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        initCollectionView()
        
        loadLocation()
        setupFetchedResultsController()
        loadPhotos()
    }
    
    // MARK: - Fetched results controller
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin)-photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Map detail
    
    func loadLocation() {
        var annotations = [MKPointAnnotation]()
        
        let annotation = MKPointAnnotation()
        
        let coordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        annotation.coordinate = coordinates
        annotations.append(annotation)
    
        mapView.addAnnotations(annotations)
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    // MARK: - Photos
    
    func loadPhotos() {
        toggleLoading(loading: true)
        noImagesText.isHidden = true
        newCollectionButton.isEnabled = false
        
        if let fetchedPhotos = fetchedResultsController.fetchedObjects {
            if (fetchedPhotos.isEmpty) {
                debugPrint("Pin DOES NOT have a photo album")
                // pin doesn't have a photoalbum yet, fetch photos
                let page = getRandomPageNumber()
                FlickrClient.getPhotosOnLocation(lat: pin.latitude, lon: pin.longitude, page: page) { result, error in
                    // if result is still empty, then show empty state
                    if let result = result {
                        self.numOfPages = result.pages
                        self.totalNumOfPhotos = result.photo.count
                        if (self.totalNumOfPhotos > 0) {
                            self.fetchPhotoSources(singlePhotos: result.photo)
                        } else {
                            debugPrint("No photos available, show empty state")
                            self.showEmptyState()
                            self.toggleLoading(loading: false)
                        }
                    } else {
                        // Error, we will show empty state with alert
                        debugPrint("Error occurred during getPhotosOnLocation: \(error?.localizedDescription)")
                        self.showEmptyState()
                        self.toggleLoading(loading: false)
                        self.showErrorAlert(message: "An error occurred during fetching photos for location")
                    }
                }
            } else {
                debugPrint("Pin DOES have a photo album")
                self.totalNumOfPhotos = fetchedPhotos.count
                toggleLoading(loading: false)
            }
        }
    }
    
    func fetchPhotoSources(singlePhotos: [SinglePhoto]) {
        var loadedPhotos: Int = 0
        
        for photo in singlePhotos {
            FlickrClient.getPhotoSize(id: photo.id) { result, error in
                if let result = result {
                    if let lastPhoto = result.size.last {
                        let fetchedPhoto = Photo(context: self.dataController.viewContext)
                        fetchedPhoto.id = photo.id
                        fetchedPhoto.source = URL(string: lastPhoto.source)!
                        fetchedPhoto.pin = self.pin
                        try? self.dataController.viewContext.save()
                        loadedPhotos+=1
                        debugPrint("New photo instance saved successfully")
                        if (loadedPhotos == singlePhotos.count) { // finished loading all photos
                            self.reloadCollectionView()
                            self.toggleLoading(loading: false)
                        }
                    }
                } else {
                    // Error (will show placeholder for image)
                    debugPrint("Error occurred during getPhotoSize: \(error?.localizedDescription)")
                    loadedPhotos+=1
                }
            }
        }
    }
    
    func getRandomPageNumber() -> Int {
        return Int.random(in: 0..<self.numOfPages)
    }
    
    // MARK: - General UI methods
    
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func toggleLoading(loading: Bool) {
        collectionView.isHidden = loading
        loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
    func showEmptyState() {
        noImagesText.isHidden = false
        newCollectionButton.isEnabled = true
    }
    
    @IBAction func onNewCollectionTap(_ sender: Any) {
        if let fetchedPhotos = fetchedResultsController.fetchedObjects {
            for fetchedPhoto in fetchedPhotos {
                dataController.viewContext.delete(fetchedPhoto as NSManagedObject)
                try? dataController.viewContext.save()
            }
            debugPrint("Photos deleted successfully")
        }
        numOfDownloadedPhotos = 0
        reloadCollectionView()
        loadPhotos()
    }
    
}
