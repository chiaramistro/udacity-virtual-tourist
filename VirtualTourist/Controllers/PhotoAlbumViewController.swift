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
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var coordinates: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PhotoAlbumViewController viewDidLoad()")
    
        mapView.delegate = self
        
        initCollectionView()
        
        loadLocation()
        loadPhotos()
    }
    
    func initCollectionView() {
        print("initCollectionView()")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView!.reloadData()
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
    
    func loadPhotos() {
        print("loadPhotos()")
        
        FlickrClient.getPhotosOnLocation(lat: coordinates.latitude, lon: coordinates.longitude) { result, error in
            print("getPhotosOnLocation() result \(String(describing: result))")
        }
    }
    
    @IBAction func onNewCollectionTap(_ sender: Any) {
        print("onNewCollectionTap()")
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("collectionView cell")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        let downloadedImage = UIImage(named: "image-placeholder")
        cell.image.image = downloadedImage
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("collectionView select()")
    }
}
