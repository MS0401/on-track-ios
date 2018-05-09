//
//  EmployeeHomeViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 11/11/16.
//  Copyright © 2016 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift
import MapKit
import MessageUI
import ACProgressHUD_Swift
import BTNavigationDropdownMenu
import SwiftyJSON
import Mapbox
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections

private typealias RouteRequestSuccess = (([Route]) -> Void)
private typealias RouteRequestFailure = ((NSError) -> Void)

class EmployeeHomeViewController: UIViewController, SettingsViewDelegate, CLLocationManagerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var navbarView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var outputLabel: UILabel!
    @IBOutlet weak var pickupView: UIView!
    @IBOutlet weak var travelTimeLabel: UILabel!
    @IBOutlet weak var emergencyButton: UIButton!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var cicleImage: UIImageView!
    @IBOutlet weak var trafficButton: UIButton!
    
    var lat = Float()
    var long = Float()
    var course = Float()
    var speed = Float()
    var realm = try! Realm()
    //var timer2: Timer?
    //var timer3: Timer?
    var sourceLocation: Location?
    var destinationLocation: Location?
    var loadArrival = 0
    var dropArrival = 0
    var batteryLevel: Float?
    var count: Int = 0
    var tbHeight: Int = 0
    var viewItems = [String]()
    var imageName = [String]()
    var menuView: BTNavigationDropdownMenu!
    let items = ["Inbound 4pm - 2am", "Inbound 2am - 8am", "Outbound"]
    var inboundLine = MKPolyline()
    var zones = [Zone]()
    var route: RealmRoute!
   
    //MARK: Mapbox property
    var waypoints: [Waypoint] = []
    var waypoints1: [Waypoint] = []
    var TempWaypoints: [Waypoint] = []
    var routesCoordinates: [CLLocationCoordinate2D] = []
    var locationManager = CLLocationManager()
    var navigationViewController : NavigationViewController?
    var navigation : RouteController?
    var currentRoute: Route?
    var routes: [Route]?
    var reroute = false
    var navIndex = 0
    var initialArrived = true
    var lastArrived = false
    
    var drivingQueue: [DriverQueueItem] = []
    var destinationAnnotation = MGLPointAnnotation()
    var currentDrive: DriverQueueItem?
    var nextDrive: DriverQueueItem?
    
    enum DriverAction: String {
        case begin
        case waiting
        case pickUp
        case dropOff
        case finish
    }
    
    struct DriverQueueItem {
        var action: DriverAction
        var passengerName: String
        var atLocation: Waypoint
    }
    
    // MARK: Directions Request Handlers
    fileprivate lazy var defaultSuccess: RouteRequestSuccess = { [weak self] (routes) in
        guard let current = routes.first else { return }
        self?.routes = routes
        self?.currentRoute = current
        //        self?.waypoints = current.routeOptions.waypoints
    }
    
    fileprivate lazy var defaultFailure: RouteRequestFailure = { [weak self] (error) in
        self?.routes = nil //clear routes from the map
        print(error.localizedDescription)
    }
  
    
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        return st
    }()
    
    //MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.inboundLine = setupInbound()
        
        pickupView.layer.shadowColor = UIColor.darkGray.cgColor
        pickupView.layer.shadowOpacity = 1
        pickupView.layer.shadowOffset = CGSize.zero
        pickupView.layer.shadowRadius = 10
        pickupView.layer.shouldRasterize = true
        pickupView.layer.cornerRadius = 10
        pickupView.clipsToBounds = true
        
        emergencyButton.layer.cornerRadius = 10
        emergencyButton.layer.borderWidth = 1
        emergencyButton.layer.borderColor = UIColor(red: 255/255, green: 38/255, blue: 53/255, alpha: 1.0).cgColor
        emergencyButton.clipsToBounds = true
        
        trafficButton.layer.cornerRadius = 10
        trafficButton.layer.borderWidth = 1
        trafficButton.layer.borderColor = UIColor(red: 84/255, green: 190/255, blue: 255/255, alpha: 1.0).cgColor
        trafficButton.clipsToBounds = true
        
        mapView.showsTraffic = true
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        mapView.delegate = self
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        automaticallyAdjustsScrollViewInsets = false
        mapView.userTrackingMode = .follow
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = abs(UIDevice.current.batteryLevel)
        

        if let route = realm.objects(RealmRoute.self).first {
            self.route = route
        }
                
        for location in route.zones {
            let annotation = MKPointAnnotation()
            let point = CLLocationCoordinate2DMake(CLLocationDegrees(location.latitude), CLLocationDegrees(location.longitude))
            annotation.coordinate = point
            annotation.title = location.name
            mapView.addAnnotation(annotation)
        }
        
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.mapView.add(self.inboundLine)
        mapView.fitAllAnnotations()

        settingsViewInboundOne()
//        getPolyPoints()
//        getDirections()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
    }
    
    func requestReroute(waypoints: [Waypoint], results: @escaping ((_ success: Bool) -> Void)) {
        
        let options = NavigationRouteOptions(waypoints: waypoints)
        options.routeShapeResolution = .full
        options.includesSteps = true
        
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
            self.currentRoute = routes?.first
            results(true)
        }
        
    }
    
    fileprivate func requestRoute(with options: RouteOptions, success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {
        
        let handler: Directions.CompletionHandler = {(waypoints, potentialRoutes, potentialError) in
            if let error = potentialError, let fail = failure { return fail(error) }
            guard let routes = potentialRoutes else { return }
            return success(routes)
        }
        
        _ = Directions.shared.calculate(options, completionHandler: handler)
    }
    
    func setupInbound() -> MKPolyline {
        var points = [CLLocationCoordinate2D]()
        
        let craigs = CLLocationCoordinate2DMake(36.239501953125, -115.151954650879)
        points.append(craigs)
        let waypoint1 = Waypoint(coordinate: craigs)
        waypoint1.coordinateAccuracy = -1
        waypoints1.append(waypoint1)
        
        let craigsBend = CLLocationCoordinate2DMake(36.239987, -115.113376)
        points.append(craigsBend)
        let waypoint2 = Waypoint(coordinate: craigsBend)
        waypoint2.coordinateAccuracy = -1
        waypoints1.append(waypoint2)
        
        let lasVegasBlvdLeft = CLLocationCoordinate2DMake(36.240664, -115.054240)
        points.append(lasVegasBlvdLeft)
        let waypoint3 = Waypoint(coordinate: lasVegasBlvdLeft)
        waypoint3.coordinateAccuracy = -1
        waypoints1.append(waypoint3)
        
        let hollywoodLeft = CLLocationCoordinate2DMake(36.257995, -115.024854)
        points.append(hollywoodLeft)
        let waypoint4 = Waypoint(coordinate: hollywoodLeft)
        waypoint4.coordinateAccuracy = -1
        waypoints1.append(waypoint4)
        
        let tropicalRight = CLLocationCoordinate2DMake(36.268929, -115.025053)
        points.append(tropicalRight)
        let waypoint5 = Waypoint(coordinate: tropicalRight)
        waypoint5.coordinateAccuracy = -1
        waypoints1.append(waypoint5)
        
        let line = MKPolyline(coordinates: points, count: 5)
        self.routesCoordinates = points
        
        return line
    }
   
    func setupCochellaInbound() -> MKPolyline {
        print("inbound-----------")
        var points = [CLLocationCoordinate2D]()
        
        let start = CLLocationCoordinate2DMake(33.723693, -116.331708)
        points.append(start)
        let start1 = CLLocationCoordinate2DMake(33.723594, -116.330183)
        points.append(start1)
        let start2 = CLLocationCoordinate2DMake(33.723148, -116.329915)
        points.append(start2)
        let start3 = CLLocationCoordinate2DMake(33.721489, -116.330162)
        points.append(start3)
        let start4 = CLLocationCoordinate2DMake(33.721578, -116.324604)
        points.append(start4)
        let start5 = CLLocationCoordinate2DMake(33.720685, -116.314332)
        points.append(start5)
        let start6 = CLLocationCoordinate2DMake(33.716853, -116.304055)
        points.append(start6)
        let start7 = CLLocationCoordinate2DMake(33.715412, -116.295622)
        points.append(start7)
        let start07 = CLLocationCoordinate2DMake(33.715099, -116.294873)
        points.append(start07)
        let start08 = CLLocationCoordinate2DMake(33.711036, -116.290432)
        points.append(start08)
        let start02 = CLLocationCoordinate2DMake(33.708329, -116.286534)
        points.append(start02)
        let start09 = CLLocationCoordinate2DMake(33.707712, -116.282943)
        points.append(start09)
        let start01 = CLLocationCoordinate2DMake(33.707360, -116.279798)
        points.append(start01)
        let start8 = CLLocationCoordinate2DMake(33.707326, -116.268960)
        points.append(start8)
        let start9 = CLLocationCoordinate2DMake(33.699732, -116.268878)
        points.append(start9)
        let start10 = CLLocationCoordinate2DMake(33.699989, -116.246865)
        points.append(start10)
        let start11 = CLLocationCoordinate2DMake(33.685345, -116.246924)
        points.append(start11)
        let end = CLLocationCoordinate2DMake(33.685362, -116.241948)
        points.append(end)
        
        let line = MKPolyline(coordinates: points, count: points.count)
        
        return line
    }
    
    func settingsViewInboundOne() {
        viewItems.removeAll()
        imageName.removeAll()
        
        viewItems.append("Turn left onto Craig Road")
        imageName.append("blue_left")
        viewItems.append("Forward on Craig Road")
        imageName.append("blue_up")
        viewItems.append("Turn left onto Las Vegas Blvd")
        imageName.append("blue_left")
        viewItems.append("Forward on Las Vegas Blvd")
        imageName.append("blue_up")
        viewItems.append("Turn left onto Hollywood Blvd")
        imageName.append("blue_left")
        viewItems.append("Forward on Hollywood Blvd")
        imageName.append("blue_up")
        viewItems.append("Turn right into Gate 16")
        imageName.append("blue_right")

        //viewItems.append("Cancel")
        //imageName.append("blue_close")
        
        settingsView.items = viewItems
        settingsView.imageNames = imageName
        
        count = viewItems.count
        tbHeight = 48 * count
        
        let originalFrame = settingsView.tableView.frame
        let newHeight = count * tbHeight
        settingsView.tableView.frame = CGRect(x: originalFrame.origin.x, y: originalFrame.origin.y, width: originalFrame.size.width, height:CGFloat(Int(newHeight)))
        settingsView.tableView.reloadData()
    }
    
    func setupLine(points: [CLLocationCoordinate2D]) -> MKPolyline {
        let line = MKPolyline(coordinates: points, count: points.count)
        return line
    }
    
    func getPolyPoints() {
        
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event!.eventId)/routes/\(route.id)/polynomial_points"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonPoints = json["polynomial_points"].arrayValue
                var points = [CLLocationCoordinate2D]()
                
                for point in jsonPoints {
                    let p = CLLocationCoordinate2DMake(CLLocationDegrees(point["latitude"].floatValue), CLLocationDegrees(point["longitude"].floatValue))
                    points.append(p)
                }
                
                DispatchQueue.main.async {
                    self.inboundLine = self.setupLine(points: points)
                    self.mapView.add(self.inboundLine)
                }
                
            case .failure:
                break
            }
        }
    }
    
    func getDirections() {
        
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event!.eventId)/routes/\(route.id)/directions"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonDirections = json["directions"].arrayValue
                var directions = [[String: Any]]()
                
                for direction in jsonDirections {
                    var dict = [String: Any]()
                    dict["direction"] = direction["direction"].stringValue
                    dict["note"] = direction["note"].stringValue
                    directions.append(dict)
                }
                
                DispatchQueue.main.async {
                    self.setupSettingsView(dict: directions)
                }
                
            case .failure:
                break
            }
        }
    }
    
    func setupSettingsView(dict: [[String: Any]]) {
        
        count = dict.count
        tbHeight = 48 * count
        
        let originalFrame = settingsView.tableView.frame
        let newHeight = count * tbHeight
        settingsView.tableView.frame = CGRect(x: originalFrame.origin.x, y: originalFrame.origin.y, width: originalFrame.size.width, height:CGFloat(Int(newHeight)))
        
        for item in dict {
            let image = item["direction"] as! String
            let note = item["note"] as! String
            
            switch image {
            case "U":
                settingsView.imageNames.append("blue_up")
            case "R":
                settingsView.imageNames.append("blue_right")
            case "L":
                settingsView.imageNames.append("blue_left")
            default:
                settingsView.imageNames.append("blue_up")
            }
            
            settingsView.items.append(note)
        }
    }

    @IBAction func handleSettings(_ sender: Any) {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
        }
    }
    
    @IBAction func dismissVC(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func unwindHome(_ sender: UIStoryboardSegue) {}
    
    func openSMS() {
        if MFMessageComposeViewController.canSendText() {
            let controller = MFMessageComposeViewController()
            controller.recipients = ["14152002585"]
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func sendEmergencyInfo(_ sender: UIButton) {
        emergency()
    }
    
    @IBAction func reportTraffic(_ sender: UIButton) {
        traffic()
    }
    
    func traffic() {
        let progressView = ACProgressHUD.shared
        progressView.progressText = "Sending Traffic Update..."
        
        let alert = UIAlertController(title: "Report Traffic", message: "What type of traffic update are you reporting?", preferredStyle: UIAlertControllerStyle.alert)
        
        let trafficSlow = UIAlertAction(title: "Traffic Slow", style: .default) { (alert) in
            self.postNotificationVC(progressView: progressView, reason: 10)
        }
        
        let trafficUnder = UIAlertAction(title: "Traffic under 10mph", style: .default) { (alert) in
            self.postNotificationVC(progressView: progressView, reason: 11)
        }
        
        let trafficMove = UIAlertAction(title: "Traffic not Moving", style: .default) { (alert) in
            self.postNotificationVC(progressView: progressView, reason: 12)
//            self.performSegue(withIdentifier: "route", sender: self)
        }
        
        let roadClosed = UIAlertAction(title: "Road Closed", style: .default) { (alert) in
            self.postNotificationVC(progressView: progressView, reason: 13)
//            self.performSegue(withIdentifier: "navigate", sender: self)
            
        }
        
        let mapNavigation = UIAlertAction(title: "Map Navigation", style: .default) { (alert) in
            
            self.startBasicNavigation()
            
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
            
        }
        
        alert.addAction(trafficSlow)
        alert.addAction(trafficUnder)
        alert.addAction(trafficMove)
        alert.addAction(roadClosed)
        alert.addAction(mapNavigation)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "navigate" {
            let navigate = segue.destination as! NavigationMapViewController
            var coordinates = self.routesCoordinates
            coordinates.removeFirst()
            navigate.waypoints = coordinates
            navigate.initialCoordinate = self.routesCoordinates.first!
            
        }else if segue.identifier == "route" {
            let route = segue.destination as! TDRouteViewController
        }
    }
    
    func emergency() {
        let progressView = ACProgressHUD.shared
        progressView.progressText = "Sending Emergency..."
        
        let alert = UIAlertController(title: "Emergency Type", message: "What kind of emergency", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Medical", style: .default, handler: { (action) in
            self.postScan(progressView: progressView, reason: 16, comment: "comment", driverId: (currentUser?.id)!, lat: self.lat, long: self.long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, scannerId: (currentUser?.id)!, scanType: "staff")
        })
        let alertActionTwo = UIAlertAction(title: "Fire", style: .default, handler: { (action) in
            self.postScan(progressView: progressView, reason: 16, comment: "comment", driverId: (currentUser?.id)!, lat: self.lat, long: self.long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, scannerId: (currentUser?.id)!, scanType: "staff")
        })
        let alertActionThree = UIAlertAction(title: "Police", style: .default, handler: { (action) in
            self.postScan(progressView: progressView, reason: 16, comment: "comment", driverId: (currentUser?.id)!, lat: self.lat, long: self.long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, scannerId: (currentUser?.id)!, scanType: "staff")
        })
        let alertActionFour = UIAlertAction(title: "Bus Accident", style: .default, handler: { (action) in
            self.postScan(progressView: progressView, reason: 16, comment: "comment", driverId: (currentUser?.id)!, lat: self.lat, long: self.long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, scannerId: (currentUser?.id)!, scanType: "staff")
        })
        
        let alertActionSix = UIAlertAction(title: "Broken Down", style: .default, handler: { (action) in
            self.postScan(progressView: progressView, reason: 16, comment: "comment", driverId: (currentUser?.id)!, lat: self.lat, long: self.long, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, scannerId: (currentUser?.id)!, scanType: "staff")
        })
        let alertActionFive = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            
        })
        alert.addAction(alertAction)
        alert.addAction(alertActionTwo)
        alert.addAction(alertActionThree)
        alert.addAction(alertActionFour)
        alert.addAction(alertActionSix)
        alert.addAction(alertActionFive)
        present(alert, animated: true, completion: nil)
    }
    
    func postScan(progressView: ACProgressHUD, reason: Int, comment: String, driverId: Int,
                  lat: Float, long: Float, eventId: Int, routeId: Int, scannerId: Int, scanType: String) {
        
        progressView.showHUD()
        
        APIManager.shared.postDriverScan(driverId, comment: comment, reason: reason, lat: lat, long: long, eventId: eventId, routeId: routeId, passengerCount: nil, scannerId: scannerId, scanType: scanType, ingress: nil, shiftId: nil) { (error) in
            
            if error != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                    progressView.hideHUD()
                    self.errorAlert(title: "Emergency Alert", subtitle: "Emergency alert was not received, Please try again")
                })
                
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                    progressView.hideHUD()
                    self.completionAlert(title: "Emergency Alert", subtitle: "Emergency Alert Received, please follow your companies emergency proceedures")
                })
            }
        }
    }
    
    func postNotificationVC(progressView: ACProgressHUD, reason: Int) {
        APIManager.shared.postNotification(reason: reason, latitude: (currentUser?.lastLocation?.latitude)!, longitude: (currentUser?.lastLocation?.longitude)!, driver_id: (currentUser?.id)!, phone_number: (currentUser?.cell!)!, event_id: (currentUser?.event_id)!, changeRouteId: nil) { (error) in
            
            progressView.showHUD()
            
            if error != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                    progressView.hideHUD()
                    self.errorAlert(title: "Traffic Reported", subtitle: "Your traffic report was not received please try again")
                })
                
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                    progressView.hideHUD()
                    self.completionAlert(title: "Traffic Reported", subtitle: "Traffic report received, thank you")
                })
            }
        }
    }
    
    func completionAlert(title: String, subtitle: String) {
        _ = SweetAlert().showAlert(title, subTitle: subtitle, style: AlertStyle.success, buttonTitle:  "OK", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
        }
    }
    
    func errorAlert(title: String, subtitle: String) {
        _ = SweetAlert().showAlert(title, subTitle: subtitle, style: AlertStyle.error, buttonTitle:  "Try Again", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
        }
    }
    
    /*
    @IBAction func openMapApp(_ sender: UIButton) {
        let newLocation = CLLocation(latitude: Double((destinationLocation?.latitude)!), longitude: Double((destinationLocation?.longitude)!))
        
        CLGeocoder().reverseGeocodeLocation(newLocation, completionHandler: {(placemarks, error) in
            let placemark = placemarks?[0]
            let coordinate = CLLocationCoordinate2DMake(Double((self.destinationLocation?.latitude)!), Double((self.destinationLocation?.longitude)!))
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: placemark?.addressDictionary as! [String : Any]?))
            mapItem.name = placemark?.addressDictionary?["Name"] as! String?
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsShowsTrafficKey: true] as [String : Any])
        })
    }
    
    func updateHeader(_ destination: Location, name: String, imageName: String) {
        destinationLocation = destination
        destinationLabel.text = name
        cicleImage.image = UIImage(named: imageName)
        pickupLocations(destination)
    }
    */
    
    func didSelectRow(indexPath: Int) {
        if indexPath < count - 2 {
            let zones = currentUser?.route?.zones
            let zone = zones?[indexPath]
            
            //let l = Location(driver_id: (currentUser?.id)!, latitude: (zone?.latitude)!, longitude: (zone?.longitude)!)
            //updateHeader(l, name: "\((currentUser?.route?.name)!) \((zone?.name)!)", imageName: "blue_circle")
        }
        
        if indexPath == (count - 2) {
            openSMS()
        }
    }
    
    func hideSettingsView(status: Bool) {
        if status == true {
            settingsView.removeFromSuperview()
        }
    }
    
    // MARK: Basic Navigation
    func startBasicNavigation() {
        
        let alert = UIAlertController(title: "Report Navigation", message: "What point are you going to go?", preferredStyle: UIAlertControllerStyle.alert)
        
        let Apoint = UIAlertAction(title: "A point", style: .default) { (alert) in
            
            self.TempWaypoints = self.waypoints1
            
            self.Navigation()
        }
        
        let Bpoint = UIAlertAction(title: "B point", style: .default) { (alert) in
            
            for coordinate in self.waypoints1.reversed() {
                self.TempWaypoints.append(coordinate)
                print(coordinate.coordinate)
            }
            self.Navigation()
        }
        
        alert.addAction(Apoint)
        alert.addAction(Bpoint)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func Navigation() {
        self.waypoints.removeAll()
        let userWaypoint = Waypoint(location: mapView.userLocation.location!, heading: mapView.userLocation.heading, name: "user")
        self.waypoints.append(userWaypoint)
        self.waypoints.append(TempWaypoints[self.navIndex])
        self.requestReroute(waypoints: self.waypoints, results: {(success) -> Void in
            
            if success {
                
                guard let route = self.currentRoute else { return }
                self.navigationViewController = NavigationViewController(for: route, locationManager: self.navigationLocationManager())
                self.navigationViewController?.delegate = self
                SharingManager.sharedInstance.index = SharingManager.sharedInstance.index + 1
                print("---------")
                print("Current index \(self.navIndex)")
                print("---------")
                
                self.navIndex = self.navIndex + 1
                self.present(self.navigationViewController!, animated: true, completion: nil)
            }
        })
    }
    
    func navigationLocationManager() -> NavigationLocationManager {
        guard let route = currentRoute else { return NavigationLocationManager() }
        print("~~~~~~~~~~~")
        print(route.coordinates?.count ?? "0")
        print(route.coordinates ?? "nil")
        return NavigationLocationManager()//  SimulatedLocationManager(route: route)
    }
}

extension EmployeeHomeViewController: NavigationMapViewDelegate {
    // To use these delegate methods, set the `VoiceControllerDelegate` on your `VoiceController`.
    //
    // Called when there is an error with speaking a voice instruction.
    func voiceController(_ voiceController: RouteVoiceController, spokenInstructionsDidFailWith error: Error) {
        print(error.localizedDescription)
    }
    // Called when an instruction is interrupted by a new voice instruction.
    func voiceController(_ voiceController: RouteVoiceController, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction) {
        print(interruptedInstruction.text, interruptingInstruction.text)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        
        let line = MGLLineStyleLayer(identifier: identifier, source: source)
        line.lineColor = MGLStyleValue(rawValue: UIColor(red: 0.28, green: 0.49, blue: 0.78, alpha: 1.0))
        line.lineWidth = MGLStyleValue(rawValue: 10)
        line.lineBlur = MGLStyleValue(rawValue: 5)
        line.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        line.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        return line
    }
    
    func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        
        let lineCasing = MGLLineStyleLayer(identifier: identifier, source: source)
        lineCasing.lineColor = MGLStyleValue(rawValue: UIColor(red: 0.18, green: 0.49, blue: 0.78, alpha: 1.0))
        lineCasing.lineWidth = MGLStyleValue(rawValue: 6)
        lineCasing.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        lineCasing.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        return lineCasing
    }
}

extension EmployeeHomeViewController: NavigationViewControllerDelegate {
    
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldIncrementLegWhenArrivingAtWaypoint waypoint: Waypoint) -> Bool {
        return false
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) {
        
        print("Did arrived successfully.")
        
        let alert = UIAlertController(title: "Traffic Report", message: "You have just arrived at point A successfully", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
            self.navIndex = 0
            self.initialArrived = true
            self.lastArrived = false
            navigationViewController.dismiss(animated: true, completion: nil)
            
            self.performSegue(withIdentifier: "navigate", sender: self)
        })
        alert.addAction(alertAction)
        navigationViewController.present(alert, animated: true, completion: nil)
    }
    
    func navigationViewControllerDidCancelNavigation(_ navigationViewController: NavigationViewController) {
        self.navIndex = 0
        self.initialArrived = true
        self.lastArrived = false
        navigationViewController.dismiss(animated: true, completion: nil)
    }
}

extension EmployeeHomeViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let coordinate = CLLocationCoordinate2DMake(38.5816, -121.4944)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polygonView = MKPolylineRenderer(overlay: overlay)
            polygonView.strokeColor = UIColor(red: 77/255, green: 215/255, blue: 250/255, alpha: 1.0)
            return polygonView
        }
        return MKOverlayRenderer()
    }
}

extension EmployeeHomeViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
    }
}
