//
//  MapKitExtension.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 5/12/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import MapKit

extension MKMapView {
    func fitAllAnnotations() {
        var zoomRect = MKMapRectNull;
        for annotation in annotations {
            let annotationPoint = MKMapPointForCoordinate(annotation.coordinate)
            let pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
        setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsetsMake(40, 40, 40, 40), animated: true)
    }
}


