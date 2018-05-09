//
//  VendorStaffListTableViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/11/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift

class VendorStaffListTableViewController: UITableViewController {
    
    let searchController = UISearchController(searchResultsController: nil)
    var staff: [RealmDriver]! {
        get {
            let realm = try! Realm()
            var rd = [RealmDriver]()
            let rdos = realm.objects(RealmDriver.self)
    
            for r in rdos {
                if r.equipment.count > 0 {
                    let assigned = r.equipment.filter("status == 2").first
                    if assigned != nil {
                        rd.append(r)
                    }
                }
            }
            return rd
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "OnTrack"
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = UIColor(red: 41/255, green: 50/255, blue: 65/255, alpha: 1.0)
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return staff.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier", for: indexPath)
        let st = staff[indexPath.row]
        cell.textLabel?.text = st.name
        
        if st.equipment.count == 0 {
            cell.detailTextLabel?.text = ""
        } else if st.equipment.count == 1 {
            cell.detailTextLabel?.text = "\(st.equipment.count) Item"
        } else {
            cell.detailTextLabel?.text = "\(st.equipment.count) Items"
        }
   
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let stf = staff[indexPath.row]
        performSegue(withIdentifier: "vendorStaffSegue", sender: stf)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "vendorStaffSegue" {
            let dvc = segue.destination as! ItemStaffViewController
            let staff = sender as! RealmDriver
            //dvc.staff = staff
        }
    }

}

extension VendorStaffListTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        //filterContentForSearchText(searchBar.text!)
    }
}
