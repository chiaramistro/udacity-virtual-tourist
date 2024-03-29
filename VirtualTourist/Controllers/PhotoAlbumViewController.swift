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
    var photos: [Photo] = []
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var numOfDownloadedPhotos: Int = 0
    
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
    
    fileprivate func setupFetchedResultsController() {
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
                        if (result.pages > 0) {
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
                photos = fetchedPhotos
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
        photos = [] // reset
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
                            self.photos.append(fetchedPhoto)
                            if (loadedPhotos == singlePhotos.count) { // finished loading all photos
                                self.toggleLoading(loading: false)
                                self.collectionView!.reloadData()
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
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("collectionView cell \(indexPath.row)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        let downloadedImage = UIImage(named: "image-placeholder")
        cell.image.image = downloadedImage
        
        let thePhoto = photos[indexPath.row]
        
        if let photoData = thePhoto.image {
            print("Photo DOES have data")
            // image has data saved in storage, take that
            let image = UIImage(data: photoData)
            cell.image.image = image
            handleDownloadedPhoto()
        } else {
            print("Photo DOES NOT have data, check for source")
            if let photoUrl = thePhoto.source {
                print("Photo DOES have source, download image")
                FlickrClient.getImage(url: photoUrl) { photo, error in
                    print("getImage() result \(String(describing: photo))")
                    DispatchQueue.main.async {
                        if let photo = photo {
                            print("getImage() successful")
                            thePhoto.image = photo
                            let image = UIImage(data: photo)
                            cell.image.image = image
                            self.handleDownloadedPhoto()
                        } else {
                            // Some error occurred, show placeholder
                            print("Error occurred during getImage: \(error?.localizedDescription)")
                            let downloadedImage = UIImage(named: "image-placeholder")
                            cell.image.image = downloadedImage
                            self.handleDownloadedPhoto()
                        }
                    }
                }
            } else {
                print("Photo DOES NOT have source")
                let downloadedImage = UIImage(named: "image-placeholder")
                cell.image.image = downloadedImage
                handleDownloadedPhoto()
            }
        }
        
        return cell
    }
    
    func handleDownloadedPhoto() {
        print("handleDownloadedPhoto()")
        numOfDownloadedPhotos+=1
        print("handleDownloadedPhoto() numOfDownloadedPhotos\(numOfDownloadedPhotos)")
        if (numOfDownloadedPhotos == photos.count) {
            print("Finished with numOfDownloadedPhotos!")
            newCollectionButton.isEnabled = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("collectionView select()")
        let thePhoto = photos[indexPath.row]
        dataController.viewContext.delete(thePhoto)
        photos.remove(at: indexPath.row)
        try? dataController.viewContext.save()
        self.collectionView!.reloadData()
    }
}
