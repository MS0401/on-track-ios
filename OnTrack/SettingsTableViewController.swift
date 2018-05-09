//
//  SettingsTableViewController.swift
//  
//
//  Created by Peter Hitchcock on 4/18/17.
//
//

import UIKit
import RealmSwift
import CoreLocation

class SettingsTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    let realm = try! Realm()
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            
            locationManager.stopMonitoringVisits()
            locationManager.stopUpdatingLocation()
            stopUpdatingLocation = true
            
            if currentUser?.role == "driver" {
                NotificationCenter.default.post(name: driverTimer, object: nil)
            } else {
                NotificationCenter.default.post(name: staffTimer, object: nil)
            }
            
            try! self.realm.write() {
                self.realm.deleteAll()
            }
            
            dismiss(animated: true, completion: nil)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "AlternateNavVC") as! UINavigationController
            UIApplication.shared.keyWindow?.rootViewController = controller
        }
    }
}
