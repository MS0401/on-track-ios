//
//  ScanTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 2/3/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import SwiftDate

class ScanTableViewCell: UITableViewCell {

    @IBOutlet weak var scanTypeLabel: UILabel!
    @IBOutlet weak var scanTimeLabel: UILabel!
    @IBOutlet weak var scanColorView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cellView: UIView!
    
    var scan: Scan! {
        didSet {
            scanTypeLabel.text = scan.reason
            nameLabel.text = scan.scannerName
            
            if let d = DateInRegion(string: scan.created_at!, format: DateFormat.iso8601Auto)?.string() {
                scanTimeLabel.text = d
            }
            
            switch scan.reason {
            case ScanType.yardArrival.rawValue?:
                scanColorView.backgroundColor = UIColor.flatBlack
            case ScanType.driverCheckin.rawValue?:
                scanColorView.backgroundColor = UIColor.flatGray
            case ScanType.orientation.rawValue?:
                scanColorView.backgroundColor = UIColor.flatRed
            case ScanType.dryRun.rawValue?:
                scanColorView.backgroundColor = UIColor.flatRed
            case ScanType.driverBriefing.rawValue?:
                scanColorView.backgroundColor = UIColor.flatRed
            case ScanType.hotelDesk.rawValue?:
                scanColorView.backgroundColor = UIColor.flatRed
            case ScanType.yardIn.rawValue?:
                scanColorView.backgroundColor = UIColor.flatRed
            case ScanType.yardOut.rawValue?:
                scanColorView.backgroundColor = UIColor.flatRed
            case ScanType.pickupArrival.rawValue?:
                scanColorView.backgroundColor = UIColor.flatMint
            case ScanType.pickupPax.rawValue?:
                scanColorView.backgroundColor = UIColor.flatMint
            case ScanType.dropUnload.rawValue?:
                scanColorView.backgroundColor = UIColor.flatSkyBlue
            case ScanType.venueStaging.rawValue?:
                scanColorView.backgroundColor = UIColor.flatSkyBlue
            case ScanType.venueLoadOut.rawValue?:
                scanColorView.backgroundColor = UIColor.flatRed
            case ScanType.breakIn.rawValue?:
                scanColorView.backgroundColor = UIColor.flatYellow
            case ScanType.breakOut.rawValue?:
                scanColorView.backgroundColor = UIColor.flatRed
            case ScanType.outOfServiceMechanical.rawValue?:
                scanColorView.backgroundColor = UIColor.flatRed
            case ScanType.outOfServiceEmergency.rawValue?:
                scanColorView.backgroundColor = UIColor.flatRed
            case ScanType.endShift.rawValue?:
                scanColorView.backgroundColor = UIColor.flatGray
            case ScanType.passenger.rawValue?:
                scanColorView.backgroundColor = UIColor.flatRed
            default:
                scanColorView.backgroundColor = UIColor.flatSkyBlue
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        scanColorView.layer.cornerRadius = 3
    }
    
    func setupCell() {
        scanColorView.layer.cornerRadius = 3
    }
}
