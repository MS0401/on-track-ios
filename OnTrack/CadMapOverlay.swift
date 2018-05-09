//
//  CadMapOverlay.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit

class CadMapOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    
    init(cad: Cad) {
        boundingMapRect = cad.overlayBoundingMapRect
        coordinate = cad.midCoordinate
    }
}
