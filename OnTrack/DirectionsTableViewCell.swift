//
//  DirectionsTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/25/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class DirectionsTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setupCell(zone: Zone) {
        nameLabel.text = zone.name
        detailsLabel.text = "\(zone.latitude), \(zone.longitude)"
    }
}
