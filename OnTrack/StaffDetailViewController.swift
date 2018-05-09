//
//  StaffDetailViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 5/25/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import SwiftyJSON

class StaffDetailViewController: UIViewController, SettingsViewDelegate {
   
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var numberOfScansLabel: UILabel!
    
    var driver: RealmDriver!
    var scans = [Scan]()
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        return st
    }()
    internal var count: Int = 0
    internal var tbHeight: Int = 0
    var viewItems = [String]()
    var imageName = [String]()
    var lastLocation: RealmLocation!
    var center: CLLocationCoordinate2D!
    var region: MKCoordinateRegion!
    var driverId = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        staffDetail()
        
        mapView.showsTraffic = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        numberOfScansLabel.alpha = 0.0
        numberOfScansLabel.text = ""
        
        title = driver.name
        tableView.tableFooterView = UIView()
        setupSettingsView()
        
        driverId = driver.id
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func staffDetail() {
        APIManager.shared.getStaffDetail(currentUser!.event!.eventId, (driver.shifts.first?.id)!, driver.id) { (driver) in
            self.driver = driver

            for scan in driver.scans {
                self.scans.append(scan)
            }
            
            DispatchQueue.main.async {
                self.lastLocation = driver.lastLocation
                self.tableView.reloadData()
                self.numberOfScansLabel.text = "\(self.scans.count)"
                
                if self.lastLocation.latitude != 0 {
                    self.center = CLLocationCoordinate2D(latitude: Double(self.lastLocation.latitude), longitude: Double(self.lastLocation.longitude))
                    self.region = MKCoordinateRegion(center: self.center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
                    self.mapView.setRegion(self.region, animated: false)
                    self.addPin(location: self.lastLocation)
                    self.mapView.setRegion(self.region, animated: false)
                } else if self.scans.count > 0 {
                    self.center = CLLocationCoordinate2D(latitude: Double((self.scans.last?.latitude)!), longitude: Double((self.scans.last?.latitude)!))
                    self.region = MKCoordinateRegion(center: self.center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
                    self.mapView.setRegion(self.region, animated: false)
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = self.center
                } else {
                    self.center = CLLocationCoordinate2DMake(36.268916, -115.024194)
                    self.region = MKCoordinateRegion(center: self.center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
                    self.mapView.setRegion(self.region, animated: false)
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = self.center
                }
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.numberOfScansLabel.alpha = 1.0
                })
            }
        }
    }

    func setupSettingsView() {
        count = 4
        tbHeight = 48 * count
        
        let originalFrame = settingsView.tableView.frame
        let newHeight = count * tbHeight
        settingsView.tableView.frame = CGRect(x: originalFrame.origin.x, y: originalFrame.origin.y, width: originalFrame.size.width, height:CGFloat(Int(newHeight)))
        
        viewItems.append("Text")
        imageName.append("comments")
        viewItems.append("System SMS")
        imageName.append("comments")
        viewItems.append("Call")
        imageName.append("phone")
        viewItems.append("Cancel")
        imageName.append("blue_close")
        settingsView.items = viewItems
        settingsView.imageNames = imageName
    }
    
    func didSelectRow(indexPath: Int) {
        if indexPath == 0 {
            if driver.cell != "" || driver.cell != nil {
                let number = "sms:+1\(String(describing: driver.cell!))"
                UIApplication.shared.openURL(NSURL(string: number)! as URL)
            } else {
                throwAlert()
            }
            
        } else if indexPath == 1 {
            driver.event = currentUser?.event
            driver.route = currentUser?.route
            driver.id = driverId
            messages(driver: driver)
            
        } else if indexPath == 2 {
            if driver.cell != "" {
                callDriver()
            } else {
                throwAlert()
            }
        }
    }
    
    func throwAlert() {
        let alert = UIAlertController(title: "Driver Cell", message: "Driver Cell was not provided", preferredStyle: UIAlertControllerStyle.alert)
        let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true, completion: nil)
    }
    
    func hideSettingsView(status: Bool) {
        if status == true {
            settingsView.removeFromSuperview()
        }
    }
    
    func messages(driver: RealmDriver) {
        let layout = UICollectionViewFlowLayout()
        let controller = MessageCollectionViewController(collectionViewLayout: layout)
        
        controller.driver = driver
        present(controller, animated: true, completion: nil)
    }
    
    func callDriver() {
        if driver.cell != nil {
            UIApplication.shared.open(URL(string: "telprompt://1\(String(describing: driver.cell!))")!, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func moreAction(_ sender: Any) {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
        }
    }
}

extension StaffDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "staffScanCell", for: indexPath) as! ScanTableViewCell
        let scan = scans[indexPath.row]
        cell.scan = scan
        cell.nameLabel.text = scan.driverName
        cell.setupCell()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension StaffDetailViewController: MKMapViewDelegate {
    
    func addPin(location: RealmLocation) {
        
        let pinCoord = CLLocationCoordinate2DMake(CLLocationDegrees(location.latitude), CLLocationDegrees(location.longitude))
        let dropPin = MKPointAnnotation()
        
        dropPin.coordinate = pinCoord
        mapView.addAnnotation(dropPin)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        }
        
        if let annotationView = annotationView {
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "staff_placemark")
        }
        
        return annotationView
    }
}
