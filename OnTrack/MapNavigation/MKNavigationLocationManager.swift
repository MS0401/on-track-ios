//
//  MKNavigationLocationManager.swift
//  OnTrack
//
//  Created by Andrei Opanasenko on 1/17/18.
//  Copyright © 2018 Peter Hitchcock. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

/**
 `MKNavigationLocationManager` is the base location manager which handles
 permissions and background modes.
 */

open class MKNavigationLocationManager: CLLocationManager {
    
    var lastKnownLocation: CLLocation?
    
    override public init() {
        super.init()
        
//        let always = Bundle.main.locationAlwaysUsageDescription
//        let both = Bundle.main.locationAlwaysAndWhenInUseUsageDescription
//        
//        if always != nil || both != nil {
//            requestAlwaysAuthorization()
//        } else {
//            requestWhenInUseAuthorization()
//        }
//        
//        if #available(iOS 9.0, *) {
//            if Bundle.main.backgroundModes.contains("location") {
//                allowsBackgroundLocationUpdates = true
//            }
//        }
        
        desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }
}
