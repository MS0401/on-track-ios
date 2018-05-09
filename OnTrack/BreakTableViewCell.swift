//
//  BreakTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class BreakTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureCell(shiftTime: ShiftTime) {
        nameLabel.text = shiftTime.name
        timeLabel.text = convertTime(dt: shiftTime.time)
    }
}
