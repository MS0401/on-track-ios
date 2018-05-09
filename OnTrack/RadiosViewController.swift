//
//  RadiosViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/1/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyJSON
import SwiftDate

class RadiosViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    lazy var realm = try! Realm()
    //var radios = [[String: Any]]()
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
    
    var assignedRadios: [Equipment]! {
        get {
            let realm = try! Realm()
            var rd = [Equipment]()
            let rdos = realm.objects(Equipment.self)
            for r in rdos {
                if r.status == 1 {
                    rd.append(r)
                }
            }
            return rd
        }
    }
    
    
    
    let searchController = UISearchController(searchResultsController: nil)
    var isFromOtherVC = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "All Radios"
        tableView.tableFooterView = UIView()
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = UIColor(red: 41/255, green: 50/255, blue: 65/255, alpha: 1.0)
        
        tableView.tableHeaderView = searchController.searchBar
        
        let s1: JSON = ["id": 1, "name": "Radio One", "created_at": "Sept 1", "status": 1, "type": "Radio", "uid": "12345"]
        let s2: JSON = ["id": 2, "name": "Radio Two", "created_at": "Sept 1", "status": 1, "type": "Radio", "uid": "123456"]
        let s3: JSON = ["id": 3, "name": "Radio Three", "created_at": "Sept 1", "status": 1, "type": "Radio", "uid": "1234567"]
        
        let equip1 = Equipment(json: s1)
        let equip2 = Equipment(json: s2)
        let equip3 = Equipment(json: s3)
        
        if realm.objects(Equipment.self).count > 0 {
            
        } else {
            try! realm.write {
                realm.add(equip1)
                realm.add(equip2)
                realm.add(equip3)
            }
        }
        
        print(realm.configuration.fileURL)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @IBAction func addToInventory(_ sender: UIBarButtonItem) {
        
        let decisionController = UIAlertController(title: "Select", message: "Please select from the following to add radio to inventory", preferredStyle: .alert)
        let scanAction = UIAlertAction(title: "Scan", style: .default) { (action) in
            self.performSegue(withIdentifier: "scanInventorySegue", sender: self)
        }
        
        let manualAction = UIAlertAction(title: "Manual", style: .default) { (action) in
            let alertController = UIAlertController(title: "Add Radio to Inventory",
                                                    message: "Please enter all required fields",
                                                    preferredStyle: UIAlertControllerStyle.alert)
            
            alertController.addTextField { (textfield) in
                textfield.placeholder = "Radio ID"
            }
            /*
            alertController.addTextField { (textfield) in
                textfield.placeholder = "Name"
            }
            alertController.addTextField { (textfield) in
                textfield.placeholder = "Status"
            }
            */
            
            let submitAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (action) in
                
                let one: Int = Int(alertController.textFields![0].text!)!
                //let two = alertController.textFields![1].text!
                //let three: Int = Int(alertController.textFields![2].text!)!
                
                let s1: JSON = ["id": one, "created_at": "Sept 1", "status": 1, "type": "Radio", "uid": "\(one)"]
                let equip1 = Equipment(json: s1)
                
                try! self.realm.write {
                    self.realm.add(equip1)
                }
                
                self.tableView.reloadData()
                
                /*
                var when = DispatchTime.now() + 1
                DispatchQueue.main.asyncAfter(deadline: when) {
                    self.completionAlert(title: "Radio Added", subtitle: "Radio successfully added to inventory")
                }
                */
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(submitAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion:nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        decisionController.addAction(scanAction)
        decisionController.addAction(manualAction)
        decisionController.addAction(cancelAction)
        present(decisionController, animated: true, completion:nil)
    }
    
    func completionAlert(title: String, subtitle: String) {
        _ = SweetAlert().showAlert(title, subTitle: subtitle, style: AlertStyle.success, buttonTitle:  "Ok", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
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
        } else if segue.identifier == "radioDetailSegue" {
            let row = sender as! Int
            let radio: Equipment!
            switch isFromOtherVC {
            case false:
                radio = radios[row]
            case true:
                radio = assignedRadios[row]
            default:
                break
            }
            let dvc = segue.destination as! RadioDetailViewController
            dvc.radio = radio
        }
    }
}

extension RadiosViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFromOtherVC == false {
            return radios.count
        } else {
            return assignedRadios.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "radioC", for: indexPath) as! ItemTableViewCell
        let radio: Equipment!
        
        switch isFromOtherVC {
        case false:
           radio = radios[indexPath.row]
        case true:
            radio = assignedRadios[indexPath.row]
        default:
            break
        }
        
        cell.checkOutLabel.text = "\(radio.type) ID: \(radio.id)"
        cell.itemImageView.layer.cornerRadius = 4
        
        if radio.assignedTo != "" {
            cell.timeLabel.text = "Assigned To: \(radio.assignedTo)"
        } else {
            cell.timeLabel.text = "Not Assigned"
        }

        switch radio.status {
        case 1:
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
        case 2:
            cell.reasonView.backgroundColor = UIColor.flatGreen
        case 3:
            cell.reasonView.backgroundColor = UIColor.flatRed
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "radioDetailSegue", sender: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let radio = radios[indexPath.row]
            let scans = radio.scans
            
            try! realm.write {
                realm.delete(scans)
                realm.delete(radio)
            }
            
            tableView.reloadData()
        }
    }
}

extension RadiosViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        //filterContentForSearchText(searchBar.text!)
    }
}
