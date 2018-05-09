//
//  RouteStatsTableViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class RouteStatsTableViewCell: UITableViewCell {

    @IBOutlet weak var routeNameLabel: UILabel!
    @IBOutlet weak var routeNumberLabel: UILabel!
    @IBOutlet weak var routePercentLabel: UILabel!
    @IBOutlet weak var routeProgressView: UIProgressView!
    
    var progress: Float! {
        didSet {
            UIView.animate(withDuration: 1.0) {
                self.routePercentLabel.alpha = 1.0
                self.routeProgressView.setProgress(self.progress, animated: true)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        routePercentLabel.alpha = 0.0
    }

}
