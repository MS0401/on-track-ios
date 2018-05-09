//
//  NotificationTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/30/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import SwiftDate

class NotificationTableViewCell: UITableViewCell {
    
    @IBOutlet var reasonLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var routeLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var notification: RealmNotification! {
        didSet {
            reasonLabel.text = notification.reason
            nameLabel.text = notification.driver?.name
            routeLabel.text = notification.routeName! + " - " + notification.shiftName!
            if let date = DateInRegion(string: notification.createdAt, format: DateFormat.iso8601Auto)?.string() {
                timeLabel.text = date
            }
            
            switch notification.reason {
            case "traffic_slow":
                backgroundColor = UIColor.flatOrange
            case "traffic_under_10":
                backgroundColor = UIColor.flatOrange
            case "traffic_not_moving":
                backgroundColor = UIColor.flatOrange
            case "road_closed":
                backgroundColor = UIColor.flatOrange
            case "emergency":
                backgroundColor = UIColor.flatRed
            case "out_of_service":
                backgroundColor = UIColor.flatRed
            default:
                backgroundColor = UIColor.clear
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
