//
//  MapOverlay.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import MapKit

class Cad {
    
    var name: String?
    var boundary: [CLLocationCoordinate2D] = []
    
    var midCoordinate = CLLocationCoordinate2D()
    var overlayTopLeftCoordinate = CLLocationCoordinate2D()
    var overlayTopRightCoordinate = CLLocationCoordinate2D()
    var overlayBottomLeftCoordinate = CLLocationCoordinate2D()
    var overlayBottomRightCoordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2DMake(overlayBottomLeftCoordinate.latitude,
                                              overlayTopRightCoordinate.longitude)
        }
    }
    
    var overlayBoundingMapRect: MKMapRect {
        get {
            let topLeft = MKMapPointForCoordinate(overlayTopLeftCoordinate)
            let topRight = MKMapPointForCoordinate(overlayTopRightCoordinate)
            let bottomLeft = MKMapPointForCoordinate(overlayBottomLeftCoordinate)
            
            return MKMapRectMake(
                topLeft.x,
                topLeft.y,
                fabs(topLeft.x - topRight.x),
                fabs(topLeft.y - bottomLeft.y))
        }
    }

    init() {
        
        midCoordinate = CLLocationCoordinate2DMake(36.281714, -115.013553)
        overlayTopLeftCoordinate = CLLocationCoordinate2DMake(36.286538, -115.021000)
        overlayTopRightCoordinate = CLLocationCoordinate2DMake(36.286538, -115.005425)
        overlayBottomLeftCoordinate = CLLocationCoordinate2DMake(36.276248, -115.021000)
        
        // Coundown coords
        /*
        midCoordinate = CLLocationCoordinate2DMake(34.088111, -117.292035)
        overlayTopLeftCoordinate = CLLocationCoordinate2DMake(34.092109, -117.294138)
            //34.092096, -117.293974
        //original 34.092016, -117.293958
        overlayTopRightCoordinate = CLLocationCoordinate2DMake(34.092025, -117.289722)
        
        overlayBottomLeftCoordinate = CLLocationCoordinate2DMake(34.085476, -117.293572)
        
        */
        
    }
}
