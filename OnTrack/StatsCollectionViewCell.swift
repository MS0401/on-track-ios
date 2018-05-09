//
//  StatsCollectionViewCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/21/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import UICircularProgressRing

class StatsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var circleProgress: UICircularProgressRingView!
    @IBOutlet weak var countLabel: UILabel!
    
    var progress: CGFloat! {
        didSet {
            circleProgress.setProgress(value: progress, animationDuration: 2.0, completion: nil)
        }
    }
    
    func setupCell() {
        
    }
}
