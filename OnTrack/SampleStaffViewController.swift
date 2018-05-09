//
//  SampleStaffViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/28/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit

class SampleStaffViewController: UIViewController, SettingsViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityLabel: UILabel!
    
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        return st
    }()
    internal var count: Int = 0
    internal var tbHeight: Int = 0
    var viewItems = [String]()
    var imageName = [String]()
    var regionRadius: CLLocationDistance = 500
    var incident = MKPointAnnotation()
    var responses = [["title": "Vehicle Scan" , "type": "Type: Passenger Unload"],["title": "Incident Reported by: Peter Hitchcock", "type": "Emergency"], ["title": "Peter Hitchcock" , "type": "Responding to Incident"], ["title": "Incident Closed by: Peter Hitchcock", "type": "Emergency"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        mapView.showsTraffic = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        title = "Peter Hitchcock"
        tableView.tableFooterView = UIView()
        setupSettingsView()
        
        //centerMapOnLocation()
        
        activityLabel.text = "4"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        centerMapOnLocation()
    }
    
    func centerMapOnLocation() {
        let coord = CLLocationCoordinate2DMake(37.402492, -121.971383)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coord, regionRadius, regionRadius)
        //incident = MKPointAnnotation()
        incident.coordinate = coord
        incident.title = "Peter Hitchcock"
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.addAnnotation(incident)
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

            let number = "sms:+19168470003"
            UIApplication.shared.openURL(NSURL(string: number)! as URL)
            
        } else if indexPath == 1 {

            
        } else if indexPath == 2 {
            callDriver()
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
        UIApplication.shared.open(URL(string: "telprompt://19168470003")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func moreAction(_ sender: Any) {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
        }
    }
}

extension SampleStaffViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return responses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "aCell", for: indexPath) as! ItemTableViewCell
        cell.checkOutLabel.text = responses[indexPath.row]["title"]
        cell.timeLabel.text = responses[indexPath.row]["type"]
        switch indexPath.row {
        case 0:
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
        case 1:
            cell.reasonView.backgroundColor = UIColor.flatRed
        case 3:
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
        default:
            cell.reasonView.backgroundColor = UIColor.flatGreen
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SampleStaffViewController: MKMapViewDelegate {
    
    
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

