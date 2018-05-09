//
//  StaffMembersTableViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 5/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class StaffMembersTableViewController: UITableViewController {
    
    var drivers = [RealmDriver]()
    var filter = [RealmDriver]()
    
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = UIColor(red: 41/255, green: 50/255, blue: 65/255, alpha: 1.0)
        extendedLayoutIncludesOpaqueBars = true
        
        getStaff()
        
        refreshControl?.addTarget(self, action: #selector(StaffMembersTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.tableFooterView = UIView()
    }
    
    func getStaff() {
        APIManager.shared.getAllStaffMembers(roles: ["admin", "manager", "route_managers"]) { (drivers) in
            self.drivers = drivers.sorted { $0.name < $1.name }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        getStaff()
        tableView.reloadData()
        refreshControl.endRefreshing()
    }

    @IBAction func callDispatch(_ sender: Any) {
        let alert = UIAlertController(title: "Dispatch", message: "Call or Text Dispatch", preferredStyle: UIAlertControllerStyle.alert)
        let callAction = UIAlertAction(title: "Call", style: UIAlertActionStyle.default) { (action) in
            UIApplication.shared.open(URL(string: "telprompt://1\(String(describing: "4152002585"))")!, options: [:], completionHandler: nil)
        }
        
        let textAction = UIAlertAction(title: "Text", style: UIAlertActionStyle.default) { (action) in
                let number = "sms:+1\(String(describing: "4152002585"))"
                UIApplication.shared.openURL(NSURL(string: number)! as URL)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(callAction)
        alert.addAction(textAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "staffDetailSegue" {
            let dvc = segue.destination as! StaffDetailViewController
            dvc.driver = sender as! RealmDriver
        }
    }
   
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filter.count
        }
        return drivers.count
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "staffCell", for: indexPath) as! StaffTableViewCell
        var driver: RealmDriver!
        if searchController.isActive && searchController.searchBar.text != "" {
            driver = filter[indexPath.row] as RealmDriver
        } else {
            driver = drivers[indexPath.row] as RealmDriver
        }
        cell.driver = driver
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let driver: RealmDriver!
        if searchController.isActive && searchController.searchBar.text != "" {
            driver = filter[indexPath.row] as RealmDriver
        } else {
            driver = drivers[indexPath.row] as RealmDriver
        }
        
        performSegue(withIdentifier: "staffDetailSegue", sender: driver)
    }
}

extension StaffMembersTableViewController: UISearchBarDelegate {
}

extension StaffMembersTableViewController: UISearchResultsUpdating {
    
    func filterContentForSearchText(_ searchText: String) {
        filter = drivers.filter({( driver: RealmDriver ) -> Bool in
            return driver.name.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
}
