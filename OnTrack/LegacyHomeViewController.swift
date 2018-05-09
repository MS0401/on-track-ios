//
//  HomeViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/30/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import SwiftyJSON
import RealmSwift
import Pulsator
//import DXCustomCallout_ObjC

class HomeViewController: UIViewController, SettingsViewDelegate {
    
    internal var tbHeight: Int = 0
    internal var count: Int = 0

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var legendView: UIView!
    
    var realm = try! Realm()
    var drivers = [RealmDriver]()
    var zones = [Zone]()
    var lat = Float()
    var long = Float()
    var timer: Timer?
    var batteryLevel: Float?
    
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        st.items = ["SMS Dispatch", "Emergency", "Cancel"]
        st.imageNames = ["comments", "red_info", "blue_close"]
        return st
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsTraffic = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        legendView.layer.cornerRadius = 10
        legendView.clipsToBounds = true
        
        loadRoute()
    
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(loadRoute), userInfo: nil, repeats: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }
    
    @objc func loadRoute() {
        APIManager.shared.getRouteInfo(routeId: (currentUser?.route?.id)!) { (drivers, zones) in
            self.drivers.removeAll()
            self.zones.removeAll()
            
            for driver in drivers {
                if driver.role != "driver" {
                    self.drivers.append(driver)
                }
            }

            self.zones = zones
            
            DispatchQueue.main.async {
                self.addPins()
            }
        }
    }
    
    @IBAction func handleSettings(_ sender: Any) {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
        }
    }
    
    func hideSettingsView(status: Bool) {
        if status == true {
            settingsView.removeFromSuperview()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "driverAnnotationSegue" {
            let dvc = segue.destination as! DriverDetailViewController
        }
    }
}

extension HomeViewController: MKMapViewDelegate {
    
    func addPins() {
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
        
        for pin in zones {
            let pinCoord = CLLocationCoordinate2DMake(CLLocationDegrees(pin.latitude), CLLocationDegrees(pin.longitude))
            let dropPin = MKPointAnnotation()
            
            dropPin.coordinate = pinCoord
            dropPin.title = pin.name
            dropPin.subtitle = pin.point
            mapView.addAnnotation(dropPin)
            mapView.fitAllAnnotations()
        }
        
        for driver in drivers {
            
            let pinCoord = CLLocationCoordinate2DMake(CLLocationDegrees((driver.lastLocation?.latitude)!), CLLocationDegrees((driver.lastLocation?.longitude)!))
            let dropPin = MKPointAnnotation()
            
            dropPin.coordinate = pinCoord
            dropPin.title = "\(driver.name)"
            dropPin.subtitle = "staff"
        }
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
            
            //TODO: Refactor
            if let t = annotation.subtitle! {
                switch t {
                case "drop":
                    annotationView.image = UIImage(named: "green_placemark")
                case "load":
                    annotationView.image = UIImage(named: "blue_placemark")
                case "yard":
                    annotationView.image = UIImage(named: "yellow_placemark")
                case "break":
                    annotationView.image = UIImage(named: "red_placemark")
                case "mechanical":
                    annotationView.image = UIImage(named: "white_placemark")
                case "":
                    annotationView.image = UIImage(named: "green_dot")
                    //annotationView.centerOffset = CGPoint(x: 0, y: annotationView.frame.size.height / 2)
                    annotationView.canShowCallout = true
                    annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                case "driver":
                    annotationView.image = UIImage(named: "green_dot")
                    annotationView.centerOffset = CGPoint(x: 0, y: annotationView.frame.size.height / 2)
                    /*
                    let pulsator = Pulsator()
                    pulsator.numPulse = 1
                    pulsator.radius = 40
                    pulsator.animationDuration = 3
                    pulsator.backgroundColor = UIColor(colorLiteralRed: 44/255, green: 219/255, blue: 102/255, alpha: 1.0).cgColor
                    annotationView.layer.insertSublayer(pulsator, below: annotationView.layer)
                    //annotationView.layer.addSublayer(pulsator)
                    pulsator.pulseInterval = 1
                    pulsator.position = CGPoint(x: 7, y: 7)
                    pulsator.start()
                    */
                    annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                default:
                    annotationView.image = UIImage(named: "blue_dot")
                    annotationView.canShowCallout = true
                    annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                    /*
                    let pulsator = Pulsator()
                    pulsator.numPulse = 1
                    pulsator.radius = 40
                    pulsator.animationDuration = 3
                    pulsator.backgroundColor = UIColor(colorLiteralRed: 76/255, green: 160/255, blue: 255/255, alpha: 1.0).cgColor
                    annotationView.layer.insertSublayer(pulsator, below: annotationView.layer)
                    //annotationView.layer.addSublayer(pulsator)
                    pulsator.pulseInterval = 1
                    pulsator.position = CGPoint(x: 7, y: 7)
                    pulsator.start()
                    */
                    //annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                }
            }
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

    }
    
    func addHalo() {
        let pulsator = Pulsator()
        pulsator.numPulse = 1
        pulsator.radius = 40
        pulsator.animationDuration = 3
        pulsator.backgroundColor = UIColor(red: 0, green: 0.455, blue: 0.756, alpha: 1).cgColor
        view.layer.addSublayer(pulsator)
        pulsator.pulseInterval = 1
        pulsator.start()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.strokeColor = .red
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {

    }
    
    func didSelectRow(indexPath: Int) {
        
    }
}
