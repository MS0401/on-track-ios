//
//  Driver.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/8/16.
//  Copyright © 2016 Peter Hitchcock. All rights reserved.
//

import Foundation
import SwiftyJSON

class Driver {
    var id: Int
    var first_name: String
    var last_name: String
    var cell: String
    var gender: String?
    var driver_license_number: String?
    var driver_license_expire: Date?
    var vendor_id: Int?
    var vehicle_id: Int?
    var event_id: Int?
    
    init(id: Int, firstName: String, lastName: String, cell: String) {
        self.id = id
        self.first_name = firstName
        self.last_name = lastName
        self.cell = cell
    }
}
