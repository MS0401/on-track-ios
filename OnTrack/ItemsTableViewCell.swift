//
//  ItemsTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class ItemsTableViewCell: UITableViewCell {

    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        /*
        colorView.layer.cornerRadius = 6
        colorView.clipsToBounds = true
        itemImageView.layer.cornerRadius = 5
        itemImageView.clipsToBounds = true
        */
    }
    
    func setupCell(item: [String: String]) {
        titleLabel.text = item["title"]
        locationLabel.text = item["location"]
        colorView.layer.cornerRadius = 6
        colorView.clipsToBounds = true
        itemImageView.image = UIImage(named: item["image"]!)
        itemImageView.layer.cornerRadius = 5
        itemImageView.clipsToBounds = true
    }
}
