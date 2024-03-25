//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Chiara Mistrorigo on 25/03/24.
//

import UIKit

class TravelLocationsMapViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("TravelLocationsMapViewController viewDidLoad()")
    }
    
    
    @IBAction func goToPhotoAlbum(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showPhotoAlbum", sender: nil)
    }

}

