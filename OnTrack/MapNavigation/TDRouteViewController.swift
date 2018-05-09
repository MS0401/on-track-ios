//
//  3DRouteViewController.swift
//  OnTrack
//
//  Created by Andrei Opanasenko on 1/19/18.
//  Copyright © 2018 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class TDRouteViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var mapView: MKMapView!
    var mapManager = MapManager()
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView?.delegate = self
        self.mapView!.showsUserLocation = true
        self.mapView?.showsBuildings = true
        self.mapView?.mapType = .standard
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        // locationManager.locationServicesEnabled
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        
        if (locationManager.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization))) {
            //locationManager.requestAlwaysAuthorization() // add in plist NSLocationAlwaysUsageDescription
            locationManager.requestWhenInUseAuthorization() // add in plist NSLocationWhenInUseUsageDescription
            self.getDirectionsUsingApple()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blue
            polylineRenderer.lineWidth = 5
            print("done")
            return polylineRenderer
        }
        return MKOverlayRenderer()
    }
    
    func getDirectionsUsingApple() {
        //        let destination =  textfieldToCurrentLocation?.text
        let craigsBend = CLLocationCoordinate2DMake(36.239987, -115.113376)
        mapManager.directionsFromCurrentLocation(to: craigsBend, directionCompletionHandler: { (route, polyline, directionInformation, boudingRegion, error) -> Void in
            
            if (error != nil) {
                print(error!)
            }
            else {
                if let web = self.mapView {
                    DispatchQueue.main.async() {
                       self.removeAllPlacemarkFromMap(shouldRemoveUserLocation: true)
                        web.add(polyline!)
                        web.setVisibleMapRect(boudingRegion!, animated: true)
                        
                        let camera = MKMapCamera()
                        camera.centerCoordinate = (polyline?.coordinate)!
                        camera.altitude = 300
                        camera.heading = 90
                        camera.pitch = 70
                        self.mapView?.camera = camera
                        
                    }
                }
            }
        })
    }
    
    internal func locationManager(_ manager: CLLocationManager,
                                  didChangeAuthorization status: CLAuthorizationStatus) {
        var hasAuthorised = false
        var locationStatus:NSString = ""
        switch status {
        case CLAuthorizationStatus.restricted:
            locationStatus = "Restricted Access"
        case CLAuthorizationStatus.denied:
            locationStatus = "Denied access"
        case CLAuthorizationStatus.notDetermined:
            locationStatus = "Not determined"
        default:
            locationStatus = "Allowed access"
            hasAuthorised = true
        }
        
        if(hasAuthorised == true) {
            getDirectionsUsingApple()
        }
        else {
            print("locationStatus \(locationStatus)")
        }
    }
    
    func removeAllPlacemarkFromMap(shouldRemoveUserLocation:Bool){
        if let mapView = self.mapView {
            for annotation in mapView.annotations{
                if shouldRemoveUserLocation {
                    if annotation as? MKUserLocation !=  mapView.userLocation {
                        mapView.removeAnnotation(annotation as MKAnnotation)
                    }
                }
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
