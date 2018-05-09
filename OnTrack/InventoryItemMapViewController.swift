//
//  InventoryItemMapViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/5/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import Alamofire
import SwiftyJSON

class InventoryItemMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let realm = try! Realm()
    var inventoryItem: Inventory!
    var center: CLLocationCoordinate2D!
    var regionRadius: CLLocationDistance = 100
    var i: MKPointAnnotation!
    var cad = Cad()
    var mapChanged = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.showsTraffic = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        mapView.layer.cornerRadius = 5
        mapView.layer.borderWidth = 2
        mapView.layer.borderColor = UIColor.flatSkyBlue.cgColor
        
        setupMap()
        addOverlay()
        
        print(inventoryItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(InventoryItemMapViewController.updateMap), name: NSNotification.Name(rawValue: "inventory"), object: nil)
    }
    
    @objc func updateMap() {
        mapView.removeAnnotation(i)
        setupMap()
    }
    
    @IBAction func toggleMap(_ sender: Any) {
        if mapChanged == false {
            mapChanged = true
            mapView.mapType = .hybrid
        } else {
            mapChanged = false
            mapView.mapType = .standard
        }
    }
    
    func setupMap() {
        let coord = CLLocationCoordinate2DMake((inventoryItem.lastScan?.latitude)!, (inventoryItem.lastScan?.longitude)!)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coord, regionRadius, regionRadius)
        i = MKPointAnnotation()
        i.coordinate = coord
        i.title = "Inventory: \(inventoryItem.id)"
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.addAnnotation(i)
    }
    
    func updateLocation(id: Int, lat: String, long: String) {
        
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/scans/\(id)"
        //print(path)
        let headers = [
            "Content-type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let parameters = [
            "event_id": 1,
            "latitude": lat,
            "longitude": long
            ] as [String: Any]
        
        Alamofire.request(path, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
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
}

extension InventoryItemMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        // Better to make this class property
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            //annotationView.canShowCallout = true
            annotationView.isDraggable = true
            //annotationView.centerOffset = CGPoint(x: 40, y: -25)
            
            print("last scan status from map \((inventoryItem.lastScan?.scanType)!)")
            if inventoryItem.inventoryTypeId == 21 {
                switch (inventoryItem.lastScan?.scanType)! {
                case "received":
                    annotationView.image = UIImage(named: "blue_square")
                case "assigned":
                    annotationView.image = UIImage(named: "green_square")
                case "out_of_service":
                    annotationView.image = UIImage(named: "red_square")
                default:
                    annotationView.image = UIImage(named: "yellow_placemark")
                }
            } else {
                switch (inventoryItem.lastScan?.scanType)! {
                case "received":
                    annotationView.image = UIImage(named: "blue_marker")
                case "assigned":
                    annotationView.image = UIImage(named: "green_marker")
                case "out_of_service":
                    annotationView.image = UIImage(named: "red_marker")
                default:
                    annotationView.image = UIImage(named: "yellow_placemark")
                }
            }
            
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        //print(view.annotation?.coordinate)
        
        switch newState {
        case .starting:
            view.dragState = .dragging
        case .ending, .canceling:
            view.dragState = .none
            let droppedAt = view.annotation?.coordinate
            
            let ac = UIAlertController(title: "Pin Dropped", message: "pin dropped at: \(droppedAt!)", preferredStyle: .alert)
            let a1 = UIAlertAction(title: "Update Location", style: .default, handler: { (action) in
                self.updateLocation(id: (self.inventoryItem.lastScan?.id)!, lat: "\((view.annotation?.coordinate.latitude)!)", long: "\((view.annotation?.coordinate.longitude)!)")
            })
            let aa = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            ac.addAction(a1)
            ac.addAction(aa)
            self.present(ac, animated: true, completion: nil)
        default: break
        }
    }
    
    func addOverlay() {
        let overlay = CadMapOverlay(cad: cad)
        mapView.add(overlay)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is CadMapOverlay {
            return CadMapOverlayView(overlay: overlay, overlayImage: UIImage(named: "event")!)
        }
        
        return MKOverlayRenderer()
        
    }
    
    
}
