//
//  WaveTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/24/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
//import FoldingCell

class WaveTableViewCell: UITableViewCell {

    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var loopsLabel: UILabel!
    @IBOutlet weak var lastScanLabel: UILabel!
    @IBOutlet weak var vendorName: UILabel!
    @IBOutlet weak var scanColorView: UIView!
    @IBOutlet weak var scannerNameLabel: UILabel!
    
    var driver: RealmDriver! {
        didSet {
            
            var scans = [String]()
            for scan in driver.scans {
                if scan.reason == "drop_unload" || scan.reason == "venue_load_out" {
                    scans.append(scan.reason!)
                }
            }
            
            driverLabel.text = driver.name
            loopsLabel.text = "\(driver.loops)"
            
            if driver.lastScan?.reason == nil || driver.lastScan?.reason == "" {
                lastScanLabel.text = "Not Scanned"
            } else {
                lastScanLabel.text = driver.lastScan?.reason
            }
            
            vendorName.text = driver.vendor?.name
            
            if driver.lastScan?.scannerName == nil || driver.lastScan?.scannerName == "" {
                scannerNameLabel.text = "Not Scanned"
            } else {
                scannerNameLabel.text = driver.lastScan?.scannerName
            }
        
            if let reason = driver.lastScan?.reason {
                switch reason {
                case "yard_arrival", "orientation", "dry_run", "driver_briefing",
                     "hotel_desk":
                    backgroundColor = UIColor.clear
                    scanColorView.backgroundColor = UIColor.flatSkyBlue
                case "driver_check_in":
                    backgroundColor = UIColor.clear
                    scanColorView.backgroundColor = UIColor.flatGray
                case "end_shift", "passenger", "other":
                    backgroundColor = UIColor.clear
                    scanColorView.backgroundColor = UIColor.flatSkyBlue
                case "out_of_service_mechanical", "out_of_service_emergency", "no_show":
                    backgroundColor = UIColor.flatRed
                    scanColorView.backgroundColor = UIColor.flatRed
                case "yard_out", "pick_up_arrival", "pick_up_pax", "venue_staging", "break_out", "yard_in":
                    backgroundColor = UIColor.clear
                    scanColorView.backgroundColor = UIColor.flatMint
                case "drop_unload", "venue_load_out":
                    backgroundColor = UIColor.clear
                    scanColorView.backgroundColor = UIColor.flatSkyBlue
                case "break_in":
                    backgroundColor = UIColor.clear
                    scanColorView.backgroundColor = UIColor.flatYellow
                default:
                    backgroundColor = UIColor.lightGray
                    scanColorView.backgroundColor = UIColor.lightGray
                    scannerNameLabel.text = ""
                }
            } else {
                backgroundColor = UIColor.lightGray
                scanColorView.backgroundColor = UIColor.lightGray
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        scanColorView.layer.cornerRadius = 3
        scanColorView.clipsToBounds = true
    }
}
