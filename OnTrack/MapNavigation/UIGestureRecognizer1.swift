//
//  UIGestureRecognizer1.swift
//  OnTrack
//
//  Created by Andrei Opanasenko on 1/16/18.
//  Copyright © 2018 Peter Hitchcock. All rights reserved.
//

import Foundation
import UIKit

extension UIGestureRecognizer {
    var point: CGPoint? {
        guard let view = view else { return nil }
        return location(in: view)
    }
    
    func requireFailure(of gestures: [UIGestureRecognizer]?) {
        guard let gestures = gestures else { return }
        gestures.forEach(self.require(toFail:))
    }
}
