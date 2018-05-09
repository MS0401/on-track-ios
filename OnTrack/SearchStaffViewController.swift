//
//  SearchStaffViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/5/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftDate
import Alamofire
import SwiftyJSON

class SearchStaffViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    lazy var realm = try! Realm()
    let searchController = UISearchController(searchResultsController: nil)
    /*
    var staff: [RealmDriver]! {
        get {
            let realm = try! Realm()
            var rd = [RealmDriver]()
            let rdos = realm.objects(RealmDriver.self)
            for r in rdos {
                rd.append(r)
            }
            return rd
        }
    }*/
    var radio: Equipment!
    var isFromOtherVC = false
    var department: Department!
    var staff = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = department.name
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = UIColor(red: 41/255, green: 50/255, blue: 65/255, alpha: 1.0)
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.tableFooterView = UIView()
        
        getStaff(id: department.id, eventId: department.eventId) { (users) in
            self.staff = users
            self.tableView.reloadData()
        }
        /*
        let d1 = RealmDriver()
        d1.id = 10
        d1.name = "Peter Hitchcock"
        
        let d2 = RealmDriver()
        d2.id = 20
        d2.name = "Lauren Rippee"
        
        let d3 = RealmDriver()
        d3.id = 30
        d3.name = "John Conway"
        
        let d4 = RealmDriver()
        d4.id = 40
        d4.name = "Jimmy Engelman"
        
        let drivers = realm.objects(RealmDriver.self)
        
        if drivers.count > 1 {
        } else {
            try! realm.write {
                realm.add(d1)
                realm.add(d2)
                realm.add(d3)
                realm.add(d4)
            }
        }
        */
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    @IBAction func addStaffMember(_ sender: UIBarButtonItem) {
        addStaff()
    }
    
    func addStaff() {
        
        let ac = UIAlertController(title: "Add Staff", message: "Add a staff member by scan or manually", preferredStyle: .alert)
        let scanAction = UIAlertAction(title: "Scan", style: .default) { (action) in
            self.performSegue(withIdentifier: "addStaffSegue", sender: self)
        }
        
        let manualAction = UIAlertAction(title: "Manual", style: .default) { (action) in
            let alertController = UIAlertController(title: "Add Staff",
                                                    message: "Please enter all required fields",
                                                    preferredStyle: UIAlertControllerStyle.alert)
            
            alertController.addTextField { (textfield) in
                textfield.placeholder = "First Name"
            }
            alertController.addTextField { (textfield) in
                textfield.placeholder = "Last Name"
            }
            alertController.addTextField { (textfield) in
                textfield.placeholder = "ID"
            }
            
            let submitAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (action) in
                let d1 = RealmDriver()
                d1.id = Int(alertController.textFields![2].text!)!
                d1.name = "\(alertController.textFields![0].text!) \(alertController.textFields![1].text!)"
                
                try! self.realm.write {
                    self.realm.add(d1)
                }
                
                self.tableView.reloadData()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(submitAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion:nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        ac.addAction(scanAction)
        ac.addAction(manualAction)
        ac.addAction(cancelAction)
        present(ac, animated: true, completion: nil)
        
    }
    
    /*
    func assignRadioToStaffMember(row: Int) {
        let st = self.staff[row]
        
        let alertController = UIAlertController(title: "Assign Radio",
                                                message: "Assign Radio to Peter Hitchcock",
                                                preferredStyle: UIAlertControllerStyle.alert)
        
        let submitAction = UIAlertAction(title: "Assign", style: UIAlertActionStyle.default) { (action) in
            let now = DateInRegion()
            let scan = Scan()
            scan.reason = "checkout"
            scan.driverName = st.name
            scan.driver_id = st.id
            scan.created_at = now.string()
            scan.equipmentStatus = "\(self.radio.type) ID: \(self.radio.id)"
    
            try! self.realm.write {
                self.radio.type = "Radio"
                self.radio.status = 2
                self.radio.assignedTo = st.name
                self.radio.assignedId = st.id
                self.radio.scans.append(scan)
                st.scans.append(scan)
                st.equipment.append(self.radio)
            }
            
            self.navigationController?.popViewController(animated: true)
        }
        
        let infoAction = UIAlertAction(title: "Staff Info", style: .default) { (action) in
            self.performSegue(withIdentifier: "searchStaffDetailSegue", sender: st)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(submitAction)
        alertController.addAction(infoAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion:nil)
    }
    */
    
    func getStaff(id: Int, eventId: Int, completion: @escaping ([User]) -> ()) {
        
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/departments/\(id)?event_id=\(eventId)"
        print(path)
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                var users = [User]()
                
                for user in json["data"]["users"].arrayValue {
                    let u = User(json: user)
                    users.append(u)
                }
                
                completion(users)
            case .failure:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "searchStaffDetailSegue" {
            let staff = sender as! User
            let dvc = segue.destination as! ItemStaffViewController
            dvc.staff = staff
        }
    }
}

extension SearchStaffViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return staff.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "staffSearchCell", for: indexPath)
        let st = staff[indexPath.row]
        cell.textLabel?.text = st.name
        cell.detailTextLabel?.text = st.cell
        
        /*
        if st.equipment.count == 0 {
            cell.detailTextLabel?.text = ""
        } else if st.equipment.count == 1 {
            cell.detailTextLabel?.text = "\(st.equipment.count) Item"
        } else {
            cell.detailTextLabel?.text = "\(st.equipment.count) Items"
        }
        */
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let st = staff[indexPath.row]
        self.performSegue(withIdentifier: "searchStaffDetailSegue", sender: st)
        /*
        if isFromOtherVC == false {
            let st = staff[indexPath.row]
            self.performSegue(withIdentifier: "searchStaffDetailSegue", sender: st)
        } else {
            assignRadioToStaffMember(row: indexPath.row)
        }
        */
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            /*
            let st = staff[indexPath.row]
            
            try! realm.write {
                realm.delete(st)
            }
            
            tableView.reloadData()
            */
        }
        
    }
}

extension SearchStaffViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        //filterContentForSearchText(searchBar.text!)
    }
}
