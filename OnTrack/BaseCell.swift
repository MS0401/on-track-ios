//
//  BaseCell.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class BaseCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
    }
}

