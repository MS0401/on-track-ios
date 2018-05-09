//
//  Vehicle.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/8/16.
//  Copyright © 2016 Peter Hitchcock. All rights reserved.
//

import Foundation
import SwiftyJSON

class Vehicle {
    var name: String
    var id: Int
    var scans: [Scan]?
    var drivers: [Driver]?
    
    init(name: String, id: Int) {
        self.name = name
        self.id = id
    }
}
