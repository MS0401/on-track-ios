//
//  MapScansViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/4/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit

class MapScansViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension MapScansViewController: MKMapViewDelegate {
    
}
