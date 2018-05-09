//
//  DriverMapViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/25/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
//import MapboxCoreNavigation
//import MapboxDirections
//import MapboxNavigation
//import Mapbox

//mapRouteSegue
/*
class DriverMapViewController: UIViewController, MGLMapViewDelegate, NavigationViewControllerDelegate,
                                NavigationMapViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var zones = [Zone]()
    //var route: Route!
    //var destination1: MGLPointAnnotation?
    //var navigationViewController: NavigationViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        zones.removeAll()
        for zone in (currentUser?.route?.zones)! {
            zones.append(zone)
        }
        
        tableView.reloadData()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    func startNavigation(along route: Route, simulatesLocationUpdates: Bool = false) {
        let navigationViewController = NavigationViewController(for: route)
        navigationViewController.simulatesLocationUpdates = simulatesLocationUpdates
        navigationViewController.routeController.snapsUserLocationAnnotationToRoute = true
        navigationViewController.voiceController?.volume = 0.5
        navigationViewController.navigationDelegate = self

        present(navigationViewController, animated: true, completion: nil)
    }
    
    func getRoute(zone: Zone, didFinish: (()->())? = nil) {
        let origin = Waypoint(coordinate: CLLocationCoordinate2D(latitude: Double((currentUser?.lastLocation?.latitude)!), longitude: Double((currentUser?.lastLocation?.longitude)!)), name: "Currnet Location")
        let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(zone.latitude), longitude: CLLocationDegrees(zone.longitude)), name: zone.name)
        
        let options = RouteOptions(waypoints: [origin, destination])
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.profileIdentifier = .automobileAvoidingTraffic
        
        _ = Directions.shared.calculate(options) { [weak self] (waypoints, routes, error) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let route = routes?.first else {
                return
            }
            
            let navigationViewController = NavigationViewController(for: route)
            navigationViewController.simulatesLocationUpdates = false
            navigationViewController.routeController.snapsUserLocationAnnotationToRoute = true
            navigationViewController.voiceController?.volume = 0.5
            navigationViewController.navigationDelegate = self
            
            self?.present(navigationViewController, animated: true, completion: nil)
            
            didFinish?()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return zones.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "zoneCell", for: indexPath) as! DirectionsTableViewCell
        let zone = zones[indexPath.row]
        cell.setupCell(zone: zone)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let zone = zones[indexPath.row]
        //setupRoute(zone: zone)
        getRoute(zone: zone)
    }
}
*/
