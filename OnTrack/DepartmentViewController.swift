//
//  DepartmentViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/14/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftDate
import Alamofire
import SwiftyJSON

class DepartmentViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let realm = try! Realm()
    var departments = [Department]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getDepartments(eventId: 1) { (departments) in
            self.departments = departments
            self.tableView.reloadData()
        }
        
        tableView.tableFooterView = UIView()
    }
    
    func getDepartments(eventId: Int, completion: @escaping ([Department]) -> ()) {

        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/departments?event_id=\(eventId)"

        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                var departments = [Department]()
                
                for department in json["data"].arrayValue {
                    let d = Department(json: department)
                    departments.append(d)
                }
                completion(departments)
            case .failure:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchStaffSegue" {
            let dvc = segue.destination as! SearchStaffViewController
            dvc.department = sender as! Department
        }
    }
}

extension DepartmentViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return departments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "staffSearchCell", for: indexPath)
        let department = departments[indexPath.row]
        cell.textLabel?.text = department.name
        cell.detailTextLabel?.text = ""
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let department = departments[indexPath.row]
        performSegue(withIdentifier: "searchStaffSegue", sender: department)
    }
}
