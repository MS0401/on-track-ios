//
//  RouteInfoViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/30/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import BTNavigationDropdownMenu
import Alamofire
import SwiftyJSON

class RouteInfoViewController: UIViewController, MKMapViewDelegate, SettingsViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var routeName: UILabel!
    
    var route: RealmRoute!
    var center: CLLocationCoordinate2D!
    var region: MKCoordinateRegion!
    var zones = [Zone]()
    var menuView: BTNavigationDropdownMenu!
    let items = ["Inbound 4pm - 2am", "Inbound 2am - 8am", "Outbound"]
    var inboundLine = MKPolyline()
    var line = MKPolyline()
    var outboundLine = MKPolyline()
    internal var count: Int = 0
    internal var tbHeight: Int = 0
    var viewItems = [String]()
    var imageName = [String]()
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        return st
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //inboundLine = setupCochellaInbound()
        
        //inboundLine = setupCochellaInbound()
        /*
        if currentUser?.event?.name == "EDC 2017" {
            inboundLine = setupInbound()
            line = setupInbound2()
            outboundLine = setupOutbound()
            
            menuView = BTNavigationDropdownMenu(title: items[0], items: items as [AnyObject])
            
            navigationItem.titleView = menuView
            
            menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
                switch indexPath {
                case 0:
                    self.mapView.remove(self.line)
                    self.mapView.remove(self.outboundLine)
                    self.mapView.add(self.inboundLine)
                case 1:
                    self.mapView.remove(self.inboundLine)
                    self.mapView.remove(self.outboundLine)
                    self.mapView.add(self.line)
                case 2:
                    self.mapView.remove(self.inboundLine)
                    self.mapView.remove(self.line)
                    self.mapView.add(self.outboundLine)
                default:
                    self.mapView.remove(self.inboundLine)
                    self.mapView.remove(self.outboundLine)
                    self.mapView.add(self.inboundLine)
                }
            }
        } else {
            title = route.name
            inboundLine = setupCochellaInbound()
        }
        */
        
        title = route.name
        
        var circles = [MKOverlay]()
        for location in route.zones {
            let annotation = MKPointAnnotation()
            let point = CLLocationCoordinate2DMake(CLLocationDegrees(location.latitude), CLLocationDegrees(location.longitude))
            let regionRadius = 200.0
            let circle = MKCircle(center: point, radius: regionRadius)
            
            annotation.coordinate = point
            annotation.title = location.name
            
            mapView.addAnnotation(annotation)
            circles.append(circle)
        }

        mapView.fitAllAnnotations()
        mapView.addOverlays(circles)
        
        //getPolyPoints()
        //getDirections()
        
        
        
        settingsViewInboundOne()
        
        inboundLine = setupInbound()
        line = setupInbound2()
        outboundLine = setupOutbound()
        
        self.mapView.add(inboundLine)
        
        if route.id == 2 {
        
        menuView = BTNavigationDropdownMenu(title: items[0], items: items as [AnyObject])
        
        navigationItem.titleView = menuView
        
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
            switch indexPath {
            case 0:
                self.mapView.remove(self.line)
                self.mapView.remove(self.outboundLine)
                self.mapView.add(self.inboundLine)
            case 1:
                self.mapView.remove(self.inboundLine)
                self.mapView.remove(self.outboundLine)
                self.mapView.add(self.line)
            case 2:
                self.mapView.remove(self.inboundLine)
                self.mapView.remove(self.line)
                self.mapView.add(self.outboundLine)
            default:
                self.mapView.remove(self.inboundLine)
                self.mapView.remove(self.outboundLine)
                self.mapView.add(self.inboundLine)
            }
        }
    }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @IBAction func dismissRouteInfo(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    /*
    func setupInbound() -> MKPolyline {
        var points = [CLLocationCoordinate2D]()
        
        let craigs = CLLocationCoordinate2DMake(36.239501953125, -115.151954650879)
        points.append(craigs)
        
        let craigsBend = CLLocationCoordinate2DMake(36.239987, -115.113376)
        points.append(craigsBend)
        
        let lasVegasBlvdLeft = CLLocationCoordinate2DMake(36.240664, -115.054240)
        points.append(lasVegasBlvdLeft)
        
        let hollywoodLeft = CLLocationCoordinate2DMake(36.257995, -115.024854)
        points.append(hollywoodLeft)
        
        let tropicalRight = CLLocationCoordinate2DMake(36.268929, -115.025053)
        points.append(tropicalRight)
        
        let line = MKPolyline(coordinates: points, count: 5)
        
        return line
    }
    */
    
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
    
    func setupInbound() -> MKPolyline {
        var points = [CLLocationCoordinate2D]()
        
        let craigs = CLLocationCoordinate2DMake(36.239501953125, -115.151954650879)
        points.append(craigs)
        
        let craigsBend = CLLocationCoordinate2DMake(36.239987, -115.113376)
        points.append(craigsBend)
        
        let lasVegasBlvdLeft = CLLocationCoordinate2DMake(36.240664, -115.054240)
        points.append(lasVegasBlvdLeft)
        
        let hollywoodLeft = CLLocationCoordinate2DMake(36.257995, -115.024854)
        points.append(hollywoodLeft)
        
        let tropicalRight = CLLocationCoordinate2DMake(36.268929, -115.025053)
        points.append(tropicalRight)
        
        let line = MKPolyline(coordinates: points, count: 5)
        
        return line
    }
    
    func setupInbound2() -> MKPolyline {
        var points = [CLLocationCoordinate2D]()
        
        let craigs = CLLocationCoordinate2DMake(36.239501953125, -115.151954650879)
        points.append(craigs)
        
        let freeway = CLLocationCoordinate2DMake(36.240380, -115.101442)
        points.append(freeway)
        
        let freeway2 = CLLocationCoordinate2DMake(36.266148, -115.069386)
        points.append(freeway2)
        
        let speedwayBlvd = CLLocationCoordinate2DMake(36.282674, -115.025670)
        points.append(speedwayBlvd)
        
        let hollywood = CLLocationCoordinate2DMake(36.281122, -115.023971)
        points.append(hollywood)
        
        let hollywoodBend = CLLocationCoordinate2DMake(36.279866, -115.024962)
        points.append(hollywoodBend)
        
        let centenialRight = CLLocationCoordinate2DMake(36.276326, -115.025162)
        points.append(centenialRight)
        
        let shatzLeft = CLLocationCoordinate2DMake(36.276355, -115.029665)
        points.append(shatzLeft)
        
        let tropicalLeft = CLLocationCoordinate2DMake(36.269195, -115.029582)
        points.append(tropicalLeft)
        
        let loadZone = CLLocationCoordinate2DMake(36.268916, -115.024194)
        points.append(loadZone)
        
        let line = MKPolyline(coordinates: points, count: 10)
        
        return line
    }
    
    func setupOutbound() -> MKPolyline {
        var points = [CLLocationCoordinate2D]()
        
        let greenOut = CLLocationCoordinate2DMake(36.259250, -115.022596)
        points.append(greenOut)
        
        let lasVegasBlvdLeft = CLLocationCoordinate2DMake(36.240664, -115.054240)
        points.append(lasVegasBlvdLeft)
        
        let craigsBend = CLLocationCoordinate2DMake(36.239987, -115.113376)
        points.append(craigsBend)
        
        let craigs = CLLocationCoordinate2DMake(36.239501953125, -115.151954650879)
        points.append(craigs)
        
        let line = MKPolyline(coordinates: points, count: 4)
        
        return line
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
                
                //print(directions)
                
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

        //settingsView.items = viewItems
        //settingsView.imageNames = imageName
    }
    
    func hideSettingsView(status: Bool) {
        if status == true {
            settingsView.removeFromSuperview()
        }
    }
    
    func didSelectRow(indexPath: Int) {}

    @IBAction func directionsButtonPressed(_ sender: Any) {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "myAnnotation") as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myAnnotation")
        } else {
            annotationView?.annotation = annotation
        }
        
        if let annotation = annotation as? Pin {
            annotationView?.pinTintColor = annotation.pinTintColor
        } else {
            annotationView?.pinTintColor = UIColor.red
        }
        
        annotationView?.canShowCallout = true
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
            circleRenderer.strokeColor = UIColor.blue
            circleRenderer.lineWidth = 1
            return circleRenderer
        } else if overlay is MKPolyline {
            let polygonView = MKPolylineRenderer(overlay: overlay)//MKPolygonRenderer(overlay: overlay)
            polygonView.strokeColor = UIColor(red: 77/255, green: 215/255, blue: 250/255, alpha: 1.0)
            return polygonView
        }
        return MKOverlayRenderer()
    }
}
