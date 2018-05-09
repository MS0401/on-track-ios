//
//  CategoryViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyJSON
import Alamofire

class CategoryViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let realm = try! Realm()
    var categories = [InventoryType]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inventory Categories"
        tableView.tableFooterView = UIView()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        getInventoryTypes()
    }
    
    func getInventoryTypes() {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventory_types"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let data = json["data"].arrayValue
                //var inventory = [InventoryType]()
                
                for d in data {
                    let inventoryType = InventoryType(json: d)
                    self.categories.append(inventoryType)
                }
                
                self.tableView.reloadData()
                
            case .failure:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let it = sender as! InventoryType
        if segue.identifier == "radioCategorySegue" {
            let dvc = segue.destination as! RadioStatsViewController
            dvc.eventId = 1
            dvc.inventoryTypeId = it.id
            dvc.inventoryName = it.name
        }
    }
}

extension CategoryViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        let category = categories[indexPath.row]
        cell.textLabel?.text = category.name
        cell.detailTextLabel?.text = " "
        /*
        switch indexPath.row {
        case 0:
            let rdos = realm.objects(Equipment.self)
            let assigned = rdos.filter("status == 2")
            cell.textLabel?.text = "Radios"
            cell.detailTextLabel?.text = "\(rdos.count)/\(assigned.count)"
        case 1:
            cell.textLabel?.text = "Generators"
            cell.detailTextLabel?.text = "10/8"
        case 2:
            cell.textLabel?.text = "Vehicles"
            cell.detailTextLabel?.text = "25/10"
        default:
            break
        }
        */
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let inventoryType = categories[indexPath.row]
        performSegue(withIdentifier: "radioCategorySegue", sender: inventoryType)
    }
}
