//
//  VendorsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/15/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class VendorsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var vendors = [Vendor]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        getVendors()
    }
    
    func getVendors() {
        
        let path = "\(vendorURL)/vendors"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let vendorsJson = json["vendors"].arrayValue
                
                for vendor in vendorsJson {
                    let v = Vendor(json: vendor)
                    self.vendors.append(v)
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case .failure:
                break
            }
        }
    }
}

extension VendorsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vendors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "pmVendorCell", for: indexPath)
        cell.textLabel?.text = vendors[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
