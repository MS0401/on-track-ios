//
//  LocationViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/21/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import ACProgressHUD_Swift
import CoreNFC
import RealmSwift
import Alamofire
import SwiftyJSON
import BTNavigationDropdownMenu
import ActionCableClient

@available(iOS 11.0, *)
class LocationViewController: UIViewController {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var incidentButton: UIButton!
    //@IBOutlet weak var scanButton: UIButton!
    
    let realm = try! Realm()
    private var locationManager: CLLocationManager!
    var regionRadius: CLLocationDistance = 1000
    var showIncidents = false
    var incidents = [MKPointAnnotation]()
    var filterArray = [MKPointAnnotation]()
    var incidentAnnotation: MKAnnotation!
    private var nfcSession: NFCNDEFReaderSession!
    private var nfcMessages: [[NFCNDEFMessage]] = []
    var payload = ""
    var allIncidents = [Incident]()
    var menuView: BTNavigationDropdownMenu!
    var items = ["All", "Open", "In Progress", "Resolved", "Closed"]
    var mapChanged = false
    var client = ActionCableClient(url: URL(string: "wss://ontrackinventory.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "IncidentChannel"
    var cad = Cad()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuView = BTNavigationDropdownMenu(title: items[0], items: items as [AnyObject])
        
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
            switch indexPath {
            case 0:
                /*
                self.mapView.removeAnnotations(self.all)
                self.mapView.removeAnnotations(self.received)
                self.mapView.removeAnnotations(self.assigned)
                self.mapView.removeAnnotations(self.outOfService)
                self.mapView.addAnnotations(self.all)
                 */
        
                self.mapView.removeAnnotations(self.incidents)
                self.mapView.removeAnnotations(self.filterArray)
                self.filterArray.removeAll()
                for incident in self.incidents {
                    self.filterArray.append(incident)
                }
                self.mapView.addAnnotations(self.filterArray)
            case 1:
                self.filterArray.removeAll()
                self.mapView.removeAnnotations(self.filterArray)
                self.mapView.removeAnnotations(self.incidents)
                for incident in self.incidents {
                    if let title = incident.title {
                        let arr = title.components(separatedBy: ":")
                        if arr[0] == "open" {
                            self.filterArray.append(incident)
                        }
                    }
                    self.mapView.addAnnotations(self.filterArray)
                }
            case 2:
                self.filterArray.removeAll()
                self.mapView.removeAnnotations(self.filterArray)
                self.mapView.removeAnnotations(self.incidents)
                for incident in self.incidents {
                    if let title = incident.title {
                        let arr = title.components(separatedBy: ":")
                        if arr[0] == "in_progress" {
                            self.filterArray.append(incident)
                        }
                    }
                    self.mapView.addAnnotations(self.filterArray)
                }
            case 3:
                self.filterArray.removeAll()
                self.mapView.removeAnnotations(self.filterArray)
                self.mapView.removeAnnotations(self.incidents)
                for incident in self.incidents {
                    if let title = incident.title {
                        let arr = title.components(separatedBy: ":")
                        if arr[0] == "resolved" {
                            self.filterArray.append(incident)
                        }
                    }
                    self.mapView.addAnnotations(self.filterArray)
                }
            case 4:
                self.filterArray.removeAll()
                self.mapView.removeAnnotations(self.filterArray)
                self.mapView.removeAnnotations(self.incidents)
                for incident in self.incidents {
                    if let title = incident.title {
                        let arr = title.components(separatedBy: ":")
                        if arr[0] == "closed" {
                            self.filterArray.append(incident)
                        }
                    }
                    self.mapView.addAnnotations(self.filterArray)
                }
            default:
                break
            }
        }
        
        navigationItem.titleView = menuView
        
        /*
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        */
        
        mapView.showsUserLocation = true
        mapView.showsTraffic = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        incidentButton.layer.cornerRadius = 10
        incidentButton.layer.borderWidth = 1
        incidentButton.layer.borderColor = UIColor(red: 255/255, green: 38/255, blue: 53/255, alpha: 1.0).cgColor
        incidentButton.clipsToBounds = true
        
        /*
        scanButton.layer.cornerRadius = 10
        scanButton.layer.borderWidth = 1
        scanButton.layer.borderColor = UIColor(colorLiteralRed: 84/255, green: 190/255, blue: 255/255, alpha: 1.0).cgColor
        scanButton.clipsToBounds = true
        */
        
        /*
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            centerMapOnUserLocation()
        }
        */

        //centerMapOnUserLocation()
        //addOverlay()
        
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
        setupActionCable()
        getIncidents(eventId: 1) { (incidents) in
            self.allIncidents = incidents
            for incident in self.allIncidents {
                let annot = MKPointAnnotation()
                annot.coordinate = CLLocationCoordinate2D(latitude: incident.latitude, longitude: incident.longitude)
                annot.title = "\(incident.status): \(incident.id)"
                self.incidents.append(annot)
            }
            DispatchQueue.main.async {
                self.mapView.addAnnotations(self.incidents)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuView.hide()
        client.disconnect()
    }
    
    @IBAction func reportIncident(_ sender: UIButton) {
        loadingIndicator()
    }
    
    @IBAction func scanAttendee(_ sender: UIButton) {
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: true)
        nfcSession.alertMessage = "You can scan NFC-tags by holding them behind the top of your iPhone."
        nfcSession.begin()
        print("tapped")
    }
    
    @IBAction func centerUserLocationOnMap(_ sender: UIButton) {
        //centerMapOnUserLocation()
        if mapChanged == false {
            mapChanged = true
            mapView.mapType = .hybrid
        } else {
            mapChanged = false
            mapView.mapType = .standard
        }
    }
    
    @IBAction func allIncidents(_ sender: UIBarButtonItem) {
        showIncidents = true
        if showIncidents == true {
            mapView.removeAnnotations(incidents)
            mapView.addAnnotations(incidents)
        }
    }
    
    func loadingIndicator(){
        let dialog = AZDialogViewController(title: "Report Incident", message: "Please select incident reason to report")
        
        let container = dialog.container
        
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        dialog.container.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        indicator.startAnimating()
        
        
        dialog.buttonStyle = { (button,height,position) in
            //button.setBackgroundImage(UIImage.imageWithColor(self.primaryColorDark), for: .highlighted)
            button.setTitleColor(UIColor.white, for: .highlighted)
            button.setTitleColor(UIColor.flatSkyBlue, for: .normal)
            button.layer.masksToBounds = true
            button.layer.borderColor = UIColor.flatSkyBlue.cgColor//self.primaryColor.cgColor
        }
        
        //dialog.animationDuration = 5.0
        dialog.customViewSizeRatio = 0.0
        dialog.dismissDirection = .none
        dialog.allowDragGesture = false
        dialog.dismissWithOutsideTouch = true
        dialog.show(in: self)
        
        dialog.addAction(AZDialogAction(title: "Inventory", handler: { (dialog) -> (Void) in
            let incident = MKPointAnnotation()
            incident.coordinate = CLLocationCoordinate2D(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude)
            incident.title = "Inventory"
            
            self.createIncident(departmentId: 1, inventoryId: nil, description: "incident", status: "open", completion: { (incident) in
                self.performSegue(withIdentifier: "incidentSegue", sender: incident)
            })
            //self.incidents.append(incident)
            //self.mapView.addAnnotation(incident)
            //self.postNotificationVC(reason: 14)
            dialog.dismiss()
        }))
        
        dialog.addAction(AZDialogAction(title: "Emergency", handler: { (dialog) -> (Void) in
            let incident = MKPointAnnotation()
            incident.coordinate = CLLocationCoordinate2D(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude)
            incident.title = "Emergency"
            
            self.createIncident(departmentId: 1, inventoryId: nil, description: "incident", status: "open", completion: { (incident) in
                self.performSegue(withIdentifier: "incidentSegue", sender: incident)
            })
            //self.incidents.append(incident)
            //self.mapView.addAnnotation(incident)
            //self.postNotificationVC(reason: 14)
            dialog.dismiss()
        }))
        
        dialog.addAction(AZDialogAction(title: "Medical", handler: { (dialog) -> (Void) in
            let incident = MKPointAnnotation()
            incident.coordinate = CLLocationCoordinate2D(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude)
            incident.title = "Medical"
            self.incidents.append(incident)
            self.mapView.addAnnotation(incident)
            self.postNotificationVC(reason: 15)
            dialog.dismiss()
        }))
        
        dialog.addAction(AZDialogAction(title: "Police", handler: { (dialog) -> (Void) in
            let incident = MKPointAnnotation()
            incident.coordinate = CLLocationCoordinate2D(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude)
            incident.title = "Police"
            self.incidents.append(incident)
            self.mapView.addAnnotation(incident)
            self.postNotificationVC(reason: 16)
            dialog.dismiss()
        }))
        
        dialog.cancelEnabled = !dialog.cancelEnabled
        dialog.dismissDirection = .bottom
        dialog.allowDragGesture = true
        //indicator.stopAnimating()
        
        dialog.cancelButtonStyle = { (button,height) in
            //button.tintColor = UIColor.flatSkyBlue
            button.setTitle("Cancel", for: [])
            return false
        }
    }
    
    func incidentInfo(title: String){
        let dialog = AZDialogViewController(title: title,
                                            message: "Location: \nReported by: ")
        
        let container = dialog.container
        
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        dialog.container.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        indicator.startAnimating()
        
        
        dialog.buttonStyle = { (button,height,position) in
            //button.setBackgroundImage(UIImage.imageWithColor(self.primaryColorDark), for: .highlighted)
            button.setTitleColor(UIColor.white, for: .highlighted)
            button.setTitleColor(UIColor.flatSkyBlue, for: .normal)
            button.layer.masksToBounds = true
            button.layer.borderColor = UIColor.flatSkyBlue.cgColor//self.primaryColor.cgColor
        }
        
        //dialog.animationDuration = 5.0
        dialog.customViewSizeRatio = 0.0
        dialog.dismissDirection = .none
        dialog.allowDragGesture = false
        dialog.dismissWithOutsideTouch = true
        dialog.show(in: self)
        
        dialog.addAction(AZDialogAction(title: "Incident Info", handler: { (dialog) -> (Void) in
            dialog.dismiss()
            self.performSegue(withIdentifier: "incidentSegue", sender: self)
        }))
        
        dialog.addAction(AZDialogAction(title: "Responding", handler: { (dialog) -> (Void) in
            dialog.dismiss()
        }))
        
        dialog.addAction(AZDialogAction(title: "Cancel", handler: { (dialog) -> (Void) in
            dialog.dismiss()
        }))
        
        dialog.dismissDirection = .bottom
        dialog.allowDragGesture = true
        
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
        
        let id = ["event_id": 1]
        //let id = ["event_id": 1]
        
        self.channel = client.create(LocationViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        //self.channel = client.create(LocationViewController.ChannelIdentifier)
        
        self.channel?.onSubscribed = {
            print("Subscribed to \(LocationViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let json = JSON(data!)
            
            let id = json["id"].intValue
            let status = json["status"].stringValue
            
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
        }
        
        self.client.connect()
    }
    
    func createIncident(departmentId: Int, inventoryId: Int?, description: String, status: String, completion: @escaping (Incident) -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/incidents"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let parameters = [
            "event_id": 1,
            "incident_type": "inventory",
            "department_id": departmentId,
            "inventory_id": inventoryId,
            "description": description,
            "status": status,
            "location_attributes": ["longitude": "\(user!.lastLocation!.longitude)", "latitude": "\(user!.lastLocation!.latitude)"],
            "images": [],
            "priority": "low"
            
            ] as [String : Any]
        
        print(parameters)
        
        Alamofire.request(path, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                
                let incident = Incident(json: json["data"])
                completion(incident)
                
            case .failure:
                break
            }
        }
    }
    
    func getIncidents(eventId: Int, completion: @escaping ([Incident]) -> ()) {
        //print("getincidnets")
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/incidents?page=1&page_size=50&event_id=1"
        //print(path)
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(json)
                var incidents = [Incident]()
                
                for incident in json["data"].arrayValue {
                    let i = Incident(json: incident)
                    incidents.append(i)
                }
                
                completion(incidents)
            case .failure:
                break
            }
        }
    }
    
    func getIncident(eventId: Int, incidentId: Int, completion: @escaping (Incident) -> ()) {
        
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/incidents/\(incidentId)?event_id=1"
       
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                //print(json)
                let i = Incident(json: json["data"])
            
                completion(i)
            case .failure:
                break
            }
        }
    }
    
    func postNotificationVC(reason: Int) {
        let progressView = ACProgressHUD.shared
        progressView.progressText = "Sending Incident Report..."
        progressView.showHUD()
        
        APIManager.shared.postNotification(reason: reason, latitude: Float(mapView.userLocation.coordinate.latitude), longitude: Float(mapView.userLocation.coordinate.longitude), driver_id: 5, phone_number: "9168470003", event_id: 1, changeRouteId: nil) { (error) in
        
            if error != nil {
                progressView.hideHUD()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.errorAlert(title: "Incident Not Received", subtitle: "Your incident report was not received please try again")
                })
                
            } else {
                progressView.hideHUD()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.completionAlert(title: "Incident Reported", subtitle: "Incident report received, thank you")
                })
            }
        }
    }
    
    func completionAlert(title: String, subtitle: String) {
        _ = SweetAlert().showAlert(title, subTitle: subtitle, style: AlertStyle.success, buttonTitle:  "Ok", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
        }
    }
    
    func errorAlert(title: String, subtitle: String) {
        _ = SweetAlert().showAlert(title, subTitle: subtitle, style: AlertStyle.error, buttonTitle:  "Try Again", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "incidentSegue" {
            let dvc = segue.destination as! IncidentViewController
            dvc.newIncident = sender as! Incident
        }
    }
}

@available(iOS 11.0, *)
extension LocationViewController: MKMapViewDelegate {
    
    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        showIncidents = false
        mapView.removeAnnotations(incidents)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //incidentInfo(title: ((view.annotation?.title)!)!)
        //incidentAnnotation = view.annotation
        getIncident(eventId: 1, incidentId: view.tag) { (incident) in
            print("from map view: \(incident)")
            self.performSegue(withIdentifier: "incidentSegue", sender: incident)
        }
    }
    
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
            annotationView.canShowCallout = true
            
            if let title = annotationView.annotation?.title! {
                
                let arr = title.components(separatedBy: ":")
                
                annotationView.tag = Int(arr[1].trimmingCharacters(in: .whitespacesAndNewlines))!
                
                //print(annotationView.tag)
                
                switch arr[0] {
                case "open":
                    annotationView.image = UIImage(named: "out_of_service")
                case "in_progress":
                    annotationView.image = UIImage(named: "other")
                case "resolved":
                    annotationView.image = UIImage(named: "drop")
                case "closed":
                    annotationView.image = UIImage(named: "drop")
                default:
                    annotationView.image = UIImage(named: "other")
                }
            }
        }
        
        return annotationView
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

@available(iOS 11.0, *)
extension LocationViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        } else {
            //mapView.showsUserLocation = true
            //mapView.userTrackingMode = .followWithHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        /*
        if let userLocation = locations.last {
            
            //let viewRegion = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 2000, 2000)
            //mapView.setRegion(viewRegion, animated: false)
        }
        */
    }
}

@available(iOS 11.0, *)
extension LocationViewController: NFCNDEFReaderSessionDelegate {
    
    // Called when the reader-session expired, you invalidated the dialog or accessed an invalidated session
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC-Session invalidated: \(error.localizedDescription)")
        
    }
    
    // Called when a new set of NDEF messages is found
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("New NFC Messages (\(messages.count)) detected:")
        
        for message in messages {
            print(" - \(message.records.count) Records:")
            print(message)
            
            for record in message.records {
                print(record.identifier)
                print("\t- Payload: \(String(data: record.payload, encoding: .utf8)!)")
                print("\t- Type: \(record.type)")
                print("\t- Identifier: \(record.identifier)\n")
                //self.payload = String(data: record.payload, encoding: .utf8)!
                
                let first = String(data: record.payload, encoding: .utf8)!.dropFirst()
                var second = first.dropFirst()
                var third = second.dropFirst()
                
                self.payload = String(third)
                
                print("----------------\(third)")
                print("----------------\(self.payload)")
                
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.loadingIndicator()
        })
        
        //attendeeScaned()
        /*
         // Add the new messages to our found messages
         self.nfcMessages.append(messages)
         
         // Reload our table-view on the main-thread to display the new data-set
         DispatchQueue.main.async {
         self.tableView.reloadData()
         }
         */
    }
}
