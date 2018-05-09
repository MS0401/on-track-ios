//
//  MKNavigationMapView.swift
//  OnTrack
//
//  Created by Andrei Opanasenko on 1/16/18.
//  Copyright © 2018 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit
import Turf
import Foundation

open class MKNavigationMapView: MKMapView, UIGestureRecognizerDelegate {

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
    var animatesUserLocation: Bool = false
    var isPluggedIn: Bool = false
    var batteryStateObservation: NSKeyValueObservation?
    var altitude: CLLocationDistance = defaultAltitude
    var mapManager = MapManager()
    var currentRoute: MKRoute!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        makeGestureRecognizersRespectCourseTracking()
        makeGestureRecognizersUpdateCourseView()
        
        batteryStateObservation = UIDevice.current.observe(\.batteryState) { [weak self] (device, changed) in
            self?.isPluggedIn = device.batteryState == .charging || device.batteryState == .full
        }
        
        resumeNotifications()
        resumeGetRouteNotifications()
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: NSNotification.Name(rawValue: "locationDidChange"), object: nil)
        
        let gestures = gestureRecognizers ?? []
        let mapTapGesture = self.mapTapGesture
        mapTapGesture.requireFailure(of: gestures)
        addGestureRecognizer(mapTapGesture)
    }
    
    private lazy var mapTapGesture = UITapGestureRecognizer(target: self, action: #selector(didRecieveTap(sender:)))
    
    @objc func didRecieveTap(sender: UITapGestureRecognizer) {
        print("DidTap MKMapView")
    }
    
    func resumeGetRouteNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(GetRoute(notification:)), name: NSNotification.Name(rawValue: "getRoute"), object: nil)
    }
    
    @objc func progressDidChange(_ notification: Notification) {
        guard tracksUserCourse else { return }
        
        self.userLocationForCourseTracking = notification.userInfo!["location"] as? CLLocation
        
        self.updateCourseTracking(location: self.userLocationForCourseTracking, animated: false)
        
    }
    
    /** Modifies the gesture recognizers to also disable course tracking. */
    func makeGestureRecognizersRespectCourseTracking() {
        for gestureRecognizer in gestureRecognizers ?? []
            where gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UIRotationGestureRecognizer {
                gestureRecognizer.addTarget(self, action: #selector(disableUserCourseTracking))
        }
    }
    
    func makeGestureRecognizersUpdateCourseView() {
        for gestureRecognizer in gestureRecognizers ?? [] {
            gestureRecognizer.addTarget(self, action: #selector(updateCourseView(_:)))
        }
    }
    
    deinit {
        suspendNotifications()
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "locationDidChange"), object: nil)
    }
    
    @objc func updateCourseView(_ sender: UIGestureRecognizer) {
        
        if sender.state == .ended {
            altitude = self.camera.altitude
        }
        
        // Capture altitude for double tap and two finger tap after animation finishes
        if sender is UITapGestureRecognizer, sender.state == .ended {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                self.altitude = self.camera.altitude
            })
        }
        
        if let pan = sender as? UIPanGestureRecognizer {
            if sender.state == .ended || sender.state == .cancelled {
                let velocity = pan.velocity(in: self)
                let didFling = sqrt(velocity.x * velocity.x + velocity.y * velocity.y) > 100
                if didFling {
                }
            }
        }
        
        if sender.state == .changed {
            guard let location = userLocationForCourseTracking else { return }
            userCourseView?.layer.removeAllAnimations()
            userCourseView?.center = convert(location.coordinate, toPointTo: self)
        }
    }
    
    weak var courseTrackingDelegate: MKNavigationMapViewCourseTrackingDelegate!
    
    open override var showsUserLocation: Bool {
        get {
            if tracksUserCourse || userLocationForCourseTracking != nil {
                return !(userCourseView?.isHidden ?? true)
            }
            return super.showsUserLocation
        }
        set {
            if tracksUserCourse || userLocationForCourseTracking != nil {
                super.showsUserLocation = false
                
                if userCourseView == nil {
                    userCourseView = UserPuckCourseView1(frame: CGRect(origin: .zero, size: CGSize(width: 75, height: 75)))
                }
                userCourseView?.isHidden = !newValue
            } else {
                userCourseView?.isHidden = true
                super.showsUserLocation = newValue
            }
        }
    }
    
    @objc func disableUserCourseTracking() {
        tracksUserCourse = false
    }
    
    @objc public func updateCourseTracking(location: CLLocation?, animated: Bool) {
        animatesUserLocation = animated
        guard let location = location, CLLocationCoordinate2DIsValid(location.coordinate) else {
            return
        }
        
        if tracksUserCourse {
            
            UIView.animate(withDuration: 1.0, delay: 0, options: [.curveLinear, .beginFromCurrentState], animations: {
                
                let camera = MKMapCamera()
                camera.centerCoordinate = location.coordinate
                camera.altitude = 300.0
                camera.pitch = 45
                
                if self.activeRoute {
                    let direction = location.coordinate.direction(to: self.currentStep.polyline.coordinate)
                    camera.heading = direction
                }else {
                    camera.heading = 90
                }                
                
                print(location.course)                
                self.camera = camera
                
            }, completion: nil)
            
        }
        
        let duration: TimeInterval = animated ? 1 : 0
        UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear, .beginFromCurrentState], animations: {
            
            self.userCourseView?.center = self.convert(location.coordinate, toPointTo: self)
            
            
        }, completion: nil)
        
        if let userCourseView = userCourseView as? UserCourseView1 {
            userCourseView.update(location: location, pitch: camera.pitch, direction: camera.heading, animated: animated, tracksUserCourse: tracksUserCourse)
        }
    }
   
    
    var tracksUserCourse: Bool = false {
        didSet {
            if tracksUserCourse {
                
                altitude = MKNavigationMapView.defaultAltitude
                showsUserLocation = true
                courseTrackingDelegate?.MKNavigationMapViewDidStartTrackingCourse(self)
            } else {
                courseTrackingDelegate?.MKNavigationMapViewDidStopTrackingCourse(self)
            }
            
            if let location = userLocationForCourseTracking {
                updateCourseTracking(location: location, animated: true)
            }
        }
    }
    
    var activeRoute: Bool = false
    var currentStep: MKRouteStep!
    
    //MARK: Get Route and draw polyline
    @objc func GetRoute(notification: NSNotification) {
        
        let currentCoordinate = notification.userInfo!["currentCoordinate"] as? CLLocationCoordinate2D
        let destinationCooridnate = notification.userInfo!["destinationCoordinate"] as? CLLocationCoordinate2D
        
        mapManager.directionsFromCurrentLocation(to: destinationCooridnate!, directionCompletionHandler: { (route, polyline, directionInformation, boudingRegion, error) -> Void in
            
            if (error != nil) {
                print(error!)
            }
            else {
                
//                self.currentRoute = route!
                self.activeRoute = true
//                self.currentStep = self.currentRoute.steps[0]
                
                //MARK: Setting geofencing to current route steps.
//                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setGeofencing"), object: self, userInfo: ["currentRoute": self.currentRoute])
                
                self.removeAllPlacemarkFromMap(shouldRemoveUserLocation: true)
                self.add(polyline!, level: MKOverlayLevel.aboveRoads)
                
                //MARK: Start annontation
                let start = MKPointAnnotation()
                start.coordinate = currentCoordinate!
                start.title = "Start"
                self.addAnnotation(start)
                
//                //MARK: Destination annontation
//                let destination = MKPointAnnotation()
//                let point = route?.polyline.coordinate
//                destination.coordinate = point!
//                destination.title = "Destination"
//                self.addAnnotation(destination)
                
            }
        })
    }
    
    func removeAllPlacemarkFromMap(shouldRemoveUserLocation:Bool){
        for annotation in self.annotations{
            if shouldRemoveUserLocation {
                if annotation as? MKUserLocation !=  self.userLocation {
                    self.removeAnnotation(annotation as MKAnnotation)
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
                addSubview(userCourseView)
            }
        }
    }
    
    var routes: [MKRoute]?
    
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

//MARK: NavigationMapViewCourseTrackingDelegate

protocol MKNavigationMapViewCourseTrackingDelegate: class {
    func MKNavigationMapViewDidStartTrackingCourse(_ mapView: MKNavigationMapView)
    func MKNavigationMapViewDidStopTrackingCourse(_ mapView: MKNavigationMapView)
}

