//
//  RequestsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/15/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import TwicketSegmentedControl

class RequestsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: TwicketSegmentedControl!
    
    var titles = ["Pending", "Approved", "Rejected"]
    var requests = [Request]()
    var filter = [Request]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        
        tableView.tableFooterView = UIView()
        
        getAllRequests()
    }
    
    func getAllRequests() {
        
        let path = "\(vendorURL)/requests/all_requests"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonRequests = json["requests"].arrayValue
                
                for request in jsonRequests {
                    let r = Request(json: request)
                    self.requests.append(r)
                }
                
                self.filter = self.requests.filter { $0.status == "pending" }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case .failure:
                break
            }
        }
    }


}

extension RequestsViewController: TwicketSegmentedControlDelegate {
    
    func didSelect(_ segmentIndex: Int) {
        switch segmentIndex {
        case 0:
            filter.removeAll()
            filter = requests.filter { $0.status == "pending" }
            tableView.reloadData()
        case 1:
            filter.removeAll()
            filter = requests.filter { $0.status == "approved" }
            tableView.reloadData()
        case 2:
            filter.removeAll()
            filter = requests.filter { $0.status == "rejected" }
            tableView.reloadData()
        default:
            filter.removeAll()
            filter = requests.filter { $0.status == "pending" }
            tableView.reloadData()
        }
    }
}

extension RequestsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filter.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "pmRequestsCell", for: indexPath)
        cell.textLabel?.text = filter[indexPath.row].requestType
        cell.detailTextLabel?.text = "\(filter[indexPath.row].vendorId)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
