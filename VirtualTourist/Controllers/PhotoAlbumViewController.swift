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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PhotoAlbumViewController viewDidLoad()")
    
        print("PhotoAlbumViewController pin \(pin.objectID)")
        
        mapView.delegate = self
        
        initCollectionView()
        
        loadLocation()
        setupFetchedResultsController()
        loadPhotos()
    }
    
    func setupFetchedResultsController() {
        print("setupFetchedResultsController()")
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
    
    func initCollectionView() {
        print("initCollectionView()")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView!.reloadData()
    }
    
    func loadLocation() {
        print("loadLocation() pin \(String(describing: pin))")
        
        var annotations = [MKPointAnnotation]()
        
        let annotation = MKPointAnnotation()
        
        let coordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        annotation.coordinate = coordinates
        annotations.append(annotation)
    
        mapView.addAnnotations(annotations)
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func loadPhotos() {
        print("loadPhotos()")
        toggleLoading(loading: true)
        noImagesText.isHidden = true
        newCollectionButton.isEnabled = false
        
        if let fetchedPhotos = fetchedResultsController.fetchedObjects {
            if (fetchedPhotos.isEmpty) {
                print("Pin DOES NOT have a photo album")
                // pin doesn't have a photoalbum yet, fetch photos
                FlickrClient.getPhotosOnLocation(lat: pin.latitude, lon: pin.longitude) { result, error in
                    print("getPhotosOnLocation() result \(String(describing: result))")
                    // if result is still empty, then show empty state
                    if let result = result {
                        self.totalNumOfPhotos = result.perPage
                        if (self.totalNumOfPhotos > 0) {
                            self.fetchPhotoSources(singlePhotos: result.photo)
                        } else {
                            print("Empty state")
                            self.showEmptyState()
                            self.toggleLoading(loading: false)
                        }
                    } else {
                        // Error empty state
                        print("Error occurred during getPhotosOnLocation: \(error?.localizedDescription)")
                        self.showEmptyState()
                        self.toggleLoading(loading: false)
                    }
                }
            } else {
                print("Pin DOES have a photo album")
                print("Total number of photos \(fetchedPhotos.count)")
                self.totalNumOfPhotos = fetchedPhotos.count
                toggleLoading(loading: false)
            }
        }
    }
    
    func toggleLoading(loading: Bool) {
        print("toggleLoading(\(loading))")
        collectionView.isHidden = loading
        loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
    func showEmptyState() {
        print("showEmptyState()")
        noImagesText.isHidden = false
    }
    
    func fetchPhotoSources(singlePhotos: [SinglePhoto]) {
        print("fetchPhotoSources()")
        var loadedPhotos: Int = 0
        print("Total number of photos \(singlePhotos.count)")
        
        for photo in singlePhotos {
            FlickrClient.getPhotoSize(id: photo.id) { result, error in
                print("getPhotoSize() result \(String(describing: result))")
                if let result = result {
                    if let lastPhoto = result.size.last {
                        let fetchedPhoto = Photo(context: self.dataController.viewContext)
                        fetchedPhoto.id = photo.id
                        fetchedPhoto.source = URL(string: lastPhoto.source)!
                        fetchedPhoto.pin = self.pin
                        try? self.dataController.viewContext.save()
                        DispatchQueue.main.async {
                            loadedPhotos+=1
                            if (loadedPhotos == singlePhotos.count) { // finished loading all photos
                                self.reloadCollectionView()
                                self.toggleLoading(loading: false)
                            }
                        }
                    }
                } else {
                    // Error, will show placeholder on image
                    print("Error occurred during getPhotoSize: \(error?.localizedDescription)")
                    loadedPhotos+=1
                }
            }
        }
    }
    
    @IBAction func onNewCollectionTap(_ sender: Any) {
        print("onNewCollectionTap()")
        if let fetchedPhotos = fetchedResultsController.fetchedObjects {
            print("onNewCollectionTap() fetchedPhotos \(fetchedPhotos.count)")
            for fetchedPhoto in fetchedPhotos {
                print("onNewCollectionTap() fetchedPhoto \(fetchedPhoto.objectID)")
                dataController.viewContext.delete(fetchedPhoto as NSManagedObject)
                try? dataController.viewContext.save()
            }
        }
        numOfDownloadedPhotos = 0
        reloadCollectionView()
        loadPhotos()
    }
}
