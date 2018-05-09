//
//  InventoryDetailsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/8/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class InventoryDetailsViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var departmentLabel: UILabel!
    @IBOutlet weak var associatLabel: UILabel!
    
    var inventoryItem: Inventory!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusColors()
        
        NotificationCenter.default.addObserver(self, selector: #selector(InventoryDetailsViewController.updateLabel), name: NSNotification.Name(rawValue: "inventory"), object: nil)
    }
    
    @objc func updateLabel() {
        statusColors()
    }
    
    func statusColors() {
        if inventoryItem.departmentName == "" {
            departmentLabel.text = "Not Specified"
        } else {
            departmentLabel.text = inventoryItem.departmentName
        }
        
        //print(inventoryItem.parentId)
        print("description \(inventoryItem.locationDescription)")
        
        if inventoryItem.locationDescription == "" {
            associatLabel.text = "Not Specified"
        } else {
            associatLabel.text = "\(inventoryItem.locationDescription)"
        }
        //associatLabel.text = "\(inventoryItem.locationDescription)"
        /*
        if inventoryItem.parentId == 0 && inventoryItem.accessories.count > 0 {
            associatLabel.text = "Parent"
        } else if inventoryItem.parentId == 0 && inventoryItem.accessories.count == 0 {
            associatLabel.text = "Not Associated"
        } else {
            associatLabel.text = "ID \(inventoryItem.parentId)"
        }
        */

        
        
        if let status = inventoryItem.lastScan?.scanType {
            switch status {
            case "received":
                statusLabel.text = "Received"
                statusLabel.textColor = UIColor.flatSkyBlue
            case "assigned":
                statusLabel.text = "Assigned"
                statusLabel.textColor = UIColor.flatGreen
            case "fuel":
                statusLabel.text = "Fuel"
                statusLabel.textColor = UIColor.flatOrange
            case "out_of_service":
                statusLabel.text = "Out of Service"
                statusLabel.textColor = UIColor.flatRed
            case "checked_in":
                statusLabel.text = "Checked In"
                statusLabel.textColor = UIColor.flatForestGreen
            case "checked_out":
                statusLabel.text = "Checked Out"
                statusLabel.textColor = UIColor.flatBlueDark
            default:
                statusLabel.text = "Not Scanned"
                statusLabel.textColor = UIColor.flatGray
            }
        }
    }

}
