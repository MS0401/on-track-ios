//
//  TrafficTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/8/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import SwiftDate

class TrafficTableViewCell: UITableViewCell {
    
    @IBOutlet weak var notificationReason: UILabel!
    @IBOutlet weak var routeName: UILabel!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var driverNamelabel: UILabel!
    
    var notification: RealmNotification! {
        didSet {
            notificationReason.text = notification.reason
            routeName.text = notification.routeName
            driverNamelabel.text = notification.driver?.name
            
            if let d = DateInRegion(string: notification.createdAt, format: DateFormat.iso8601Auto)?.string() {
                createdAtLabel.text = d
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
