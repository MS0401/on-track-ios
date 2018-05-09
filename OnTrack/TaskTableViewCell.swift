//
//  TaskTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {

    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var reasonView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var vendorLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        colorView.layer.cornerRadius = 8
        colorView.clipsToBounds = true
    }
}
