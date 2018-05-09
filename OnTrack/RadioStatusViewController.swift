//
//  RadioStatusViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/1/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON
import SwiftDate

class RadioStatusViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    lazy var realm = try! Realm()
    var inventories = [Inventory]()
    var inventoryTypeId: Int!
    var inventoryStatus: String!
    /*
    var radios: [Equipment]! {
        get {
            let realm = try! Realm()
            var rd = [Equipment]()
            let rdos = realm.objects(Equipment.self)
            for r in rdos {
                rd.append(r)
            }
            return rd
        }
    }
    */
    //var scans = [Equipment]()
    //var status: Int!
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        /*
        if let status = self.status {
            
            switch status {
            case 1:
                self.scans = self.radios.filter { $0.status == 1 }
                title = "\(self.scans.count) Available"
            case 2:
                self.scans = self.radios.filter { $0.status == 2 }
                title = "\(self.scans.count) Assigned"
            case 3:
                self.scans = self.radios.filter { $0.status == 3 }
                title = "\(self.scans.count) Maintenance"
            default:
                break
            }
        }
        */
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = UIColor(red: 41/255, green: 50/255, blue: 65/255, alpha: 1.0)
        tableView.tableHeaderView = searchController.searchBar
        
        switch inventoryStatus {
        case "available":
            title = "Available"
        case "assigned":
            title = "Assigned"
        case "out_of_service":
            title = "Out of Service"
        default:
            title = "Inventory"
        }
        
        getInventoryByStats(eventId: 1, inventoryTypeId: inventoryTypeId, type: inventoryStatus)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /*
        if let status = self.status {
            
            switch status {
            case 1:
                self.scans = self.radios.filter { $0.status == 1 }
                title = "\(self.scans.count) Available"
            case 2:
                self.scans = self.radios.filter { $0.status == 2 }
                title = "\(self.scans.count) Assigned"
            case 3:
                self.scans = self.radios.filter { $0.status == 3 }
                title = "\(self.scans.count) Maintenance"
            default:
                break
            }
        }
        */
        tableView.reloadData()
    }
    
    func getInventoryByStats(eventId: Int, inventoryTypeId: Int, type: String) {
        //print("get inventory")
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/inventories_by_stats?\(eventId)=1&inventory_type_id=\(inventoryTypeId)&type=\(type)"
        //?event_id=1&inventory_type_id=1&type=out_of_service
        //print(path)
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        //print(headers)
        
        let parameters = [
            "event_id": 1,
            "inventory_type_id": 1,
            "type": "out_of_service"
            ] as [String : Any]
        print(parameters)
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            //print("here")
            print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonInventories = json["data"].arrayValue
                self.inventories.removeAll()
                
                for inventory in jsonInventories {
                    let i = Inventory(json: inventory)
                    self.inventories.append(i)
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
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
                print(json)
                
                let item = Inventory(json: json["data"])
                
                completion(item)
                
            case .failure:
                break
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scanInventorySegue" {
            if #available(iOS 11.0, *) {
                let dvc = segue.destination as! BarcodeScannerViewController
                dvc.isFromInventory = true
            } else {
                // Fallback on earlier versions
            }
        } else if segue.identifier == "rDetailSegue" {
            let dvc = segue.destination as! GeneratorDetailViewController
            dvc.inventoryItem = sender as! Inventory
        }
    }
}

extension RadioStatusViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inventories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "radioCell", for: indexPath) as! ItemTableViewCell
        let inventory = inventories[indexPath.row]
        
        cell.checkOutLabel.text = "\(inventory.name) UID: \(inventory.uid)"
        print("inventory department name \(inventory.departmentName)")
        if inventory.departmentName == "" || inventory.departmentName == " " {
             cell.jobLabel.text = "Department: Not Assigned"
        } else {
             cell.jobLabel.text = "Department: \(inventory.departmentName)"
        }
        
        if inventory.locationDescription == "" {
            cell.timeLabel.text = "Location: Not Specified"
        } else {
            cell.timeLabel.text = "Location: \(inventory.locationDescription)"
        }

        
        
        /*
        if let d = DateInRegion(string: (inventory.lastScan?.createdAt)!, format: DateFormat.iso8601Auto)?.string() {
            cell.timeLabel.text = "\(d)"
        }
        */
 
    
        switch inventory.lastScan!.scanType {
        case "available":
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
        case "assigned":
            cell.reasonView.backgroundColor = UIColor.flatGreen
        case "out_of_service":
            cell.reasonView.backgroundColor = UIColor.flatRed
        default:
            break
        }
        
        
        /*
        cell.checkOutLabel.text = "\(scan.type) ID: \(scan.id)"
        //cell.itemImageView.layer.cornerRadius = 4
        
        if scan.assignedTo != "" {
            cell.timeLabel.text = "Assigned To: \(scan.assignedTo)"
        } else {
            cell.timeLabel.text = "Not Assigned"
        }
        
        switch scan.status {
        case 1:
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
        case 2:
            cell.reasonView.backgroundColor = UIColor.flatGreen
        case 3:
            cell.reasonView.backgroundColor = UIColor.flatRed
        default:
            break
        }
        */

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = inventories[indexPath.row]
        getInventoryItem(id: item.id) { (inventoryItem) in
            self.performSegue(withIdentifier: "rDetailSegue", sender: inventoryItem)
        }
    }
}

extension RadioStatusViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        //filterContentForSearchText(searchBar.text!)
    }
}
