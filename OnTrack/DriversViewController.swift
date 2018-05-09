//
//  DriversViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/30/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import RealmSwift
import ACProgressHUD_Swift

class DriversViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let realm = try! Realm()
    var drivers = [RealmDriver]()
    var filter = [RealmDriver]()
    var timer: Timer?
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(DriversViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = UIColor(red: 41/255, green: 50/255, blue: 65/255, alpha: 1.0)
        

        tableView.tableHeaderView = searchController.searchBar
        tableView.addSubview(refreshControl)
        tableView.tableFooterView = UIView()
        
        getAllDrivers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func getAllDrivers() {
        let progressView = ACProgressHUD.shared
        progressView.progressText = "Updating Drivers..."
        progressView.showHUD()
        
        APIManager.shared.getDrivers(roles: ["driver"]) { (drivers) in
            self.drivers = drivers.sorted { $0.name < $1.name }
            
            progressView.hideHUD()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        getAllDrivers()
        
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    @IBAction func dismissVC(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "driverDetailSegue" {
            let d = sender as! RealmDriver
            let dvc = segue.destination as! DriverDetailViewController
            dvc.driver = d
            dvc.shift = d.shifts.first
            dvc.driverId = d.id
        }
    }
}

extension DriversViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filter.count
        }
        return drivers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dCell", for: indexPath) as! DriverTableViewCell
        var driver: RealmDriver!
        if searchController.isActive && searchController.searchBar.text != "" {
            driver = filter[indexPath.row] as RealmDriver
        } else {
            driver = drivers[indexPath.row] as RealmDriver
        }
        cell.driver = driver
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let driver: RealmDriver!
        if searchController.isActive && searchController.searchBar.text != "" {
            driver = filter[indexPath.row] as RealmDriver
        } else {
            driver = drivers[indexPath.row] as RealmDriver
        }
        
        performSegue(withIdentifier: "driverDetailSegue", sender: driver)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        filter = drivers.filter({( driver: RealmDriver ) -> Bool in
            return driver.name.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
}

extension DriversViewController: UISearchBarDelegate {
}

extension DriversViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
}
