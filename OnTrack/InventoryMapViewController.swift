//
//  InventoryMapViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/28/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit
import BTNavigationDropdownMenu
import Alamofire
import SwiftyJSON
import RealmSwift
import ActionCableClient

class InventoryMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var realm = try! Realm()
    var regionRadius: CLLocationDistance = 500//1500
    var all = [MKPointAnnotation]()
    var received = [MKPointAnnotation]()
    var assigned = [MKPointAnnotation]()
    var outOfService = [MKPointAnnotation]()
    var mapChanged = false
    var menuView: BTNavigationDropdownMenu!
    var items = ["All", "Received", "Assigned", "Out of Service"]
    var inventories = [Inventory]()
    var inventoryTypeId: Int!
    var cad = Cad()
    var client = ActionCableClient(url: URL(string: "wss://ontrackinventory.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "InventoryLastScanChannel"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("InventoryTypeId: \(inventoryTypeId)")
        
        menuView = BTNavigationDropdownMenu(title: items[0], items: items as [AnyObject])
        
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
            switch indexPath {
            case 0:
                self.mapView.removeAnnotations(self.all)
                self.mapView.removeAnnotations(self.received)
                self.mapView.removeAnnotations(self.assigned)
                self.mapView.removeAnnotations(self.outOfService)
                self.mapView.addAnnotations(self.all)
            case 1:
                self.mapView.removeAnnotations(self.all)
                self.mapView.removeAnnotations(self.received)
                self.mapView.removeAnnotations(self.assigned)
                self.mapView.removeAnnotations(self.outOfService)
                self.mapView.addAnnotations(self.received)
            case 2:
                self.mapView.removeAnnotations(self.all)
                self.mapView.removeAnnotations(self.received)
                self.mapView.removeAnnotations(self.assigned)
                self.mapView.removeAnnotations(self.outOfService)
                self.mapView.addAnnotations(self.assigned)
            case 3:
                self.mapView.removeAnnotations(self.all)
                self.mapView.removeAnnotations(self.received)
                self.mapView.removeAnnotations(self.assigned)
                self.mapView.removeAnnotations(self.outOfService)
                self.mapView.addAnnotations(self.outOfService)
            default:
                self.mapView.removeAnnotations(self.all)
                self.mapView.removeAnnotations(self.received)
                self.mapView.removeAnnotations(self.assigned)
                self.mapView.removeAnnotations(self.outOfService)
                self.mapView.addAnnotations(self.all)
            }
        }
        
        navigationItem.titleView = menuView
        
        /*
        //33.685086, -116.241903
        let g1 = CLLocationCoordinate2DMake(37.403723, -121.971826)
        let a1 = MKPointAnnotation()
        a1.coordinate = g1
        a1.title = "Generator"
        generators.append(a1)
        all.append(a1)
        mapView.addAnnotation(a1)
        //33.678729, -116.234458
        let l1 = CLLocationCoordinate2DMake(37.403402, -121.972561)
        let a2 = MKPointAnnotation()
        a2.coordinate = l1
        a2.title = "Light Tower"
        lights.append(a2)
        all.append(a2)
        mapView.addAnnotation(a2)
        
        let o1 = CLLocationCoordinate2DMake(36.264788, -115.02480)
        let a3 = MKPointAnnotation()
        a3.coordinate = o1
        a3.title = "Office"
        //offices.append(a3)
        //all.append(a3)
        //mapView.addAnnotation(a3)
        //33.681479, -116.238706
        let l2 = CLLocationCoordinate2DMake(37.402329, -121.971751)
        let a4 = MKPointAnnotation()
        a4.coordinate = l2
        a4.title = "Light Tower"
        lights.append(a4)
        all.append(a4)
        mapView.addAnnotation(a4)
        //36.276654, -115.012209
        let l3 = CLLocationCoordinate2DMake(37.401223, -121.970902)
        let a5 = MKPointAnnotation()
        a5.coordinate = l3
        a5.title = "Light Tower"
        lights.append(a5)
        all.append(a5)
        mapView.addAnnotation(a5)
        //33.684479, -116.242268
        let l4 = CLLocationCoordinate2DMake(37.402405, -121.973641)
        let a6 = MKPointAnnotation()
        a6.coordinate = l4
        a6.title = "Light Tower"
        lights.append(a6)
        all.append(a6)
        mapView.addAnnotation(a6)
        //33.683639, -116.234265
        let l5 = CLLocationCoordinate2DMake(37.401562, -121.973151)
        let a7 = MKPointAnnotation()
        a7.coordinate = l5
        a7.title = "Light Tower"
        lights.append(a7)
        all.append(a7)
        mapView.addAnnotation(a7)
        //33.684818, -116.237590
        let l6 = CLLocationCoordinate2DMake(37.403217, -121.974209)
        let a8 = MKPointAnnotation()
        a8.coordinate = l6
        a8.title = "Light Tower"
        lights.append(a8)
        all.append(a8)
        mapView.addAnnotation(a8)
        //33.678693, -116.240187
        let g2 = CLLocationCoordinate2DMake(37.403723, -121.971826)
        let a9 = MKPointAnnotation()
        a9.coordinate = g2
        a9.title = "Generator"
        generators.append(a9)
        all.append(a9)
        mapView.addAnnotation(a9)
        
        //33.680086, -116.241517
        let g3 = CLLocationCoordinate2DMake(37.401461, -121.970010)
        let a10 = MKPointAnnotation()
        a10.coordinate = g3
        a10.title = "Generator"
        generators.append(a10)
        all.append(a10)
        mapView.addAnnotation(a10)
        
        //33.678747, -116.234265
        let g4 = CLLocationCoordinate2DMake(37.400758, -121.974595)
        let a11 = MKPointAnnotation()
        a11.coordinate = g4
        a11.title = "Generator"
        generators.append(a11)
        all.append(a11)
        mapView.addAnnotation(a11)
        
        //33.681515, -116.244071
        let g5 = CLLocationCoordinate2DMake(37.402250, -121.971730)
        let a12 = MKPointAnnotation()
        a12.coordinate = g5
        a12.title = "Generator"
        generators.append(a12)
        all.append(a12)
        mapView.addAnnotation(a12)
        */
        //getInventories()
        
        let latDelta = cad.overlayTopLeftCoordinate.latitude -
            cad.overlayBottomRightCoordinate.latitude
        
        // Think of a span as a tv size, measure from one corner to another
        let span = MKCoordinateSpanMake(fabs(latDelta), 0.0)
        let region = MKCoordinateRegionMake(cad.midCoordinate, span)
        
        mapView.region = region
        
        addOverlay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getInventories()
        setupActionCable()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuView.hide()
        client.disconnect()
    }
    
    func setupActionCable() {
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
        
        let id = ["event_id": 1,"inventory_type_id": 21]
        //let id = ["event_id": 1]
        
        self.channel = client.create(InventoryMapViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        //self.channel = client.create(InventoryMapViewController.ChannelIdentifier)
        
        self.channel?.onSubscribed = {
            print("Subscribed to \(InventoryMapViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let json = JSON(data!)
            
            print(json)
            
            /*
            for incident in self.incidents {
                if let title = incident.title {
                    let arr = title.components(separatedBy: ":")
                    let findId = Int(arr[1].trimmingCharacters(in: .whitespacesAndNewlines))!
                    
                    if findId == id {
                        self.mapView.removeAnnotation(incident)
                        incident.title = "\(status): \(findId)"
                        self.mapView.addAnnotation(incident)
                    }
                }
            }
            
            for incident in self.filterArray {
                if let title = incident.title {
                    let arr = title.components(separatedBy: ":")
                    let findId = Int(arr[1].trimmingCharacters(in: .whitespacesAndNewlines))!
                    
                    if findId == id {
                        self.mapView.removeAnnotation(incident)
                        incident.title = "\(status): \(findId)"
                        self.mapView.addAnnotation(incident)
                    }
                }
            }
            */
        }
        
        self.client.connect()
    }
    
    func centerMapOnLocation() {
        //33.682336, -116.240337
        //print(inventories.last?.scans)
        if let lat = inventories.last?.lastScan?.latitude, let long = inventories.last?.lastScan?.longitude {
            let coord = CLLocationCoordinate2DMake(Double(lat), Double(long))
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(coord, regionRadius, regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
        }
    }
    
    @IBAction func changeMapType(_ sender: Any) {
        if mapChanged == false {
            mapChanged = true
            mapView.mapType = .hybrid
        } else {
            mapChanged = false
            mapView.mapType = .standard
        }
        
    }
    
    func getInventories() {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories?page=1&page_size=500&event_id=1&inventory_type_id=\(inventoryTypeId!)"
        print(path)
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        //"event_id": 1,
        //"inventory_type_id": 1,
        let parameters = [
            "event_id": 1,
            "inventory_type_id": 1
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonInventories = json["data"].arrayValue
                self.inventories.removeAll()
                //self.all.removeAll()
                
                for inventory in jsonInventories {
                    let i = Inventory(json: inventory)
                    
                    if i.lastScan?.scanType == "received" {
                        let rec = CLLocationCoordinate2DMake((i.lastScan?.latitude)!, (i.lastScan?.longitude)!)
                        let annot = MKPointAnnotation()
                        annot.coordinate = rec
                        annot.title = "Received: \(i.id)"
                        self.received.append(annot)
                        self.all.append(annot)
                        self.mapView.addAnnotation(annot)
                        self.inventories.append(i)
                        
                    } else if i.lastScan?.scanType == "assigned" {
                        let ass = CLLocationCoordinate2DMake((i.lastScan?.latitude)!, (i.lastScan?.longitude)!)
                        let annot = MKPointAnnotation()
                        annot.coordinate = ass
                        annot.title = "Assigned: \(i.id)"
                        self.assigned.append(annot)
                        self.all.append(annot)
                        self.mapView.addAnnotation(annot)
                        self.inventories.append(i)
                        
                    } else if i.lastScan?.scanType == "out_of_service" {
                        let oos = CLLocationCoordinate2DMake((i.lastScan?.latitude)!, (i.lastScan?.longitude)!)
                        let annot = MKPointAnnotation()
                        annot.coordinate = oos
                        annot.title = "Out of Service: \(i.id)"
                        self.outOfService.append(annot)
                        self.all.append(annot)
                        self.mapView.addAnnotation(annot)
                        self.inventories.append(i)
                        
                    } else {
                        
                    }
                }
                
                DispatchQueue.main.async {
                    //self.centerMapOnLocation()
                    print(self.all)
                }
                //print(self.inventories)
                
            case .failure:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mapInventorySegue" {
            //let id = sender as! Int
            let dvc = segue.destination as! GeneratorDetailViewController
            dvc.inventoryItem = sender as! Inventory
        }
    }
    
    func getInventoryItem(id: Int, completion: @escaping (Inventory) -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/\(id)"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let item = Inventory(json: json["data"])
                    
                completion(item)
            case .failure:
                break
            }
        }
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

extension InventoryMapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        //print(annotation)
        
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
            annotationView.canShowCallout = true
            annotationView.isDraggable = true
            //annotationView.centerOffset = CGPoint(x: 20, y: -15)
            
            if let title = annotationView.annotation?.title! {
                
                let arr = title.components(separatedBy: ":")
                
                annotationView.tag = Int(arr[1].trimmingCharacters(in: .whitespacesAndNewlines))!
                
                //print(arr[1].trimmingCharacters(in: .whitespacesAndNewlines))
                
                print(annotationView.tag)
                
                if inventoryTypeId == 21 {
                    switch arr[0] {
                    case "Assigned":
                        annotationView.image = UIImage(named: "green_oval")
                    case "Out of Service":
                        annotationView.image = UIImage(named: "red_oval")
                    case "Received":
                        annotationView.image = UIImage(named: "blue_oval")
                    default:
                        annotationView.image = UIImage(named: "blue_oval")
                    }
                    
                } else {
                    switch arr[0] {
                    case "Assigned":
                        annotationView.image = UIImage(named: "green_marker")
                    case "Out of Service":
                        annotationView.image = UIImage(named: "red_marker")
                    case "Received":
                        annotationView.image = UIImage(named: "blue_marker")
                    default:
                        annotationView.image = UIImage(named: "blue_marker")
                    }
                }
            }
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        getInventoryItem(id: view.tag) { (item) in
            self.performSegue(withIdentifier: "mapInventorySegue", sender: item)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        //print(view.annotation?.coordinate)
        switch newState {
        case .starting:
            view.dragState = .dragging
        case .ending, .canceling:
            view.dragState = .none
            
            let droppedAt = view.annotation?.coordinate
            /*
            if let found = find(all.map({ $0.t }), "Foo") {
                let obj = array[found]
            }
            */
            let ac = UIAlertController(title: "Pin Dropped", message: "pin dropped at: \(droppedAt!) id-tag: \(view.tag)", preferredStyle: .alert)
            let a1 = UIAlertAction(title: "Update Location", style: .default, handler: { (action) in
                self.getInventoryItem(id: view.tag, completion: { (inventory) in
                    let ii = inventory
                    
                    self.updateLocation(id: (ii.lastScan?.id)!, lat: "\((view.annotation?.coordinate.latitude)!)", long: "\((view.annotation?.coordinate.longitude)!)")
                })
                
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
            return CadMapOverlayView(overlay: overlay, overlayImage: UIImage(named: "edc_overlay")!) //UIImage(named: "event")
        }
        
        return MKOverlayRenderer()
        
    }
}
