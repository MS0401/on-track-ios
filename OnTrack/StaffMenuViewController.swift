//
//  StaffMenuViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/18/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MessageUI
import RealmSwift
import CoreLocation

class StaffMenuViewController: UIViewController {
    
    let realm = try! Realm()
    var locationManager = CLLocationManager()
    var lat = Float()
    var long = Float()
    var timer: Timer?
    var batteryLevel: Float?
    var arrived = false
    var zones = [Zone]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let logo = UIImage(named: "logo.png")
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        imageView.contentMode = .scaleAspectFit
        imageView.image = logo
        navigationItem.titleView = imageView
        
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        RealmManager.shared.realmLocation(currentUser: currentUser!, latitude: 37.7749, longitude: -122.4194, batteryLevel: 100.0)
        
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(postTimer), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(timerInvalidate), name: staffTimer, object: nil)
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = abs(UIDevice.current.batteryLevel)
        
        APIManager.shared.getZones((currentUser?.event_id)!) { (zones) in
            self.zones.removeAll()
            self.zones = zones
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGeofence()
    }
    
    @objc func timerInvalidate() {
        timer?.invalidate()
    }
    
    @objc func postTimer() {
        APIManager.shared.postLocation(eventId: (currentUser?.event?.eventId)!, driverId: currentUser!.id, lat: lat, long: long, course: nil,
                                       speed: nil, load_arrival: nil, drop_arrival: nil, battery_level: batteryLevel!)
        
        RealmManager.shared.realmLocation(currentUser: currentUser!, latitude: lat, longitude: long, batteryLevel: batteryLevel!)
    }
    
    @IBAction func waves(_ sender: UIButton) {
        performSegue(withIdentifier: "wave", sender: self)
    }
    
    @IBAction func callDispatch(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "telprompt://14152002585")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func smsDispatch(_ sender: UIButton) {
        openSMS()
    }
}

extension StaffMenuViewController: CLLocationManagerDelegate {
    
    func setupGeofence() {
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {

            for zone in zones {
                let title = zone.name
                var coord: CLLocationCoordinate2D!
                coord = CLLocationCoordinate2DMake(CLLocationDegrees(zone.latitude), CLLocationDegrees(zone.longitude))
                let regionRadius = 250.0
                let region = CLCircularRegion(center: coord, radius: regionRadius, identifier: title)
                region.notifyOnEntry = true
                region.notifyOnExit = true
                locationManager.startMonitoring(for: region)
            }
           
        } else {
            print("cant track regions")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationArray = locations as NSArray
        let locationObj = locationArray.lastObject as! CLLocation
        let coord = locationObj.coordinate
        lat = Float(coord.latitude)
        long = Float(coord.longitude)
        /*
        let m = manager.monitoredRegions
        for n in m {
            print(n.identifier)
        }
        */
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("error ----------------------------------> \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if arrived == false {
            APIManager.shared.postDriverScan((currentUser?.id)!, comment: region.identifier, reason: 20, lat: lat, long: long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, passengerCount: nil, scannerId: (currentUser?.id)!, scanType: "geo", ingress: nil, shiftId: nil) { (error) in
                self.arrived = true
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if arrived == true {
            APIManager.shared.postDriverScan((currentUser?.id)!, comment: region.identifier, reason: 21, lat: lat, long: long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, passengerCount: nil, scannerId: (currentUser?.id)!, scanType: "geo", ingress: nil, shiftId: nil) { (error) in
                self.arrived = false
            }
        }
    }
}

extension StaffMenuViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
    }
    
    func openSMS() {
        if MFMessageComposeViewController.canSendText() {
            let controller = MFMessageComposeViewController()
            controller.recipients = ["14152002585"]
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
}
