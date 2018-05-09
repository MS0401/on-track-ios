//
//  StaffTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 5/25/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class StaffTableViewCell: UITableViewCell {

    @IBOutlet weak var staffNameLabel: UILabel!
    @IBOutlet weak var lastScanLabel: UILabel!
    @IBOutlet weak var zoneLabel: UILabel!
    
    var driver: RealmDriver! {
        didSet {
            staffNameLabel.text = driver.name
            lastScanLabel.text = driver.vendor?.name //driver.lastScan?.reason
            zoneLabel.text = driver.role //driver.lastScan?.comment
        }
    }
}
