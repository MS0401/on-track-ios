//
//  VendorEquipmentViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/14/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import TwicketSegmentedControl
import Alamofire
import SwiftyJSON

class VendorEquipmentViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var segmentedControl: TwicketSegmentedControl!
    var titles = ["Delivered", "Scheduled"]
    var delivered = [Equipment]()
    var scheduled = [Equipment]()
    
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
        
        getEquipment()
    }
    
    func getEquipment() {
        
        let path = "\(vendorURL)/vendors/1/equipment"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let equipmentJson = json["equipment"].arrayValue
                
                for equipment in equipmentJson {
                    let e = Equipment(json: equipment)
                    
                    if e.delivered == false {
                        self.scheduled.append(e)
                    } else {
                        self.delivered.append(e)
                    }
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

extension VendorEquipmentViewController: TwicketSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
        tableView.reloadData()
    }
}

extension VendorEquipmentViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return delivered.count
        case 1:
            return scheduled.count
        default:
            return delivered.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "vendorEquipmentCell", for: indexPath)
        var equipment: Equipment!
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            equipment = delivered[indexPath.row]
        case 1:
            equipment = scheduled[indexPath.row]
        default:
            equipment = delivered[indexPath.row]
        }
        cell.textLabel?.text = equipment.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
