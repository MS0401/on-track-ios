//
//  MainMenuViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/17/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MessageUI
import RealmSwift
import CoreLocation
import Alamofire
import ACProgressHUD_Swift

class DriverMenuViewController: UIViewController, CLLocationManagerDelegate, SettingsViewDelegate {
    
    let realm = try! Realm()
    var locationManager = CLLocationManager()
    var lat = Float()
    var long = Float()
    var course = Float()
    var speed = Float()
    var timer: Timer?
    var batteryLevel: Float?
    var arrived = false
    var zones = [Zone]()
    internal var count: Int = 0
    internal var tbHeight: Int = 0
    var viewItems = [String]()
    var imageName = [String]()
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        return st
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        //34.063515, -117.278518
        RealmManager.shared.realmLocation(currentUser: currentUser!, latitude: 34.063515, longitude: -117.278518, batteryLevel: 100.0)
        
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(postTimer), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(timerInvalidate), name: driverTimer, object: nil)
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = abs(UIDevice.current.batteryLevel)
        
        APIManager.shared.getZones((currentUser?.event_id)!) { (zones) in
            self.zones.removeAll()
            self.zones = zones
        }
        
        setupSettingsView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGeofence()
    }
    
    @objc func timerInvalidate() {
        timer?.invalidate()
    }
    
    func setupSettingsView() {
        count = 4
        tbHeight = 48 * count
        
        let originalFrame = settingsView.tableView.frame
        let newHeight = count * tbHeight
        settingsView.tableView.frame = CGRect(x: originalFrame.origin.x, y: originalFrame.origin.y, width: originalFrame.size.width, height:CGFloat(Int(newHeight)))
        
        viewItems.append("Text Dispatch")
        imageName.append("comments")
        viewItems.append("Call Dispatch")
        imageName.append("phone")
        viewItems.append("Emergency")
        imageName.append("red_info")
        viewItems.append("Cancel")
        imageName.append("blue_close")
        settingsView.items = viewItems
        settingsView.imageNames = imageName
    }
    
    func didSelectRow(indexPath: Int) {
        if indexPath == 0 {
            openSMS()
        } else if indexPath == 1 {
            UIApplication.shared.open(URL(string: "telprompt://14152002585")!, options: [:], completionHandler: nil)
        } else if indexPath == 2 {
            self.emergency()
        }
    }
    
    func hideSettingsView(status: Bool) {
        if status == true {
            settingsView.removeFromSuperview()
        }
    }
    
    func emergency() {
        let progressView = ACProgressHUD.shared
        progressView.progressText = "Sending Emergency..."
        
        let alert = UIAlertController(title: "Emergency Type", message: "What kind of emergency", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Medical", style: .default, handler: { (action) in
            self.postScan(progressView: progressView, reason: 16, comment: "comment", driverId: (currentUser?.id)!, lat: self.lat, long: self.long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, scannerId: (currentUser?.id)!, scanType: "staff")
        })
        let alertActionTwo = UIAlertAction(title: "Fire", style: .default, handler: { (action) in
            self.postScan(progressView: progressView, reason: 16, comment: "comment", driverId: (currentUser?.id)!, lat: self.lat, long: self.long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, scannerId: (currentUser?.id)!, scanType: "staff")
        })
        let alertActionThree = UIAlertAction(title: "Police", style: .default, handler: { (action) in
            self.postScan(progressView: progressView, reason: 16, comment: "comment", driverId: (currentUser?.id)!, lat: self.lat, long: self.long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, scannerId: (currentUser?.id)!, scanType: "staff")
        })
        let alertActionFour = UIAlertAction(title: "Bus Accident", style: .default, handler: { (action) in
            self.postScan(progressView: progressView, reason: 16, comment: "comment", driverId: (currentUser?.id)!, lat: self.lat, long: self.long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, scannerId: (currentUser?.id)!, scanType: "staff")
        })
        
        let alertActionSix = UIAlertAction(title: "Broken Down", style: .default, handler: { (action) in
            self.postScan(progressView: progressView, reason: 16, comment: "comment", driverId: (currentUser?.id)!, lat: self.lat, long: self.long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, scannerId: (currentUser?.id)!, scanType: "staff")
        })
        
        let alertActionFive = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            
        })
        
        alert.addAction(alertAction)
        alert.addAction(alertActionTwo)
        alert.addAction(alertActionThree)
        alert.addAction(alertActionFour)
        alert.addAction(alertActionSix)
        alert.addAction(alertActionFive)
        present(alert, animated: true, completion: nil)
    }
    
    func postScan(progressView: ACProgressHUD, reason: Int, comment: String, driverId: Int,
                  lat: Float, long: Float, eventId: Int, routeId: Int, scannerId: Int, scanType: String) {
        
        progressView.showHUD()

        APIManager.shared.postDriverScan(driverId, comment: comment, reason: reason, lat: lat, long: long, eventId: eventId, routeId: routeId, passengerCount: nil, scannerId: scannerId, scanType: scanType, ingress: nil, shiftId: nil) { (error) in
            
            if error != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                    progressView.hideHUD()
                    self.errorAlert()
                })
                
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                    progressView.hideHUD()
                    self.completionAlert()
                })
            }
        }
    }
    
    func completionAlert() {
        _ = SweetAlert().showAlert("Emergency Notification", subTitle: "Emergency Notification Received", style: AlertStyle.success, buttonTitle:  "OK", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
        }
    }
    
    func errorAlert() {
        _ = SweetAlert().showAlert("Emergency Notification", subTitle: "Emergency Notification not Received", style: AlertStyle.error, buttonTitle:  "Try Again", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
        }
    }

    @objc func postTimer() {
        APIManager.shared.postLocation(eventId: (currentUser?.event_id)!, driverId: (currentUser?.id)!, lat: lat, long: long,
                                       course: course, speed: speed, load_arrival: nil,
                                       drop_arrival: nil, battery_level: batteryLevel!)
        
        RealmManager.shared.realmLocation(currentUser: currentUser!, latitude: lat, longitude: long, batteryLevel: batteryLevel!)
    }
    
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

    @IBAction func emergencyButton(_ sender: Any) {
        emergency()
    }
    
    @IBAction func callDispatch(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "telprompt://14152002585")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func smsDispatch(_ sender: UIButton) {
        openSMS()
    }
    
    @IBAction func emergency(_ sender: Any) {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
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
        course = Float(locationManager.location!.course)
        speed = (Float(locationManager.location!.speed) * 2.236936284)
        //let dist = locationManager.location?.distance(from: CLLocation(latitude: 37.7749, longitude: -122.4194))
        //print(dist! * 0.000621371192) //distance to next stop
        //let location = locations.last! as CLLocation
        //let source = Location(driver_id: (driver?.id)!, latitude: Float(coord.latitude), longitude: Float(coord.longitude))
        //sourceLocation = source
        //outputLabel.text = "\(location)"
        
        /*
        if currentUser?.lastLocation == nil {
            var lastLocation = RealmLocation()
            lastLocation.driver_id = (currentUser?.id)!
            lastLocation.latitude = lat
            lastLocation.longitude = long
            lastLocation.battery_level.value = batteryLevel
            
            try? realm.write {
                currentUser?.lastLocation = lastLocation
            }
        } else {
            try? realm.write {
                currentUser?.lastLocation?.driver_id = (currentUser?.id)!
                currentUser?.lastLocation?.latitude = lat
                currentUser?.lastLocation?.longitude = long
                currentUser?.lastLocation?.battery_level.value = batteryLevel
            }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "driverStatSegue" {
            let dvc = segue.destination as! DriverDetailViewController
            dvc.driver = currentUser
        } else if segue.identifier == "driverCardSegue" {
            let dvc = segue.destination as! DriverDetailViewController
            dvc.driver = currentUser
            dvc.shift = currentUser?.shifts.first
            dvc.driverId = currentUser?.id
        }
    }
}

extension DriverMenuViewController: MFMessageComposeViewControllerDelegate {
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
