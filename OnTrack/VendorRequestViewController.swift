//
//  VendorRequestViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/14/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import TwicketSegmentedControl
import Alamofire
import SwiftyJSON


let vendorURL = "http://localhost:3000/api/v1"

class VendorRequestViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var segmentedControl: TwicketSegmentedControl!
    var titles = ["Pending", "Approved", "Rejected"]
    var pending = [Request]()
    var approved = [Request]()
    var rejected = [Request]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frame = CGRect(x: 0, y: 0, width: Int(view.frame.width), height: 40)
        segmentedControl = TwicketSegmentedControl(frame: frame)
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        view.addSubview(segmentedControl)
        view.bringSubview(toFront: segmentedControl)
        
        tableView.tableFooterView = UIView()
        
        getRequests()
    }
    
    func getRequests() {
        
        let path = "\(vendorURL)/vendors/1/requests"
        print(path)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let pendingJson = json["pending"].arrayValue
                let approvedJson = json["approved"].arrayValue
                let rejectedJson = json["rejected"].arrayValue
                
                for request in pendingJson {
                    let r = Request(json: request)
                    self.pending.append(r)
                }
                
                for request in approvedJson {
                    let r = Request(json: request)
                    self.approved.append(r)
                }
                
                for request in rejectedJson {
                    let r = Request(json: request)
                    self.rejected.append(r)
                }
                
                DispatchQueue.main.async {
                    print(self.pending.count)
                    print(self.approved.count)
                    print(self.rejected.count)
                    self.tableView.reloadData()
                }

            case .failure:
                break
            }
        }
    }

}

extension VendorRequestViewController: TwicketSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
        tableView.reloadData()
        /*
        switch segmentIndex {
        case 0:
            <#code#>
        default:
            <#code#>
        }
        */
    }
}

extension VendorRequestViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return pending.count
        case 1:
            return approved.count
        case 2:
            return rejected.count
        default:
            return pending.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "vendorRequestCell", for: indexPath)
        var request: Request!
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            request = pending[indexPath.row]
        case 1:
            request = approved[indexPath.row]
        case 2:
            request = rejected[indexPath.row]
        default:
            request = pending[indexPath.row]
        }
        cell.textLabel?.text = request.requestType
        cell.detailTextLabel?.text = request.status
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
