//
//  ItemTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class ItemTableViewCell: UITableViewCell {

    @IBOutlet weak var reasonView: UIView!
    @IBOutlet weak var checkOutLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var jobLabel: UILabel!
    @IBOutlet weak var bkView: UIView!
    @IBOutlet weak var itemImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bkView.layer.cornerRadius = 4
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
