//
//  DriverDetailViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/31/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import SwiftyJSON
import SwiftDate
import RealmSwift
import ActionCableClient
//import Starscream

class DriverDetailViewController: UIViewController, SettingsViewDelegate/*, WebSocketDelegate*/ {
    
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loopsLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var driveTimeLabel: UILabel!
    @IBOutlet weak var timeFromScanLabel: UILabel!
    @IBOutlet weak var negativeHours: UILabel!
    
    var driver: RealmDriver!
    var shift: Shift!
    var driverId: Int!
    var timer: Timer?
    var realm = try! Realm()
    var scans = [Scan]()
    var cell = ""
    internal var count: Int = 0
    internal var tbHeight: Int = 0
    var viewItems = [String]()
    var imageName = [String]()
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        return st
    }()
    var center: CLLocationCoordinate2D!
    var region: MKCoordinateRegion!
    var negativeTime: Int!
    var fromHours = false
    var negativehours = 0
    var client = ActionCableClient(url: URL(string: "wss://ontrackmanagement.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "DriversChannel"
    var dropPin = MKPointAnnotation()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loopsLabel.text = ""
        timeLabel.text = ""
        driveTimeLabel.text = ""
        timeFromScanLabel.text = ""
        negativeHours.text = ""
        
        loopsLabel.alpha = 0.0
        timeFromScanLabel.alpha = 0.0
        timeLabel.alpha = 0.0
        driveTimeLabel.alpha = 0.0
        negativeHours.alpha = 0.0
        
        mapView.showsTraffic = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        if let shift = self.shift {
            self.shift = shift
        }
        
        driverId = driver.id
        
        getDriver(nil)
        
        tableView.tableFooterView = UIView()
        
        if driverId == currentUser?.id {
            navigationItem.rightBarButtonItem = nil
        } else {
            setupSettingsView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        driverTest()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
        
        let id = ["driver_id" : driverId, "event_id": shift.eventId]
        
        self.channel = client.create(DriverDetailViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        //self.channel = client.create(DriverDetailViewController.ChannelIdentifier)
        self.channel?.onSubscribed = {
            print("Subscribed to \(DriverDetailViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let JSONObject = JSON(data!)
            let jsonScan = JSONObject["scan"]
            let jsonLocation = JSONObject["last_location"]
            print("JSONObject -----------> \(JSONObject)")
            
            let scan = Scan(json: jsonScan)
            self.scans.insert(scan, at: 0)
            
            self.driver.lastLocation?.latitude = jsonLocation["latitude"].floatValue
            self.driver.lastLocation?.longitude = jsonLocation["longitude"].floatValue
            
            self.center = CLLocationCoordinate2D(latitude: Double((self.driver.lastLocation?.latitude)!), longitude: Double((self.driver.lastLocation?.longitude)!))
            self.region = MKCoordinateRegion(center: self.center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
            
            DispatchQueue.main.async {
                //self.tableView.reloadData()
                self.filterArray()
                self.loopsLabel.text = "\(self.scanCount())"
                self.timeFromScanLabel.text = "\(self.timeBetweenScans().tn) min"
                self.timeLabel.text = "\(self.timeBetweenScans().tb) min"
                self.driveTimeLabel.text = "\(self.timeBetweenScans().dt) hrs"
                self.mapView.removeAnnotation(self.dropPin)
                self.mapView.setRegion(self.region, animated: false)
                self.addPin(location: self.driver.lastLocation!)
            }
        }
        
        self.client.connect()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.client.disconnect()
    }
    
    /*
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocket is connected")
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("got some text: \(text)")
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("got some data: \(data.count)")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("disconnected")
    }
    */
    
    func setupSettingsView() {
        count = 6
        tbHeight = 48 * count
        
        let originalFrame = settingsView.tableView.frame
        let newHeight = count * tbHeight
        settingsView.tableView.frame = CGRect(x: originalFrame.origin.x, y: originalFrame.origin.y, width: originalFrame.size.width, height:CGFloat(Int(newHeight)))
        
        viewItems.append("Text Driver")
        imageName.append("comments")
        viewItems.append("System SMS")
        imageName.append("comments")
        viewItems.append("Call Driver")
        imageName.append("phone")
        viewItems.append("Scan")
        imageName.append("blue_scan")
        viewItems.append("Notes")
        imageName.append("blue_note")
        viewItems.append("Cancel")
        imageName.append("blue_close")
        settingsView.items = viewItems
        settingsView.imageNames = imageName
    }

    func didSelectRow(indexPath: Int) {
        if indexPath == 0 {
            
            if driver.cell != "" {
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
        } else if indexPath == 3 {
            performSegue(withIdentifier: "manualScanSegue", sender: self)
        } else if indexPath == 4 {
            performSegue(withIdentifier: "notesSegue", sender: self)
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
    
    func filterArray() {
        scans = scans.sorted(by: {$0.created_at! > $1.created_at!})
        
        tableView.reloadData()
    }
    
    func scanCount() -> Int {
        var scans = [Scan]()
        scans.removeAll()
        for s in self.scans {
            if s.reason == "drop_unload" {
                scans.append(s)
            }
        }
        return scans.count
    }
    
    func timeBetweenScans() -> (tn: Int, tb: Int, dt: String) {
        var lastScan: String!
        var firstScan: String!
        var prevScan: String!
        let timeDotNow = DateInRegion()
        
        if self.scans.count == 1 {
            lastScan = (self.scans.first?.created_at)!
            
            let ls = DateInRegion(string: lastScan, format: DateFormat.iso8601Auto)
            let timeNow = Int(abs((timeDotNow - ls!) / 60).rounded())
            let driveTime = Double(abs((timeDotNow - ls!) / 60).rounded() / 60)
            let sFormat = String(format: "%.2f", driveTime)
            return (timeNow, 0, sFormat)
            
        } else if self.scans.count > 1 {
            lastScan = (self.scans.first?.created_at)!
            firstScan = (self.scans.last?.created_at)!
            
            //let i = self.scans[1]
            prevScan = self.scans[1].created_at!
            
            let ls = DateInRegion(string: lastScan, format: DateFormat.iso8601Auto)
            let ps = DateInRegion(string: prevScan, format: DateFormat.iso8601Auto)
            let fs = DateInRegion(string: firstScan, format: DateFormat.iso8601Auto)
            
            let timeNow = Int(abs((timeDotNow - ls!) / 60).rounded())
            let timeBetween = Int(abs((ls! - ps!) / 60).rounded())
            let driveTime = Double(abs((timeDotNow - fs!) / 60).rounded() / 60)
            let sFormat = String(format: "%.2f", driveTime)
            
            return (timeNow, timeBetween, sFormat)
        } else {
           return (0, 0, "0")
        }
    }
    
    func getDriver(_ notification: NSNotification?) {
        
        APIManager.shared.getDriverInfo(eventId: shift.eventId, shiftId: shift.id, driverId: driverId, completion: { (driver) in
            
            self.scans.removeAll()
            for scan in driver.scans {
                self.scans.append(scan)
            }
            self.cell = driver.cell!
            self.driver = driver
            
            DispatchQueue.main.async {
                
                self.title = driver.name
                self.mapView.removeAnnotation(self.dropPin)
                self.filterArray()
                
                if driver.lastLocation?.driver_id != 0 {
                    self.center = CLLocationCoordinate2D(latitude: Double((driver.lastLocation?.latitude)!), longitude: Double((driver.lastLocation?.longitude)!))
                    self.region = MKCoordinateRegion(center: self.center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
                    self.mapView.setRegion(self.region, animated: true)
                    self.addPin(location: driver.lastLocation!)
                    
                } else if self.scans.count > 0 {
                    self.center = CLLocationCoordinate2D(latitude: Double((self.scans.last?.latitude)!), longitude: Double((self.scans.last?.longitude)!))
                    self.region = MKCoordinateRegion(center: self.center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
                    
                    let pinCoord = CLLocationCoordinate2DMake(CLLocationDegrees((self.scans.last?.latitude)!), CLLocationDegrees((self.scans.last?.longitude)!))
                    let dropPin = MKPointAnnotation()
                    
                    dropPin.coordinate = pinCoord
                    
                    self.mapView.setRegion(self.region, animated: true)
                    self.mapView.addAnnotation(dropPin)
                }
                
                self.loopsLabel.text = "\(self.scanCount())"
                self.timeFromScanLabel.text = "\(self.timeBetweenScans().tn) min"
                self.timeLabel.text = "\(self.timeBetweenScans().tb) min"
                self.driveTimeLabel.text = "\(self.timeBetweenScans().dt) hrs"
                switch self.driverId {
                case 6,7:
                    if self.fromHours == true {
                        self.negativeHours.text = "\(1) hrs"
                    } else {
                        self.negativeHours.text = "\(0) hrs"
                    }
                case 9:
                    self.negativeHours.text = "\(4) hrs"
                case 10:
                    self.negativeHours.text = "\(3) hrs"
                case 17:
                    self.negativeHours.text = "\(4) hrs"
                default:
                    self.negativeHours.text = "\(0) hrs"
                }
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.loopsLabel.alpha = 1.0
                    self.timeFromScanLabel.alpha = 1.0
                    self.timeLabel.alpha = 1.0
                    self.driveTimeLabel.alpha = 1.0
                    self.negativeHours.alpha = 1.0
                })
                
                //self.tableView.reloadData()
                //self.filterArray()
            }
        })
    }
    
    func driverTest() {
        APIManager.shared.getDriverInfo(eventId: shift.eventId, shiftId: shift.id, driverId: driverId, completion: { (driver) in
            
            self.scans.removeAll()
            for scan in driver.scans {
                self.scans.append(scan)
            }
            self.cell = driver.cell!
            self.driver = driver
            
            DispatchQueue.main.async {
                
                self.title = driver.name
                self.mapView.removeAnnotation(self.dropPin)
                self.filterArray()
                
                if driver.lastLocation?.driver_id != 0 {
                    self.center = CLLocationCoordinate2D(latitude: Double((driver.lastLocation?.latitude)!), longitude: Double((driver.lastLocation?.longitude)!))
                    self.region = MKCoordinateRegion(center: self.center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
                    self.mapView.setRegion(self.region, animated: true)
                    self.addPin(location: driver.lastLocation!)
                    
                } else if self.scans.count > 0 {
                    self.center = CLLocationCoordinate2D(latitude: Double((self.scans.last?.latitude)!), longitude: Double((self.scans.last?.longitude)!))
                    self.region = MKCoordinateRegion(center: self.center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
                    
                    let pinCoord = CLLocationCoordinate2DMake(CLLocationDegrees((self.scans.last?.latitude)!), CLLocationDegrees((self.scans.last?.longitude)!))
                    let dropPin = MKPointAnnotation()
                    
                    dropPin.coordinate = pinCoord
                    
                    self.mapView.setRegion(self.region, animated: true)
                    self.mapView.addAnnotation(dropPin)
                }
                
                self.loopsLabel.text = "\(self.scanCount())"
                self.timeFromScanLabel.text = "\(self.timeBetweenScans().tn) min"
                self.timeLabel.text = "\(self.timeBetweenScans().tb) min"
                self.driveTimeLabel.text = "\(self.timeBetweenScans().dt) hrs"
                switch self.driverId {
                case 6,7:
                    if self.fromHours == true {
                        self.negativeHours.text = "\(1) hrs"
                    } else {
                        self.negativeHours.text = "\(0) hrs"
                    }
                case 9:
                    self.negativeHours.text = "\(4) hrs"
                case 10:
                    self.negativeHours.text = "\(3) hrs"
                case 17:
                    self.negativeHours.text = "\(4) hrs"
                default:
                    self.negativeHours.text = "\(0) hrs"
                }
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.loopsLabel.alpha = 1.0
                    self.timeFromScanLabel.alpha = 1.0
                    self.timeLabel.alpha = 1.0
                    self.driveTimeLabel.alpha = 1.0
                    self.negativeHours.alpha = 1.0
                })
                
                //self.filterArray()
                //self.tableView.reloadData()
            }
        })

    }
    
    @IBAction func moreAction(_ sender: Any) {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
        }
    }
    
    @IBAction func dismissDriverDetail(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func textMessages() {
        let layout = UICollectionViewFlowLayout()
        let controller = MessageCollectionViewController(collectionViewLayout: layout)
        present(controller, animated: true, completion: nil)
    }
    
    func callDriver() {
        if driver.cell != nil {
            UIApplication.shared.open(URL(string: "telprompt://1\(String(describing: driver.cell!))")!, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func unwindToDetail(_ sender: UIStoryboardSegue) {}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "messageSegue" {
            let dvc = segue.destination as! MessageCollectionViewController
            dvc.driver = driver
        } else if segue.identifier == "manualScanSegue" {
            let dvc = segue.destination as! ManualScanViewController
            dvc.driver = driver
            dvc.shift = shift
            dvc.driverId = driverId
        }
    }
}

extension DriverDetailViewController: MKMapViewDelegate {
    
    func addPin(location: RealmLocation) {
       
        let pinCoord = CLLocationCoordinate2DMake(CLLocationDegrees(location.latitude), CLLocationDegrees(location.longitude))
        //let dropPin = MKPointAnnotation()
            
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

extension DriverDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scanCell", for: indexPath) as! ScanTableViewCell
        let scan = scans[indexPath.row]
        cell.scan = scan
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
