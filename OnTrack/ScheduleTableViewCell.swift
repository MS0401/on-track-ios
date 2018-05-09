//
//  ScheduleTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/26/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
//import ChameleonFramework
import SwiftDate

class ScheduleTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var highlight: UIView!
    @IBOutlet weak var content: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        highlight.layer.cornerRadius = 2
    }
    
    func configureCell(shiftTime: ShiftTime) {
        nameLabel.text = shiftTime.name
        if let d = DateInRegion(string: shiftTime.time, format: DateFormat.iso8601Auto)?.string() {
            timeLabel.text = d
        }
        
        switch shiftTime.scanType {
        case ScanType.yardArrival.rawValue?:
            highlight.backgroundColor = UIColor.flatBlack
        case ScanType.driverCheckin.rawValue?:
            highlight.backgroundColor = UIColor.flatSkyBlue
        case ScanType.orientation.rawValue?:
            highlight.backgroundColor = UIColor.flatRed
        case ScanType.dryRun.rawValue?:
            highlight.backgroundColor = UIColor.flatRed
        case ScanType.driverBriefing.rawValue?:
            highlight.backgroundColor = UIColor.flatRed
        case ScanType.hotelDesk.rawValue?:
            highlight.backgroundColor = UIColor.flatRed
        case ScanType.yardIn.rawValue?:
            highlight.backgroundColor = UIColor.flatRed
        case ScanType.yardOut.rawValue?:
            highlight.backgroundColor = UIColor.flatGrayDark
        case ScanType.pickupArrival.rawValue?:
            highlight.backgroundColor = UIColor.flatMint
        case ScanType.pickupPax.rawValue?:
            highlight.backgroundColor = UIColor.flatGreen
        case ScanType.dropUnload.rawValue?:
            highlight.backgroundColor = UIColor.flatSkyBlue
        case ScanType.venueStaging.rawValue?:
            highlight.backgroundColor = UIColor.flatRed
        case ScanType.venueLoadOut.rawValue?:
            highlight.backgroundColor = UIColor.flatRed
        case ScanType.breakIn.rawValue?:
            highlight.backgroundColor = UIColor.flatYellow
        case ScanType.breakOut.rawValue?:
            highlight.backgroundColor = UIColor.flatSkyBlue
        case ScanType.outOfServiceMechanical.rawValue?:
            highlight.backgroundColor = UIColor.flatRed
        case ScanType.outOfServiceEmergency.rawValue?:
            highlight.backgroundColor = UIColor.flatRed
        case ScanType.endShift.rawValue?:
            highlight.backgroundColor = UIColor.flatRedDark
        case ScanType.passenger.rawValue?:
            highlight.backgroundColor = UIColor.flatRed
        default:
            highlight.backgroundColor = UIColor.flatSkyBlue
        }
    }
}
