//
//  TaskTimelineTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class TaskTimelineTableViewCell: UITableViewCell {

    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var reasonView: UIView!
    @IBOutlet weak var statusView: UILabel!
    @IBOutlet weak var ownerView: UILabel!
    @IBOutlet weak var timelavel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        colorView.layer.cornerRadius = 4
        colorView.clipsToBounds = true
    }
}
