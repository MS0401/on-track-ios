//
//  LostFoundTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import SwiftDate

class LostFoundTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        statusView.layer.cornerRadius = 2
    }
    
    func configueCell(lost: Lost) {
        nameLabel.text = lost.riderName
        phoneLabel.text = lost.riderPhone
        infoLabel.text = lost.body
        let date = DateInRegion(string: lost.createdAt, format: DateFormat.iso8601Auto)?.string()
        timeLabel.text = date
        
        if lost.status == "found" {
            self.statusView.backgroundColor = UIColor.flatGrayDark
            statusLabel.text = "Found"
        } else if lost.status == "returned" {
            self.statusView.backgroundColor = UIColor.flatSkyBlue
            statusLabel.text = "Returned"
        } else {
            self.statusView.backgroundColor = UIColor.flatRedDark
            statusLabel.text = "Lost"
        }
    }
}
