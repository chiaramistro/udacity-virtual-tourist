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
    
    var pin: Pin!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var numOfPhotos: Int = 0
    
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
        
        if let photos = fetchedResultsController.fetchedObjects {
            if (photos.isEmpty) {
                // try to load some photos
                FlickrClient.getPhotosOnLocation(lat: pin.latitude, lon: pin.longitude) { result, error in
                    print("getPhotosOnLocation() result \(String(describing: result))")
                    // if result is still empty, then show empty state
                    if let result = result {
                        if (result.pages > 0) {
                            self.fetchPhotoSources(photos: result.photo)
                        } else {
                            print("Empty state")
                        }
                    } else {
                        // Error empty state
                        print("Error occurred during getPhotosOnLocation: \(error?.localizedDescription)")
                    }
                }
            } else {
                numOfPhotos = photos.count
            }
        }
    }
    
    func fetchPhotoSources(photos: [SinglePhoto]) {
        print("fetchPhotoSources()")
        numOfPhotos = photos.count
        
        for photo in photos {
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
                            self.collectionView!.reloadData()
                        }
                    }
                } else {
                    // Error
                    print("Error occurred during getPhotoSize: \(error?.localizedDescription)")
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
        return numOfPhotos
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("collectionView cell \(indexPath)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        let downloadedImage = UIImage(named: "image-placeholder")
        cell.image.image = downloadedImage
        
        let thePhoto = fetchedResultsController.object(at: indexPath)
        
        if let photoUrl = thePhoto.source {
            FlickrClient.getImage(url: photoUrl) { photo, error in
                DispatchQueue.main.async {
                    if let photo = photo {
                        let image = UIImage(data: photo)
                        cell.image.image = image
                    } else {
                        // Some error occurred, show placeholder
                        print("Error occurred during getImage: \(error?.localizedDescription)")
                        let downloadedImage = UIImage(named: "image-placeholder")
                        cell.image.image = downloadedImage
                    }
                }
            }
        } else {
            print("Error occurred with photo source")
            let downloadedImage = UIImage(named: "image-placeholder")
            cell.image.image = downloadedImage
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("collectionView select()")
    }
}
