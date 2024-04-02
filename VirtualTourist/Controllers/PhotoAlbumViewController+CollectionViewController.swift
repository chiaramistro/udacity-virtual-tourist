//
//  PhotoAlbumViewController+CollectionViewController.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 02/04/24.
//

import UIKit

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func reloadCollectionView() {
        setupFetchedResultsController()
        collectionView!.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("collectionView cell \(indexPath.row)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        let downloadedImage = UIImage(named: "image-placeholder")
        cell.image.image = downloadedImage
        
        let thePhoto = fetchedResultsController.object(at: indexPath)
        
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
        if (numOfDownloadedPhotos == totalNumOfPhotos) {
            print("Finished with numOfDownloadedPhotos!")
            newCollectionButton.isEnabled = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("collectionView select() \(indexPath)")
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
        reloadCollectionView()
    }
}