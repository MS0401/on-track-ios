//
//  MessageTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/30/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var senderName: UILabel!
    @IBOutlet weak var senderMessage: UILabel!
    @IBOutlet weak var notificationImageView: UIImageView!
    @IBOutlet weak var routeWaveLabel: UILabel!
    @IBOutlet weak var lastScanLabel: UILabel!
    
    var dict: [String: Any]! {
        didSet {
            if let unread = dict["unread"] {
                if unread as! Bool == true {
                    notificationImageView.isHidden = false
                } else {
                    notificationImageView.isHidden = true
                }
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
