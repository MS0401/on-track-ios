//
//  RouteCollectionViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/30/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit

class RouteCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var routeNameLabel: UILabel!
    @IBOutlet weak var changeRouteButton: UIButton!
    @IBOutlet weak var viewMapButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mapView.delegate = self
        mapView.layer.cornerRadius = 8
    }
    
    func setupCell(route: RealmRoute) {
        routeNameLabel.text = route.name
        let center = CLLocationCoordinate2D(latitude: Double((route.zones.first?.latitude)!), longitude: Double((route.zones.first?.longitude)!))
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
        
        mapView.setRegion(region, animated: false)
    }
}

extension RouteCollectionViewCell: MKMapViewDelegate {
    
}
