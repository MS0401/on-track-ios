//
//  MKRouteMapViewController.swift
//  OnTrack
//
//  Created by Andrei Opanasenko on 1/16/18.
//  Copyright © 2018 Peter Hitchcock. All rights reserved.
//

import UIKit
import Turf
import MapKit

class MKRouteMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKNavigationMapView!
    @IBOutlet weak var overviewButton: UIButton!
    @IBOutlet weak var recenterButton: UIButton!
    @IBOutlet weak var wayNameLabel: UILabel!
    @IBOutlet weak var wayNameView: UIView!
//    @IBOutlet weak var instructionsBannerContainerView: InstructionsBannerContentView!
//    @IBOutlet weak var instructionsBannerView: InstructionsBannerView!
//    @IBOutlet weak var bottomBannerView: BottomBannerView!
    
    var pendingCamera: MKMapCamera?
   
    var tiltedCamera: MKMapCamera {
        get {
            let camera = mapView.camera
            camera.altitude = 1000
            camera.pitch = 45
            return camera
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.directions = MKDirections()
        super.init(coder: aDecoder)
    }
    
    let distanceFormatter = DistanceFormatter1(approximate: true)
//    var arrowCurrentStep: RouteStep?
    var isInOverviewMode = false {
        didSet {
            if isInOverviewMode {
                overviewButton.isHidden = true
                recenterButton.isHidden = false
                wayNameView.isHidden = true
//                mapView.logoView.isHidden = true
            } else {
                overviewButton.isHidden = false
                recenterButton.isHidden = true
//                mapView.logoView.isHidden = false
            }
        }
    }
    var currentLegIndexMapped = 0
    
    /**
     A Boolean value that determines whether the map annotates the locations at which instructions are spoken for debugging purposes.
     */
    var annotatesSpokenInstructions = false
    
    /**
     The Directions object used to create the route.
     */
    @objc public var directions: MKDirections
    
    /**
     The route controller’s associated location manager.
     */
    @objc public var locationManager: MKNavigationLocationManager! {
        didSet {
            oldValue?.delegate = nil
            locationManager.delegate = self
        }
    }
    
    /**
     Starts monitoring the user’s location along the route.
     
     Will continue monitoring until `suspendLocationUpdates()` is called.
     */
    @objc public func resume() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    /**
     Stops monitoring the user’s location along the route.
     */
    @objc public func suspendLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    /**
     The most recently received user location.
     
     This is a raw location received from `locationManager`. To obtain an idealized location, use the `location` property.
     */
    var rawLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()

        automaticallyAdjustsScrollViewInsets = false
        
        self.locationManager.delegate = self
        UIDevice.current.isBatteryMonitoringEnabled = true
        resume()
        
        let lasVegas = CLLocationCoordinate2D(latitude: 36.1347, longitude: -115.1548)
        
        UIView.animate(withDuration: 1.0, delay: 0, options: [.curveLinear, .beginFromCurrentState], animations: {
            
            let camera = MKMapCamera()
            camera.centerCoordinate = lasVegas
            camera.altitude = 100.0
            camera.pitch = 70
            camera.heading = 0
            self.mapView.mapType = .standard
            self.mapView.isPitchEnabled = true
            self.mapView.showsBuildings = true
            self.mapView.camera = camera
            
        }, completion: nil)
        
        mapView.tracksUserCourse = true
        mapView.courseTrackingDelegate = self
        
        overviewButton.applyDefaultCornerRadiusShadow(cornerRadius: overviewButton.bounds.midX)
        
        wayNameView.layer.borderWidth = 1.0 / UIScreen.main.scale
        wayNameView.applyDefaultCornerRadiusShadow()
        isInOverviewMode = false
        resumeNotifications()
    }
    
    deinit {
        suspendNotifications()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.showsCompass = false
        mapView.tracksUserCourse = true
        
        if let camera = pendingCamera {
            mapView.camera = camera
        } else if let location = self.rawLocation, location.course > 0 {
            mapView.updateCourseTracking(location: location, animated: false)
//        } else if let coordinates = routeController.routeProgress.currentLegProgress.currentStep.coordinates, let firstCoordinate = coordinates.first, coordinates.count > 1 {
//            let secondCoordinate = coordinates[1]
//            let course = firstCoordinate.direction(to: secondCoordinate)
//            let newLocation = CLLocation(coordinate: routeController.location?.coordinate ?? firstCoordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: course, speed: 0, timestamp: Date())
//            mapView.updateCourseTracking(location: newLocation, animated: false)
        } else {
            mapView.setCamera(tiltedCamera, animated: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)), name: .UIApplicationWillEnterForeground, object: nil)
        
    }
    
    func suspendNotifications() {
        
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        
    }
    
    @IBAction func recenter(_ sender: Any) {
        mapView.tracksUserCourse = true
        isInOverviewMode = false
        updateCameraAltitude()
        
    }
    
    @IBAction func toggleOverview(_ sender: Any) {
        
        updateVisibleBounds()
        isInOverviewMode = true
    }
    
    func updateCameraAltitude() {
        guard mapView.tracksUserCourse else { return } //only adjust when we are actively tracking user course
        
        let defaultAltitude = MKNavigationMapView.defaultAltitude
        setCamera(altitude: defaultAltitude)
    }
    
    private func setCamera(altitude: Double) {
        guard mapView.altitude != altitude else { return }
        mapView.altitude = altitude
    }
    
    func updateVisibleBounds() {
        
        guard let userLocation = self.locationManager.location?.coordinate else { return }
        
        let overviewContentInset = UIEdgeInsets(top: 80, left: 20, bottom: 20, right: 20)
//        let slicedLine = Polyline(routeController.routeProgress.route.coordinates!).sliced(from: userLocation, to: routeController.routeProgress.route.coordinates!.last).coordinates
//        let line = MKPolyline(coordinates: slicedLine, count: UInt(slicedLine.count))
        
        mapView.tracksUserCourse = false
        let camera = mapView.camera
        camera.pitch = 0
        camera.heading = 0
        mapView.camera = camera
        
        // Don't keep zooming in
//        guard line.overlayBounds.ne.distance(to: line.overlayBounds.sw) > 200 else { return }
        
        mapView.fitAllAnnotations()
    }
    
    @objc func applicationWillEnterForeground(notification: NSNotification) {
        mapView.updateCourseTracking(location: self.rawLocation, animated: false)
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

extension MKRouteMapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        self.rawLocation = location
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "locationDidChange"), object: self, userInfo: ["location": location])
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
    }
}

extension MKRouteMapViewController: MKNavigationMapViewCourseTrackingDelegate {
    func MKNavigationMapViewDidStartTrackingCourse(_ mapView: MKNavigationMapView) {
        recenterButton.isHidden = true
//        mapView.logoView.isHidden = false
    }
    
    func MKNavigationMapViewDidStopTrackingCourse(_ mapView: MKNavigationMapView) {
        recenterButton.isHidden = false
//        mapView.logoView.isHidden = true
    }
}
