//
//  IncidentViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/22/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import Alamofire
import SwiftyJSON
import ActionCableClient

class IncidentViewController: UIViewController, SettingsViewDelegate {

    //@IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    
    let realm = try! Realm()
    //var incidentAnnotation: MKAnnotation!
    //var regionRadius: CLLocationDistance = 500
    var responses = [["title": "Incident Reported by: Peter Hitchcock", "type": "Emergency"]]
    var timer: Timer!
    //var incidents = [MKPointAnnotation]()
    //var incident = MKPointAnnotation()
    var newIncident: Incident!
    internal var count: Int = 0
    internal var tbHeight: Int = 0
    var viewItems = [String]()
    var imageName = [String]()
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        return st
    }()
    var originalImage: UIImage!
    var client = ActionCableClient(url: URL(string: "wss://ontrackinventory.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "IncidentChannel"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Incident \(newIncident.id)"
        
        tableView.tableFooterView = UIView()
        
        /*
        //mapView.showsUserLocation = true
        mapView.showsTraffic = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        centerMapOnLocation()
        */
        
        //timer = Timer.scheduledTimer(timeInterval: 7, target: self, selector: #selector(addPins), userInfo: nil, repeats: true)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        setupSettingsView()
        status()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupActionCable()
        //timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(addPins), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        client.disconnect()
        //timer.invalidate()
    }
    
    func status() {
        switch newIncident.status {
        case "open":
            statusLabel.text = "Open"
            statusLabel.textColor = UIColor.flatRed
        case "in_progress":
            statusLabel.text = "In Progress"
            statusLabel.textColor = UIColor.flatGray
        case "resolved":
            statusLabel.text = "Resolved"
            statusLabel.textColor = UIColor.flatSkyBlue
        case "closed":
            statusLabel.text = "Closed"
            statusLabel.textColor = UIColor.flatGreen
        default:
            statusLabel.text = "Status"
            statusLabel.textColor = UIColor.white
        }
    }
    /*
    func centerMapOnLocation() {
        let coord = CLLocationCoordinate2DMake(newIncident.latitude, newIncident.longitude)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coord, regionRadius, regionRadius)
        let i = MKPointAnnotation()
        i.coordinate = coord
        i.title = "Incident: \(newIncident.id)"
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.addAnnotation(i)
    }
    */
    
    func setupSettingsView() {
        count = 3
        tbHeight = 48 * count
        
        let originalFrame = settingsView.tableView.frame
        let newHeight = count * tbHeight
        settingsView.tableView.frame = CGRect(x: originalFrame.origin.x, y: originalFrame.origin.y, width: originalFrame.size.width, height:CGFloat(Int(newHeight)))
        
        
        viewItems.append("Assign to Department")
        imageName.append("blue_scan")
        viewItems.append("Add Images")
        imageName.append("blue_scan")
        viewItems.append("Update Status")
        imageName.append("blue_scan")
        settingsView.items = viewItems
        settingsView.imageNames = imageName
    }
    
    func didSelectRow(indexPath: Int) {
        switch indexPath {
        case 0:
            assignDepartment()
        case 1:
            popImagePicker()
        case 2:
            let ac = UIAlertController(title: "Update Status", message: "Please select status to update", preferredStyle: UIAlertControllerStyle.alert)
            let aa = UIAlertAction(title: "Open", style: UIAlertActionStyle.default, handler: { (action) in
                self.updateStatus(id: self.newIncident.id, status: "open")
            })
            
            let aa1 = UIAlertAction(title: "In Progress", style: UIAlertActionStyle.default, handler: { (action) in
                self.updateStatus(id: self.newIncident.id, status: "in_progress")
            })
            
            let aa2 = UIAlertAction(title: "Resolved", style: UIAlertActionStyle.default, handler: { (action) in
                self.updateStatus(id: self.newIncident.id, status: "resolved")
            })
            
            let aa3 = UIAlertAction(title: "Closed", style: UIAlertActionStyle.default, handler: { (action) in
                self.updateStatus(id: self.newIncident.id, status: "closed")
            })
            
            let aa4 = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (action) in
                //self.updateStatus(id: self.newIncident.id, status: "closed")
            })
            
            ac.addAction(aa)
            ac.addAction(aa1)
            ac.addAction(aa2)
            ac.addAction(aa3)
            ac.addAction(aa4)
            
            self.present(ac, animated: true, completion: nil)
            
        default:
            break
        }
    }
    
    func hideSettingsView(status: Bool) {
        if status == true {
            settingsView.removeFromSuperview()
        }
    }
    
    @IBAction func pressedMoreButton(_ sender: UIBarButtonItem) {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
        }
    }
    
    func assignDepartment() {
        let ac = UIAlertController(title: "Scan", message: "Scan inventory item", preferredStyle: .alert)
        let aa = UIAlertAction(title: "Exterior Perimeter", style: UIAlertActionStyle.default) { (action) in
            self.changeDepartment(id: self.newIncident.id, departmentId: 1)
        }
        let aa1 = UIAlertAction(title: "Interior Venue", style: .default) { (action) in
            self.changeDepartment(id: self.newIncident.id, departmentId: 2)
        }
        
        ac.addAction(aa)
        ac.addAction(aa1)
        self.present(ac, animated: true, completion: nil)
        
        
        /*
        let dialog = AZDialogViewController(title: "Change Department", message: "Change Department")
        
        dialog.dismissDirection = .bottom
        dialog.dismissWithOutsideTouch = true
        dialog.showSeparator = false
        dialog.separatorColor = UIColor.flatSkyBlue
        dialog.allowDragGesture = true
        
        dialog.buttonStyle = { (button,height,position) in
            //button.setBackgroundImage(UIImage.imageWithColor(self.primaryColorDark), for: .highlighted)
            button.setTitleColor(UIColor.white, for: .highlighted)
            button.setTitleColor(UIColor.flatSkyBlue, for: .normal)
            button.layer.masksToBounds = true
            button.layer.borderColor = UIColor.flatSkyBlue.cgColor//self.primaryColor.cgColor
        }
        
        
        
        dialog.addAction(AZDialogAction(title: "Site Ops") { (dialog) -> (Void) in
            
            dialog.dismiss()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.changeDepartment(id: self.newIncident.id, departmentId: 1)
            }
            
        })
        
        dialog.addAction(AZDialogAction(title: "Transportation") { (dialog) -> (Void) in
            
            dialog.dismiss()
            
            self.changeDepartment(id: self.newIncident.id, departmentId: 2)
            
        })
        
        
        dialog.cancelEnabled = true
        
        dialog.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor.flatSkyBlue
            button.setTitle("CANCEL", for: [])
            return true //must return true, otherwise cancel button won't show.
        }
        
        self.present(dialog, animated: false, completion: nil)
        */
        
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
        
        let id = ["event_id": 1, "incident_id": newIncident.id]
        //let id = ["event_id": 1]
        
        self.channel = client.create(IncidentViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        //self.channel = client.create(IncidentViewController.ChannelIdentifier)
        
        self.channel?.onSubscribed = {
            print("Subscribed to \(IncidentViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let json = JSON(data!)
            print(json)
            
            self.newIncident.status = json["status"].stringValue
            
            self.status()
            
            self.newIncident.images.removeAll()
            for image in json["all_images"].arrayValue {
                let i = Media()
                i.imageUrl = image.stringValue
                self.newIncident.images.append(i)
            }
            
            let storyboard = UIStoryboard(name: "Inventory", bundle: Bundle.main)
            
            let viewController = storyboard.instantiateViewController(withIdentifier: "IncidentMapViewController") as! IncidentMapViewController
            viewController.incident = self.newIncident
            
            let viewController1 = storyboard.instantiateViewController(withIdentifier: "IncidentImageViewController") as! IncidentImageViewController
            viewController1.incident = self.newIncident
            
            
            //print("JSON FROM ACTION CABLE \(json)")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "incident"), object: self)
                //self.tableView.reloadData()
            }
            
        }
        
        self.client.connect()
    }
    
    func changeDepartment(id: Int, departmentId: Int) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/incidents/\(id)?event_id=1&department_id=\(departmentId)"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let parameters = [
            "event_id": 1,
            "department_id": departmentId,
            "inventory_id": id,
            "incident_type": "inventory",
            "status": "open",
            "images": [],
            "priority": "low"
            ] as [String : Any]
        
        Alamofire.request(path, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            //print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                //print(json)
                /*
                self.loadingIndicator(title: "Assigning Department...", message: "Please wait untile completed", dialogTitle: "Success", dialogMessage: "Inventory item has been reassigned", dialogButtonTitle: "OK")
                */
            case .failure:
                break
            }
        }
    }
    
    func updateStatus(id: Int, status: String) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/incidents/\(id)"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let parameters = [
            "event_id": 1,
            "department_id": 1,
            "inventory_id": id,
            "incident_type": "inventory",
            "status": status,
            "images": [],
            "priority": "low"
            ] as [String : Any]
        
        Alamofire.request(path, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                //print(json)
                /*
                 self.loadingIndicator(title: "Assigning Department...", message: "Please wait untile completed", dialogTitle: "Success", dialogMessage: "Inventory item has been reassigned", dialogButtonTitle: "OK")
                 */
            case .failure:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "incidentPageViewSegue" {
            let dvc = segue.destination as! IncidentPageViewController
            dvc.incident = self.newIncident
        }
    }
    
    /*
    func addPins() {
        //34.062247, -118.398464
        //34.059634, -118.398014
        //34.060203, -118.398014
        //34.060399, -118.399087
        
        if responses.count > 4 {
            
        } else {
            mapView.removeAnnotations(incidents)
            switch responses.count {
            case 0:
                //34.042435, -118.263310
                let coord = CLLocationCoordinate2DMake(37.402374, -121.971830)
                let annot = MKPointAnnotation()
                annot.coordinate = coord
                incidents.append(annot)
                //mapView.addAnnotation(annot)
                mapView.addAnnotations(incidents)
                responses.append(["title": "John Conway" , "type": "Responding to Incident"])
                tableView.reloadData()
            case 1:
                //34.043173, -118.262204
                let coord = CLLocationCoordinate2DMake(37.402492, -121.971383)
                let annot = MKPointAnnotation()
                annot.coordinate = coord
                annot.title = "Responding"
                incidents.append(annot)
                //mapView.addAnnotation(annot)
                mapView.addAnnotations(incidents)
                responses.append(["title": "Peter Hitchcock" , "type": "Responding to Incident"])
                tableView.reloadData()
                /*
            case 2:
                let coord = CLLocationCoordinate2DMake(34.042639, -118.262290)
                let annot = MKPointAnnotation()
                annot.coordinate = coord
                annot.title = "Responding"
                incidents.append(annot)
                //mapView.addAnnotation(annot)
                mapView.addAnnotations(incidents)
                responses.append(["title": "Lauren Rippee" , "type": "Responding to Incident"])
                tableView.reloadData()
                */
            case 2:
                //34.041767, -118.262829
                let coord = CLLocationCoordinate2DMake(37.403017, -121.973234)
                let annot = MKPointAnnotation()
                annot.coordinate = coord
                annot.title = "Responding"
                incidents.append(annot)
                mapView.addAnnotations(incidents)
                //mapView.addAnnotation(annot)
                responses.append(["title": "Jimmy Engelman" , "type": "Responding to Incident"])
                tableView.reloadData()
            case 3:
                //34.042345, -118.262986
                let coord = CLLocationCoordinate2DMake(37.401200, -121.972764)
                let annot = MKPointAnnotation()
                annot.coordinate = coord
                annot.title = "Responding"
                incidents.append(annot)
                mapView.addAnnotations(incidents)
                //mapView.addAnnotation(annot)
                responses.append(["title": "John Conway" , "type": "Responding to Incident"])
                tableView.reloadData()
            case 4:
                mapView.removeAnnotation(incident)
                let coord = CLLocationCoordinate2DMake(37.402374, -121.971830)
                let incidentClosed = MKPointAnnotation()
                incidentClosed.coordinate = coord
                incidentClosed.title = "Closed"
                mapView.addAnnotation(incidentClosed)
                responses.append(["title": "Incident Closed by: Peter Hitchcock", "type": "Emergency"])
                tableView.reloadData()
            default:
                let coord = CLLocationCoordinate2DMake(37.402374, -121.971830)
                let annot = MKPointAnnotation()
                annot.coordinate = coord
                annot.title = "Responding"
                incidents.append(annot)
                //mapView.addAnnotation(annot)
                responses.append(["title": "John Conway" , "type": "Responding to Incident"])
                tableView.reloadData()
            }
        }
    }
    */
}
/*
extension IncidentViewController: MKMapViewDelegate {
    
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

                switch newIncident.status {
                case "open":
                    annotationView.image = UIImage(named: "out_of_service")
                case "in_progress":
                    annotationView.image = UIImage(named: "other")
                case "resolved":
                    annotationView.image = UIImage(named: "drop")
                case "closed":
                    annotationView.image = UIImage(named: "drop")
                default:
                    break
            }
        }
        
        return annotationView
    }
    
}
*/
extension IncidentViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return responses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "incidentCell", for: indexPath) as! ItemTableViewCell
        cell.checkOutLabel.text = responses[indexPath.row]["title"]
        cell.timeLabel.text = responses[indexPath.row]["type"]
        switch indexPath.row {
        case 0:
            cell.reasonView.backgroundColor = UIColor.flatRed
        case 4:
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

extension IncidentViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func uploadImage(id: Int, image: String) {
        
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/incidents/\(id)"
        //print(path)
        let headers = [
            "Content-type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let parameters = [
            "event_id": 1,
            "incident_type": "inventory",
            "status": "open",
            "department_id": 1,
            "inventory_id": id,
            "images": [["base64_image": "data:image/png;base64,\(image)"]],
            "priority": "low"
        ] as [String : Any]
        
        Alamofire.request(path, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            //print(response)
            if let requestBody = response.request?.httpBody {
                do {
                    let jsonArray = try JSONSerialization.jsonObject(with: requestBody, options: [])
                    //print("Array: \(jsonArray)")
                }
                catch {
                    print("Error: \(error)")
                }
            }
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                //print(json)
                /*
                self.loadingIndicator(title: "Uploading...", message: "Uploading image, please wait", dialogTitle: "Success!", dialogMessage: "Image Uploaded", dialogButtonTitle: "Add Image")
                */
            case .failure:
                break
            }
        }
        
    }
    
    func popImagePicker() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            imagePicker.delegate = self
            
            imagePicker.modalPresentationStyle = .popover
            imagePicker.popoverPresentationController?.delegate = self
            imagePicker.popoverPresentationController?.sourceView = view
            imagePicker.modalPresentationStyle = .popover
            imagePicker.popoverPresentationController?.delegate = self
            imagePicker.popoverPresentationController?.sourceView = view

            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        //addImagesAlert()
    }
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            // Use editedImage Here
            //print(picker.tag)
            originalImage = editedImage
            
            
            let img = originalImage
            let jpegCompressionQuality: CGFloat = 0.1
            
            
            if let base64String = UIImageJPEGRepresentation(originalImage.resize(maxWidthHeight: 200.0)!, jpegCompressionQuality)?.base64EncodedString() {

                //self.setupActionCable()
                self.uploadImage(id: newIncident.id, image: base64String)
            }
            
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Use originalImage Here
            print("original")
        }
        
        
        picker.dismiss(animated: true)
        
    }
}

extension IncidentViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        //view.alpha = 1.0
    }
}
