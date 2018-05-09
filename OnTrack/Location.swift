//
//  Location.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/18/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Location {
    var driver_id: Int
    var latitude: Float
    var longitude: Float
    var id: Int?
    var load_arrival: Int?
    var drop_arrival: Int?
    var battery_level: Float?
    
    init(driver_id: Int, latitude: Float, longitude: Float) {
        self.driver_id = driver_id
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(json: JSON) {
        self.id = json["id"].int!
        self.driver_id = json["driver_id"].int!
        self.latitude = json["latitude"].float!
        self.longitude = json["longitude"].float!
    }
}
