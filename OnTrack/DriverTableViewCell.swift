//
//  DriverTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 2/6/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class DriverTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var vendorName: UILabel!
    @IBOutlet weak var shiftName: UILabel!
    
    var driver: RealmDriver! {
        didSet {
            nameLabel.text = driver.name
            vendorName.text = driver.vendor?.name
            shiftName.text = driver.shifts.first?.name
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
