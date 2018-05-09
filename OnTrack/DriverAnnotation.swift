//
//  DriverAnnotation.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 2/3/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import MapKit

class DriverAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var name: String!
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

