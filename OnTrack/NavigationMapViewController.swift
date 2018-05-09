//
//  NavigationMapViewController.swift
//  OnTrack
//
//  Created by Andrei Opanasenko on 1/12/18.
//  Copyright © 2018 Peter Hitchcock. All rights reserved.
//  com.ontrackteam.OnTrack

import UIKit
import MapKit
import MapboxNavigation
import AVFoundation
import Turf

class NavigationMapViewController: UIViewController, MKMapViewDelegate {
    
    //MARK: Properties and Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var overviewButton: UIButton!
    @IBOutlet weak var recenterButton: UIButton!
    @IBOutlet weak var wayNameLabel: UILabel!
    @IBOutlet weak var wayNameView: UIView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var toggleOverView: UIView!
    @IBOutlet weak var recenterView: UIView!
    @IBOutlet weak var instructionBannerView: UIView!
    @IBOutlet weak var totalDurationLabel: UILabel!
    @IBOutlet weak var totalDistanceLabel: UILabel!
    @IBOutlet weak var stepDistanceLabel: UILabel!
    @IBOutlet weak var blue_circle: UIImageView!
    
    let speechSynthesizer = AVSpeechSynthesizer()
    var waypoints: [CLLocationCoordinate2D] = []
    var initialCoordinate: CLLocationCoordinate2D!
    let distanceFormatter = DistanceFormatter1(approximate: true)
    var isInOverviewMode = false {
        didSet {
            if isInOverviewMode {
                toggleOverView.isHidden = true
                recenterView.isHidden = false

            } else {
                toggleOverView.isHidden = false
                recenterView.isHidden = true
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
    /**
     The route controller’s associated location manager.
     */
    let locationManager = CLLocationManager()
    var mapManager = MapManager()
    var currentLocationDirection: CLLocationDirection!
    var steps = [MKRouteStep]()
    var stepCounter = 0
    
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
    
    //MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        UIDevice.current.isBatteryMonitoringEnabled = true
        toggleOverView.layer.borderColor = UIColor.green.cgColor
        toggleOverView.layer.cornerRadius = toggleOverView.frame.height / 2
        recenterView.layer.borderColor = UIColor.green.cgColor
        recenterView.layer.cornerRadius = 10
        isInOverviewMode = false
        resumeNotifications()
        
        self.mapView?.delegate = self
        self.mapView!.showsUserLocation = true
        self.mapView?.showsBuildings = true
        self.mapView?.mapType = .standard
        self.mapView.userTrackingMode = .followWithHeading
        self.mapView.showsCompass = false
        
        UIView.animate(withDuration: 1.0, delay: 0, options: [.curveLinear, .beginFromCurrentState], animations: {
            
            let camera = MKMapCamera()
            camera.altitude = 1000.0
            camera.pitch = 90
            camera.heading = 0
            camera.centerCoordinate = self.waypoints.first!
            self.mapView.camera = camera
        }, completion: nil)
        
        locationManager.delegate = self
        
        //MARK: Request permission to use Location service
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()

        //MARK: Start the update of user's Location
        if CLLocationManager.locationServicesEnabled() {
            
            //MARK: Location Accuracy, properties
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.allowsBackgroundLocationUpdates = true
            
            
            resume()
        }
        
        //MARK: UIPanGestureRecorgnizer initialize
        let recognizer = UITapGestureRecognizer(target: self,
                                                action:#selector(handleTap(recognizer:)))
        recognizer.delegate = self
        self.mapView.addGestureRecognizer(recognizer)
        recognizer.require(toFail: mapPan)
    }
    
    //MARK: MKMapViewDelegate method.
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polygonView = MKPolylineRenderer(overlay: overlay)
            polygonView.strokeColor = UIColor(red: 77/255, green: 215/255, blue: 250/255, alpha: 1.0)
            return polygonView
        }
        return MKOverlayRenderer()
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        guard let location = userLocationForCourseTracking else { return }
        
        userCourseView?.center = self.mapView.convert(location.coordinate, toPointTo: self.mapView)
    }
    
    deinit {
        suspendNotifications()
        UIDevice.current.isBatteryMonitoringEnabled = false
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(GetttingPolylineAndSetGeofencing), object: nil)
    }
   
    var routeCoordinates: [CLLocationCoordinate2D] = []
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: NSNotification.Name(rawValue: "locationDidChange"), object: nil)

    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "locationDidChange"), object: nil)
    }
    
    private lazy var mapTapGesture = UITapGestureRecognizer(target: self, action: #selector(didRecieveTap(sender:)))

    //MARK: TapGestureRecognizer
    
    /**
     Fired when NavigationMapView detects a tap not handled elsewhere by other gesture recognizers.
     */
    @objc func didRecieveTap(sender: UITapGestureRecognizer) {
        
        print("Map Just Touched")
    }
    
    @IBAction func recenter(_ sender: Any) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(GetttingPolylineAndSetGeofencing), object: nil)
        
        let region = MKCoordinateRegion(center: (self.rawLocation?.coordinate)!, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        self.mapView.setRegion(region, animated: true)
        
        self.GetttingPolylineAndSetGeofencing()
        self.tracksUserCourse = true
        self.activeRoute = true
        displayLink.preferredFramesPerSecond = 3
        isInOverviewMode = false
        self.updateCourseTracking(location: self.rawLocation!, animated: true)
        
    }
    
    @IBAction func toggleOverview(_ sender: Any) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(GetttingPolylineAndSetGeofencing), object: nil)
        displayLink.preferredFramesPerSecond = 3
        updateVisibleBounds()
        isInOverviewMode = true
    }
   
    private func setCamera(altitude: Double) {
        guard self.altitude != altitude else { return }
        self.altitude = altitude
    }
    
    //MARK: When user click toggleOverView Button, this method is called.
    func updateVisibleBounds() {
        
        let camera = mapView.camera
        camera.pitch = 0
        camera.heading = (self.rawLocation?.coordinate)!.direction(to: self.currentStep.polyline.coordinate)
        mapView.camera = camera
        
        mapView.fitAllAnnotations()
        
        self.tracksUserCourse = false
        self.updateCourseTracking(location: self.rawLocation!, animated: true)
        
        
    }
    
    @objc func applicationWillEnterForeground(notification: NSNotification) {
        self.updateCourseTracking(location: self.rawLocation, animated: false)
    }
    
    @objc public var location: CLLocation?
    
    //MARK: MKMapView part
    
    //MARK: Class Constants
    
    /**
     Returns the altitude that the map camera initally defaults to.
     */
    @objc public static let defaultAltitude: CLLocationDistance = 1000.0
    
    /**
     Returns the altitude the map conditionally zooms out to when user is on a motorway, and the maneuver length is sufficently long.
     */
    @objc public static let zoomedOutMotorwayAltitude: CLLocationDistance = 2000.0
    
    /**
     Returns the threshold for what the map considers a "long-enough" maneuver distance to trigger a zoom-out when the user enters a motorway.
     */
    @objc public static let longManeuverDistance: CLLocationDistance = 1000.0
    
    /**
     Maximum distnace the user can tap for a selection to be valid when selecting an alternate route.
     */
    @objc public var tapGestureDistanceThreshold: CGFloat = 50
    
    var userLocationForCourseTracking: CLLocation?
    var isPluggedIn: Bool = false
    var batteryStateObservation: NSKeyValueObservation?
    var altitude: CLLocationDistance = defaultAltitude
    var currentRoute: MKRoute!

    //MARK: When user's location is updated, this method is called.
    @objc func progressDidChange(_ notification: Notification) {
        guard tracksUserCourse else { return }
        
        self.userLocationForCourseTracking = notification.userInfo!["location"] as? CLLocation
        
        self.updateCourseTracking(location: self.userLocationForCourseTracking, animated: true)
        
    }
    
    
     @IBOutlet var mapPan: UIPanGestureRecognizer!
    
    private lazy var displayLink : CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(NavigationMapViewController.updatePoint))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        return displayLink
    }()
    
    @objc func updatePoint() {
        
        guard let location = userLocationForCourseTracking else { return }
        userCourseView?.layer.removeAllAnimations()
        userCourseView?.center = self.mapView.convert(location.coordinate, toPointTo: self.mapView)
    }
    
    //MARK: When user tap, pan, rotate, this method detact
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        print("Map just tapped.")
        self.tracksUserCourse = false
        guard let location = userLocationForCourseTracking else { return }
        userCourseView?.layer.removeAllAnimations()
        userCourseView?.center = self.mapView.convert(location.coordinate, toPointTo: self.mapView)
    }
    
    @IBAction func handlePan(recognizer: UIPanGestureRecognizer) {
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(GetttingPolylineAndSetGeofencing), object: nil)
        
        self.tracksUserCourse = false
        isInOverviewMode = true
        displayLink.preferredFramesPerSecond = 60
        
        if recognizer.state == .ended {
            displayLink.preferredFramesPerSecond = 2
        }

        if recognizer.state == .ended || recognizer.state == .cancelled {
            let velocity = recognizer.velocity(in: self.mapView)
            let didFling = sqrt(velocity.x * velocity.x + velocity.y * velocity.y) > 100
            if didFling {
                displayLink.preferredFramesPerSecond = 1
            }
        }
        
        if recognizer.state == .changed {
            guard let location = userLocationForCourseTracking else { return }
            userCourseView?.layer.removeAllAnimations()
            userCourseView?.center = self.mapView.convert(location.coordinate, toPointTo: self.mapView)
        }
    }
    
    @IBAction func handlePinch(recognizer : UIPinchGestureRecognizer) {
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(GetttingPolylineAndSetGeofencing), object: nil)
        
        self.tracksUserCourse = false
        if recognizer.state == .changed {
            guard let location = userLocationForCourseTracking else { return }
            userCourseView?.layer.removeAllAnimations()
            userCourseView?.center = self.mapView.convert(location.coordinate, toPointTo: self.mapView)
        }
    }
    
    @IBAction func handleRotate(recognizer : UIRotationGestureRecognizer) {
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(GetttingPolylineAndSetGeofencing), object: nil)
        
        self.tracksUserCourse = false
        if recognizer.state == .changed {
            guard let location = userLocationForCourseTracking else { return }
            userCourseView?.layer.removeAllAnimations()
            userCourseView?.center = self.mapView.convert(location.coordinate, toPointTo: self.mapView)
        }
    }

    open var showsUserLocation: Bool {
        get {
            if tracksUserCourse || userLocationForCourseTracking != nil {
                return !(userCourseView?.isHidden ?? true)
            }
            return true
        }
        set {
            if tracksUserCourse || userLocationForCourseTracking != nil {
                self.mapView.showsUserLocation = false
                
                if userCourseView == nil {
                    userCourseView = UserPuckCourseView1(frame: CGRect(origin: .zero, size: CGSize(width: 75, height: 75)))
                }
                userCourseView?.isHidden = !newValue
            } else {
                userCourseView?.isHidden = true
                self.mapView.showsUserLocation = newValue
            }
        }
    }
    
    //MARK: Update user's location heading and location, camera setting and so on.
    @objc public func updateCourseTracking(location: CLLocation?, animated: Bool) {
        
        guard let location = location, CLLocationCoordinate2DIsValid(location.coordinate) else {
            return
        }
        
        if tracksUserCourse {
            
            UIView.animate(withDuration: 1.0, delay: 0, options: [.curveLinear, .beginFromCurrentState], animations: {
                
                if self.activeRoute {
                    self.activeRoute = false
                    let camera = MKMapCamera()
                    camera.centerCoordinate = location.coordinate
                    camera.altitude = 300.0
                    camera.pitch = 45
                    let direction = location.coordinate.direction(to: self.currentStep.polyline.coordinate)//location.course//
                    camera.heading = direction
                    print(location.course)
                    self.mapView.camera = camera
                    
                }
            }, completion: nil)
            
        }
        
        let duration: TimeInterval = animated ? 1 : 0
        
        
        UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear, .beginFromCurrentState], animations: {
            
            print("Center Changed")
            self.userCourseView?.center = self.mapView.convert(location.coordinate, toPointTo: self.mapView)
            
            
        }, completion: nil)
        
        if let userCourseView = userCourseView as? UserCourseView1 {
            userCourseView.update(location: location, pitch: self.mapView.camera.pitch, direction: location.course, animated: animated, tracksUserCourse: tracksUserCourse)//self.mapView.camera.heading
        }
    }
    
    
    @objc var tracksUserCourse: Bool = false {
        didSet {
            if tracksUserCourse {
                showsUserLocation = true
            }
            if let location = userLocationForCourseTracking {
                updateCourseTracking(location: location, animated: true)
            }
        }
    }
    
    var activeRoute: Bool = false
    var currentStep: MKRouteStep!
    
    //MAKR: Getting Route
    func GetAppleRouteFirst(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        mapManager.directions(from: from, to: to, directionCompletionHandler: { (route, polyline, directionInformation, boudingRegion, error) -> Void in
            
            if (error != nil) {
                print(error!)
            }
            else {
                if let web = self.mapView {
                    DispatchQueue.main.async() {
                        
                        self.activeRoute = true
                        self.currentRoute = route!
                        
                        //MARK: Setting Geofencing
                        if self.stepCounter == 0 {
                            self.SetGeofencing(route: self.currentRoute)
                        }else {
                            self.SetGeofencing1(route: self.currentRoute)
                        }
                        
                        self.currentStep = self.currentRoute.steps[0]
                        self.removeAllPlacemarkFromMap(shouldRemoveUserLocation: true)
                        web.add((route?.polyline)!)
                        
                        //MARK: Set Camera
                        let camera = MKMapCamera()
                        camera.centerCoordinate = (self.rawLocation?.coordinate)!
                        camera.altitude = 300
                        
                        let endLocDict = directionInformation!["end_location"] as! [String: CLLocationDegrees]
                        let endLoc = CLLocationCoordinate2DMake(endLocDict["lat"]!, endLocDict["lng"]!)
                        
                        camera.heading = self.GetRotateAngle(from: self.steps[0].polyline.coordinate, to: self.steps[1].polyline.coordinate)
                        camera.pitch = 70
                        self.mapView?.camera = camera
                        
                        //MARK: Start annontation
                        let start = MKPointAnnotation()
                        start.coordinate = self.steps[0].polyline.coordinate
                        print("Start location \(self.steps[0].polyline.coordinate)")
                        start.title = "Start"
                        self.mapView.addAnnotation(start)
                        
                        //MARK: Destination annontation
                        let destination = MKPointAnnotation()
                        destination.coordinate = endLoc//self.steps[self.steps.count - 1].polyline.coordinate
                        self.endCoordinate = endLoc
                        destination.title = "Destination"
                        self.mapView.addAnnotation(destination)
                        
                        self.tracksUserCourse = true
                        
                        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.GetttingPolylineAndSetGeofencing), object: nil)
                        self.currentDistance = 0
                        self.GetttingPolylineAndSetGeofencing()
//                        if self.steps[0].polyline.coordinate.distance(to: (self.rawLocation?.coordinate)!) < 10 {
//
//                        }else {
//                            let region = CLCircularRegion(center: self.steps[0].polyline.coordinate,
//                                                          radius: 10,
//                                                          identifier: "didstart")
//                            region.notifyOnEntry = true
//                            //                            region.notifyOnExit = true
//                            self.locationManager.startMonitoring(for: region)
//                        }
                    }
                }
            }
        })
    }
    
    func GetAppleRoute(coordinate: CLLocationCoordinate2D) {

        mapManager.directionsFromCurrentLocation(to: coordinate, directionCompletionHandler: { (route, polyline, directionInformation, boudingRegion, error) -> Void in
            
            if (error != nil) {
                print(error!)
            }
            else {
                if let web = self.mapView {
                    DispatchQueue.main.async() {
                        
                        self.activeRoute = true
                        self.currentRoute = route!
                        
                        //MARK: Setting Geofencing
                        if self.stepCounter == 0 {
                            self.SetGeofencing(route: self.currentRoute)
                        }else {
                            self.SetGeofencing1(route: self.currentRoute)
                        }
                        
                        self.currentStep = self.currentRoute.steps[0]
                        self.removeAllPlacemarkFromMap(shouldRemoveUserLocation: true)
                        web.add((route?.polyline)!)
                        
                        //MARK: Set Camera
                        let camera = MKMapCamera()
                        camera.centerCoordinate = (self.rawLocation?.coordinate)!
                        camera.altitude = 300
                        
                        let endLocDict = directionInformation!["end_location"] as! [String: CLLocationDegrees]
                        let endLoc = CLLocationCoordinate2DMake(endLocDict["lat"]!, endLocDict["lng"]!)
                        
                        camera.heading = self.GetRotateAngle(from: self.steps[0].polyline.coordinate, to: self.steps[1].polyline.coordinate)
                        camera.pitch = 70
                        self.mapView?.camera = camera
                        
                        //MARK: Start annontation
                        let start = MKPointAnnotation()
                        start.coordinate = self.steps[0].polyline.coordinate
                        print("Start location \(self.steps[0].polyline.coordinate)")
                        start.title = "Start"
                        self.mapView.addAnnotation(start)
                        
                        //MARK: Destination annontation
                        let destination = MKPointAnnotation()
                        destination.coordinate = endLoc//self.steps[self.steps.count - 1].polyline.coordinate
                        self.endCoordinate = endLoc
                        destination.title = "Destination"
                        self.mapView.addAnnotation(destination)
                        
                        self.tracksUserCourse = true
                        
                        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.GetttingPolylineAndSetGeofencing), object: nil)
                        self.currentDistance = 0
                        self.GetttingPolylineAndSetGeofencing()                        
                    }
                }
            }
        })
    }
    
    //MARK: Getting location heading
    func GetRotateAngle(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fLat: Double = degreesToRadians(x: from.latitude)
        let fLng: Double = degreesToRadians(x: from.longitude)
        let tLat: Double = degreesToRadians(x: to.latitude)
        let tLng: Double = degreesToRadians(x: to.longitude)
        let degree: Double = radiansToDegrees(x: Double(atan2(sin(tLng - fLng) * cos(tLat), cos(fLat) * sin(tLat) - sin(fLat) * cos(tLat) * cos(tLng - fLng))))
        if degree >= 0 {
            return degree
        }
        else {
            return 360 + degree
        }
    }
    
    func degreesToRadians(x: Double) -> Double {
        return .pi * x / 180.0
    }
    func radiansToDegrees(x: Double) -> Double {
        return x * 180.0 / .pi
    }
    
    func showAlert(_ title: String, message: String) {
        
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alertView.view.tintColor = UIColor(netHex: 0xFF7345)
        
        self.present(alertView, animated: true, completion: nil)
    }
    
    //MARK: Set Geofencing
    func SetGeofencing(route: MKRoute) {
        
        self.steps = route.steps
        
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert("Error", message: "Geofencing is not supported on this device!")
            return
        }
        
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            showAlert("Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
        }
        
        for i in 0 ..< self.steps.count {
            
            let step = self.steps[i]
            
            let region = CLCircularRegion(center: step.polyline.coordinate,
                                          radius: 10,
                                          identifier: "\(i)")
            region.notifyOnEntry = true
            region.notifyOnExit = true
            self.locationManager.startMonitoring(for: region)
            
        }
        
        for i in self.steps {
            print(self.steps.count)
            print("stepDistance \(i.distance)")
            print("stepInstruction \(i.instructions)")
        }
        
        let initialMessage = "\(self.steps[0].instructions)"
        self.instructionLabel.text = initialMessage
        let stepdistance = "\(self.steps[1].distance) m"
        self.stepDistance = self.steps[1].distance
        self.stepDistanceLabel.text = stepdistance
        let totalDistance = "\(self.currentRoute.distance) m"
        self.totalDistanceLabel.text = totalDistance
        let totalDuration = self.currentRoute.expectedTravelTime.stringTime
        self.totalDurationLabel.text = totalDuration
        let speechUtterance = AVSpeechUtterance(string: initialMessage)
        self.speechSynthesizer.speak(speechUtterance)
        self.stepCounter += 1
    }
    func SetGeofencing1(route: MKRoute) {
        
        self.locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })
        self.steps = route.steps
        
        let initialMessage = "\(self.steps[0].instructions)"
        self.instructionLabel.text = initialMessage
        let stepdistance = "\(self.steps[1].distance) m"
        self.stepDistance = self.steps[1].distance
        self.stepDistanceLabel.text = stepdistance
        let totalDistance = "\(self.currentRoute.distance) m"
        self.totalDistanceLabel.text = totalDistance
        let totalDuration = self.currentRoute.expectedTravelTime.stringTime
        self.totalDurationLabel.text = totalDuration
        let speechUtterance = AVSpeechUtterance(string: initialMessage)
        self.speechSynthesizer.speak(speechUtterance)
        self.stepCounter += 1
        
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert("Error", message: "Geofencing is not supported on this device!")
            return
        }
        
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            showAlert("Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
        }
        
        for i in 0 ..< route.steps.count {
            
            let step = route.steps[i]
            
            let region = CLCircularRegion(center: step.polyline.coordinate,
                                          radius: 10,
                                          identifier: "\(i)")
            region.notifyOnEntry = true
            region.notifyOnExit = true
            self.locationManager.startMonitoring(for: region)
        }
        
        for i in self.steps {
            print("stepDistance \(i.distance)")
        }
    }
    
    func removeAllPlacemarkFromMap(shouldRemoveUserLocation:Bool){
        for annotation in self.mapView.annotations{
            if shouldRemoveUserLocation {
                if annotation as? MKUserLocation !=  self.mapView.userLocation {
                    self.mapView.removeAnnotation(annotation as MKAnnotation)
                }
            }
        }
    }
    
    /**
     A `UIView` used to indicate the user’s location and course on the map.
     
     If the view conforms to `UserCourseView`, its `UserCourseView.update(location:pitch:direction:animated:)` method is frequently called to ensure that its visual appearance matches the map’s camera.
     */
    @objc public var userCourseView: UIView? {
        didSet {
            if let userCourseView = userCourseView {
                self.mapView.addSubview(userCourseView)
            }
        }
    }
    
    var routes: [MKRoute]?
    var routeLine = [CLLocationCoordinate2D]()
    var endCoordinate: CLLocationCoordinate2D!
    var currentDistance: CLLocationDistance = 0
    var stepDistance: CLLocationDistance!
    var currentStepDistance: CLLocationDistance = 0
    var onTimer: Timer!
    var routeMistake = false
    
    @objc func GetttingPolylineAndSetGeofencing() {
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(GetttingPolylineAndSetGeofencing), object: nil)
        
        for i in self.currentRoute.steps {
            self.routeLine.append(i.polyline.coordinate)
        }
        self.routeLine.append(self.endCoordinate)
        
        let polyline = Polyline(self.routeLine)
        guard let newCoordinate = polyline.coordinateFromStart(distance: currentDistance) else {
            return
        }
        // Closest coordinate ahead
        guard let lookAheadCoordinate = polyline.coordinateFromStart(distance: currentDistance + 10) else { return }
        
        let currentDirection = newCoordinate.direction(to: lookAheadCoordinate).wrap(min: 0, max: 360)
        
        let camera = self.mapView.camera
        camera.heading = currentDirection
        self.mapView.camera = camera
        
        print("difference directoin \(currentDirection - (self.rawLocation?.course)!)")
        print("current direction \(currentDirection)")
        print("location course \((self.rawLocation?.course)!)")
        print("difference distance \(newCoordinate.distance(to: (self.rawLocation?.coordinate)!))")
        //MARK: Alert current route mistakes.
        if currentDirection.differenceBetween((self.rawLocation?.course)!) > 90 || newCoordinate.distance(to: (self.rawLocation?.coordinate)!) > 30 {
            
            if !self.routeMistake {
                self.routeMistake = true
                let alert = UIAlertController(title: "Warning!", message: "You are seceding from our custom route", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default) { (alert) in
                    self.onTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(NavigationMapViewController.OnTimer), userInfo: nil, repeats: true)
                }
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
            
        }else {
            self.routeMistake = false
            self.onTimer.invalidate()
            self.onTimer = nil
        }
        
        if Int((self.rawLocation?.speed)!) > 0 {
            currentDistance += (self.rawLocation?.speed)! * 1
            currentStepDistance += (self.rawLocation?.speed)! * 1
        }
        
        guard let route = self.currentRoute else { return }
        
        //MARK: Step Distance label text
        self.stepDistanceLabel.text = "\(stepDistance - currentStepDistance) m"
        let totaldistance = route.distance - currentDistance
        self.totalDistanceLabel.text = "\(totaldistance)m"
        let totalduration = (Int(self.currentRoute.expectedTravelTime) / 60 ) % 60
        let traveledDuration = Int((currentDistance / (self.rawLocation?.speed)!).truncatingRemainder(dividingBy: 60))
        let remainingduration = totalduration - traveledDuration
        if remainingduration < 1 {
            self.totalDurationLabel.text = "Less than 1 min"
        }else {
            self.totalDurationLabel.text = "\(remainingduration)min"
        }
        
        perform(#selector(GetttingPolylineAndSetGeofencing), with: nil, afterDelay: 1)
    }
    
    @objc func OnTimer() {
        self.blue_circle.isHidden = !self.blue_circle.isHidden
    }
    
}

extension NavigationMapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        if self.rawLocation == nil && self.stepCounter == 0 {

            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            self.mapView.setRegion(region, animated: true)
            
            self.tracksUserCourse = true
            
            self.rawLocation = location
            self.GetAppleRouteFirst(from: self.initialCoordinate, to: self.waypoints[stepCounter])
            self.updateCourseTracking(location: self.rawLocation!, animated: true)
        }
        
        self.rawLocation = location
        guard self.tracksUserCourse else { return }
        self.userLocationForCourseTracking = location
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "locationDidChange"), object: self, userInfo: ["location": location])
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        
            print("Location heading was changed")
            print(newHeading.trueHeading)
            print(newHeading.headingAccuracy)
            print(newHeading.magneticHeading)
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        self.activeRoute = true
        if region is CLCircularRegion {
            
            if region.identifier == "didstart" {
                self.locationManager.stopMonitoring(for: region)
                self.GetttingPolylineAndSetGeofencing()
                return
            }
            
            self.currentStepDistance = 0
            let geofencingNumber = Int(region.identifier)
            if (geofencingNumber! + 1) == self.steps.count {
                
                self.currentStep = self.steps[(geofencingNumber!)]
                let initialMessage = "\(self.steps[(geofencingNumber!)].instructions)"
                self.instructionLabel.text = initialMessage                
                self.stepDistanceLabel.text = "0.0 m"
                let speechUtterance = AVSpeechUtterance(string: initialMessage)
                self.speechSynthesizer.speak(speechUtterance)
                
                let region = MKCoordinateRegion(center: (self.rawLocation?.coordinate)!, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
                self.mapView.setRegion(region, animated: true)
                
                self.updateCourseTracking(location: location, animated: true)
                if self.stepCounter < self.waypoints.count {
                    self.tracksUserCourse = false
                    self.GetAppleRoute(coordinate: self.waypoints[self.stepCounter])
                }else {
                    self.tracksUserCourse = false
                    let alert = UIAlertController(title: "Report Traffic", message: "You have just arrived at point B successfully.", preferredStyle: UIAlertControllerStyle.alert)
                    
                    let arrived = UIAlertAction(title: "OK", style: .default) { (alert) in
                        
                        let  vc =  self.navigationController?.viewControllers.filter({$0 is EmployeeHomeViewController}).first
                        self.navigationController?.popToViewController(vc!, animated: true)
                    }
                    
                    alert.addAction(arrived)
                    self.present(alert, animated: true, completion: nil)
                }
            }else {
                self.currentStep = self.steps[(geofencingNumber!)]
                let initialMessage = "\(self.steps[(geofencingNumber!)].instructions)"
                self.instructionLabel.text = initialMessage
                self.stepDistance = self.steps[(geofencingNumber! + 1)].distance
                self.stepDistanceLabel.text = "\(self.stepDistance) m"
                let speechUtterance = AVSpeechUtterance(string: initialMessage)
                self.speechSynthesizer.speak(speechUtterance)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {        
        print("Region just exited")
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Monitoring is started for region with identifier: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error.localizedDescription)")
    }
}

extension NavigationMapViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        print("Gesture started")
        return true
    }
    
}

extension TimeInterval {
    private var milliseconds: Int {
        return Int((truncatingRemainder(dividingBy: 1)) * 1000)
    }
    
    private var seconds: Int {
        return Int(self) % 60
    }
    
    private var minutes: Int {
        return (Int(self) / 60 ) % 60
    }
    
    private var hours: Int {
        return Int(self) / 3600
    }
    
    var stringTime: String {
        return "\(minutes)min"
//        if hours != 0 {
//            return "\(hours)h \(minutes)m \(seconds)s"
//        } else if minutes != 0 {
//            return "\(minutes)m \(seconds)s"
//        } else if milliseconds != 0 {
//            return "\(seconds)s \(milliseconds)ms"
//        } else {
//            return "\(seconds)s"
//        }
    }
}

//MARK: extension UIColor(hexcolor)
extension UIColor {
    
    // Convert UIColor from Hex to RGB
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex: Int) {
        self.init(red: (netHex >> 16) & 0xff, green: (netHex >> 8) & 0xff, blue: netHex & 0xff)
    }
}
