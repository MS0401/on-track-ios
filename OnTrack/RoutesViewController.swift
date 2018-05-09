//
//  RoutesViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/26/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import RealmSwift
import ACProgressHUD_Swift

class RoutesViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let realm = try! Realm()
    var routes = [RealmRoute]()
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(RoutesViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //collectionView.refreshControl = refreshControl
        getRoutes(eventId: (currentUser?.event?.eventId)!)
        
    }
    
    func getRoutes(eventId: Int) {
        let progressView = ACProgressHUD.shared
        progressView.progressText = "Updating Routes..."
        progressView.showHUD()
        
        APIManager.shared.getAllRoutes(eventId: eventId) { (routes) in
            self.routes = routes
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
        /*
        APIManager.shared.getRoutes(eventId) {
            self.routes.removeAll()
            let r = self.realm.objects(RealmRoute.self)
            let ar = Array(r)
            self.routes = ar
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        */
        progressView.hideHUD()
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        getRoutes(eventId: (currentUser?.event_id)!)
        collectionView.refreshControl?.endRefreshing()
    }
    
    @IBAction func dismissRoute(_ sender: UIStoryboardSegue) {
        //dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "routeInfoSegue" {
            let dvc = segue.destination as! RouteInfoViewController
            dvc.route = sender as! RealmRoute!
        }
    }
}

extension RoutesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return routes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "routeCell", for: indexPath) as! RouteCollectionViewCell
        let route = routes[indexPath.row]
        cell.setupCell(route: route)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let route = self.routes[indexPath.row]
        //let alertController = UIAlertController(title: "Route Information", message: "Tap info to see route information", preferredStyle: .alert)
        
        let alertController = UIAlertController(title: "Route Information", message: currentUser?.route != route ? "Do you want to change your route to \(route.name!)?" : "You are currently on this route", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            
            try! self.realm.write {
                
                APIManager.shared.postNotification(reason: 3, latitude: (currentUser?.lastLocation?.latitude)!, longitude: (currentUser?.lastLocation?.longitude)!, driver_id: (currentUser?.id)!, phone_number: (currentUser?.cell!)!, event_id: (currentUser?.event_id)!, changeRouteId: (currentUser?.route?.id)!) { (error) in
                    
                    let alertController = UIAlertController(title: "Route Change Received", message: "We have received your request to update your route to \(route.name!)", preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        //Get user
                    })
                    
                    alertController.addAction(action)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
        let mapAction = UIAlertAction(title: "Route Info", style: .default) { (action) in
            self.performSegue(withIdentifier: "routeInfoSegue", sender: self.routes[indexPath.row])
        }
        
        let pdfOutbound = UIAlertAction(title: "Maps", style: .default) { (action) in
            self.performSegue(withIdentifier: "mapImageSegue", sender: self)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        if currentUser!.route!.id != route.id {
            alertController.addAction(OKAction)
        }
        
        
        alertController.addAction(mapAction)
        alertController.addAction(pdfOutbound)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion:nil)
    }
}
