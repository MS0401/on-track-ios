//
//  AdminDashboardViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/28/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift
import CoreLocation
import BTNavigationDropdownMenu

class AdminDashboardViewController: UIViewController, SettingsViewDelegate {
    
    let realm = try! Realm()
    var locationManager = CLLocationManager()
    var lat = Float()
    var long = Float()
    var timer: Timer?
    var batteryLevel: Float?
    var items = [String]()
    var menuView: BTNavigationDropdownMenu!
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        return st
    }()
    internal var count: Int = 0
    internal var tbHeight: Int = 0
    var viewItems = [String]()
    var imageName = [String]()
    
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
        
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(postTimer), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(timerInvalidate), name: staffTimer, object: nil)
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = abs(UIDevice.current.batteryLevel)
        
        setupNavMenu()
        setupSettingsView()
        
        RealmManager.shared.realmLocation(currentUser: currentUser!, latitude: 34.042248, longitude: -118.262580, batteryLevel: 1.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        menuItems()
        menuView.updateItems(items as [AnyObject])
        menuView.shouldChangeTitleText = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuView.hide()
    }
    
    @objc func timerInvalidate() {
        timer?.invalidate()
    }
    
    @objc func postTimer() {
        APIManager.shared.postLocation(eventId: (currentUser?.event_id)!, driverId: currentUser!.id, lat: lat, long: long, course: nil,
                                       speed: nil, load_arrival: nil, drop_arrival: nil, battery_level: batteryLevel!)
        
        RealmManager.shared.realmLocation(currentUser: currentUser!, latitude: lat, longitude: long, batteryLevel: batteryLevel!)
    }
    
    func setupNavMenu() {
        menuItems()
        menuView = BTNavigationDropdownMenu(title: items[0], items: items as [AnyObject])
        
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
            try! self.realm.write {
                currentUser?.day = currentUser?.event?.days[indexPath]
            }
        }
        
        navigationItem.titleView = menuView
    }
    
    func menuItems() {
        if let days = currentUser?.event?.days {
            items.removeAll()
            
            for day in days {
                let start = day.calendarDay.startIndex
                let end = day.calendarDay.index(day.calendarDay.startIndex, offsetBy: 5)
                let item = "\(currentUser!.event!.name) \(day.calendarDay.replacingCharacters(in: start..<end, with: ""))"
                items.append(item)
            }
        } else {
            items.removeAll()
            items.append("Day")
        }
    }
    
    func setupSettingsView() {
        count = 1
        tbHeight = 48 * count
        
        let originalFrame = settingsView.tableView.frame
        let newHeight = count * tbHeight
        settingsView.tableView.frame = CGRect(x: originalFrame.origin.x, y: originalFrame.origin.y, width: originalFrame.size.width, height:CGFloat(Int(newHeight)))
        
        viewItems.append("Change Event")
        imageName.append("sync")
        settingsView.items = viewItems
        settingsView.imageNames = imageName
    }
    
    func didSelectRow(indexPath: Int) {
        switch indexPath {
        case 0:
            performSegue(withIdentifier: "changeEventSegue", sender: self)
        default:
            performSegue(withIdentifier: "changeEventSegue", sender: self)
        }
    }
    
    func hideSettingsView(status: Bool) {
        if status == true {
            settingsView.removeFromSuperview()
        }
    }
    
    @IBAction func moreAction(_ sender: Any) {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeEventSegue" {
            let dvc = segue.destination as! SelectEventViewController
            dvc.isFromDashboard = true
        }
    }
}

extension AdminDashboardViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationArray = locations as NSArray
        let locationObj = locationArray.lastObject as! CLLocation
        let coord = locationObj.coordinate
        lat = Float(coord.latitude)
        long = Float(coord.longitude)
        
        if stopUpdatingLocation == false {
            RealmManager.shared.realmLocation(currentUser: currentUser!, latitude: lat, longitude: long, batteryLevel: batteryLevel!)
        }
    }
}

