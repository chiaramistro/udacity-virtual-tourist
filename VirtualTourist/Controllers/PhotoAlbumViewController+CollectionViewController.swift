//
//  PhotoAlbumViewController+CollectionViewController.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 02/04/24.
//

import UIKit

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Collection view delegate and utility methods
    
    func initCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView!.reloadData()
    }
    
    func reloadCollectionView() {
        setupFetchedResultsController()
        collectionView!.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        let downloadedImage = UIImage(named: "image-placeholder")
        cell.image.image = downloadedImage
        
        let thePhoto = fetchedResultsController.object(at: indexPath)
        
        if let photoData = thePhoto.image {
            debugPrint("Photo DOES have data")
            // image has data saved in storage, take that
            let image = UIImage(data: photoData)
            cell.image.image = image
            handleDownloadedPhoto()
        } else {
            debugPrint("Photo DOES NOT have data, check for source")
            if let photoUrl = thePhoto.source {
                debugPrint("Photo DOES have source, download image")
                FlickrClient.getImage(url: photoUrl) { photo, error in
                    DispatchQueue.main.async {
                        if let photo = photo {
                            thePhoto.image = photo
                            let image = UIImage(data: photo)
                            cell.image.image = image
                            self.handleDownloadedPhoto()
                        } else {
                            // Some error occurred during picture fetching (we will show placeholder)
                            debugPrint("Error occurred during getImage: \(error?.localizedDescription)")
                            let downloadedImage = UIImage(named: "image-placeholder")
                            cell.image.image = downloadedImage
                            self.handleDownloadedPhoto()
                        }
                    }
                }
            } else {
                debugPrint("Photo DOES NOT have source")
                let downloadedImage = UIImage(named: "image-placeholder")
                cell.image.image = downloadedImage
                handleDownloadedPhoto()
            }
        }
        
        return cell
    }
    
    // If all photos were downloaded, allow user to ask for new collection
    func handleDownloadedPhoto() {
        numOfDownloadedPhotos+=1
        if (numOfDownloadedPhotos == totalNumOfPhotos) {
            newCollectionButton.isEnabled = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
        debugPrint("Photo deleted successfully")
        reloadCollectionView()
    }
}
