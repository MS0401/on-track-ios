//
//  SearchUidViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyJSON
import Alamofire
import TwicketSegmentedControl

class SearchUidViewController: UIViewController, TwicketSegmentedControlDelegate {

    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var segmentedControl: TwicketSegmentedControl!
    
    let realm = try! Realm()
    let searchController = UISearchController(searchResultsController: nil)
    var items = [Inventory]()
    var filter = [Inventory]()
    var titles = ["UID", "Staff Name"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Search"
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = UIColor(red: 41/255, green: 50/255, blue: 65/255, alpha: 1.0)
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.tableFooterView = UIView()
        /*
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        */
    }
    
    func didSelect(_ segmentIndex: Int) {
        
    }
    
    func searchUid(keyword: String, completion: @escaping ([Inventory]) -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories?page=1&page_size=50&event_id=1&keyword=\(keyword)"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        //"event_id": 1,
        //"inventory_type_id": 1,
        let parameters = [
            "event_id": 1,
            "inventory_type_id": 1
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                var inventories = [Inventory]()
                inventories.removeAll()
                for i in json["data"].arrayValue {
                    let inv = Inventory(json: i)
                    inventories.append(inv)
                }
                completion(inventories)
            case .failure:
                break
            }
        }
    }
    
    func getInventoryItem(id: Int, completion: @escaping (Inventory) -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/\(id)"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let item = Inventory(json: json["data"])
                print(json)
                completion(item)
            case .failure:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchUidItemSegue" {
            let dvc = segue.destination as! GeneratorDetailViewController
            dvc.inventoryItem = sender as! Inventory
        }
    }
}

extension SearchUidViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! ItemTableViewCell
        let item = items[indexPath.row]
        
        cell.checkOutLabel.text = "\(item.name) \(item.uid)"
       
        if item.departmentName == "" || item.departmentName == " " {
            cell.timeLabel.text = "Department: Not Assigend"
        } else {
            cell.timeLabel.text = "Department: \(item.departmentName)"
        }
        
        if item.locationDescription == "" {
            cell.jobLabel.text = "Location: Not Assigned"
        } else {
            cell.jobLabel.text = "Location: \(item.locationDescription)"
        }
        
        switch item.lastScan!.scanType {
        case "available":
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
        case "assigned":
            cell.reasonView.backgroundColor = UIColor.flatGreen
        case "out_of_service":
            cell.reasonView.backgroundColor = UIColor.flatRed
        default:
            break
        }
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        getInventoryItem(id: items[indexPath.row].id) { (inventory) in
            self.performSegue(withIdentifier: "searchUidItemSegue", sender: inventory)
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        /*
        items = items.filter({( item: Inventory ) -> Bool in
            return item.uid.lowercased().contains(searchText.lowercased())
        })
        
        print(searchText)
 
        if searchText != nil || searchText != "" || searchText != " " {
            searchUid(keyword: searchText) { (inventories) in
                self.items = inventories
                self.tableView.reloadData()
            }
        }
         */
    }
}

extension SearchUidViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        //filterContentForSearchText(searchBar.text!)
        if searchBar.text!.isEmpty {
            
        } else {
            searchUid(keyword: searchBar.text!) { (inventories) in
                self.items = inventories
                self.tableView.reloadData()
            }
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.items.removeAll()
        self.tableView.reloadData()
    }
}
