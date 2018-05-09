//
//  PMDashboardViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import ActionCableClient
import Alamofire
import SwiftyJSON
import RealmSwift
import CoreLocation

class PMDashboardViewController: UIViewController {
    
    var client = ActionCableClient(url: URL(string: "wss://ontrackinventory.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "StatsChannel"
    let realm = try! Realm()
    var locationManager = CLLocationManager()
    var lat = Float()
    var long = Float()
    var timer: Timer?
    var batteryLevel: Float?
    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user = self.realm.objects(User.self).first
        
        title = "Dashboard"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        timer = Timer.scheduledTimer(timeInterval: 600, target: self, selector: #selector(postTimer), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(timerInvalidate), name: staffTimer, object: nil)
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = abs(UIDevice.current.batteryLevel)
        
        //RealmManager.shared.realmLocationUser(currentUser: user, latitude: 34.042248, longitude: -118.262580, batteryLevel: 1.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //getUsers()
        //getInventoryStats()
        /*
        self.client.willConnect = {
            print("Will Connect")
        }
        
        self.client.onConnected = {
            print("Connected to \(self.client.url)")
        }
        
        self.client.onDisconnected = {(error: ConnectionError?) in
            print("Disconected with error: \(error)")
        }
        
        self.client.willReconnect = {
            print("Reconnecting to \(self.client.url)")
            return true
        }

        self.channel = client.create(PMDashboardViewController.ChannelIdentifier)
        
        self.channel?.onSubscribed = {
            print("Subscribed to \(PMDashboardViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            print(data)
            
        }
        
        self.client.connect()
        */
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        RealmManager.shared.realmLocationUser(currentUser: user, latitude: lat, longitude: long, batteryLevel: batteryLevel!)
        print(user.lastLocation)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        /*
        client.disconnect()
         */
    }
    
    @objc func timerInvalidate() {
        timer?.invalidate()
    }
    
    @objc func postTimer() {
        let user = self.realm.objects(User.self).first
        //print("user id \(user!.id)")
        postLocation(id: user!.id)
        //APIManager.shared.postLocation(eventId: (currentUser?.event_id)!, driverId: currentUser!.id, lat: lat, long: long, course: nil,
                                       //speed: nil, load_arrival: nil, drop_arrival: nil, battery_level: batteryLevel!)
        
        //RealmManager.shared.realmLocationUser(currentUser: user, latitude: lat, longitude: long, batteryLevel: batteryLevel!)
        //print(user.lastLocation)
    }
    
    func postLocation(id: Int) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/users/\(id)/location"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let params = [
            "event_id": 1,
            "location": ["latitude": "\(lat)", "longitude": "\(long)"]
            ] as [String : Any]
        
        Alamofire.request(path, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            //print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                //print(json)
                
            case .failure:
                break
            }
        }
    }
    
    func getInventoryStats() {
        print("get inventory")
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/stats"
        print(path)
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        print(headers)
        
        let parameters = [
            "event_id": 1,
            "inventory_type_id": 1
        ]
        print(parameters)
        
        Alamofire.request(path, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print("here")
            print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(json)
                
            case .failure:
                break
            }
        }
    }
    
    func getInventoryTypes() {
            let user = self.realm.objects(User.self).first
            let path = "\(BASE_URL_INVENTORY)/api/inventory_types"
    
            let headers = [
                "Content-Type": "application/json",
                "Authorization": "\(user!.token)"
            ]
            
            Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                switch response.result {
                case .success(let jsonObject):
                    let json = JSON(jsonObject)
                    print(json)
                    
                case .failure:
                    break
                }
            }
    }
    
    func getUsers() {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/users"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(json)
                
            case .failure:
                break
            }
        }
    }
}

extension PMDashboardViewController: CLLocationManagerDelegate {
    
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
            RealmManager.shared.realmLocationUser(currentUser: user, latitude: lat, longitude: long, batteryLevel: batteryLevel!)
            //print(user.lastLocation)
        }
    }
}
