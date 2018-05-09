//
//  RealmLocation.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 2/6/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import SwiftyJSON

class RealmLocation: Object {
    
    @objc dynamic var driver_id: Int = 0
    @objc dynamic var latitude: Float = 0.0
    @objc dynamic var longitude: Float = 0.0
    var load_arrival = RealmOptional<Int>()
    var drop_arrival = RealmOptional<Int>()
    var battery_level = RealmOptional<Float>()
    
    required init() {
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    init(json: JSON) {
        super.init()
        if let id = json["driver_id"].int {
            self.driver_id = id
        }
        
        if let lat = json["latitude"].float {
            self.latitude = lat
        }
        
        if let long = json["longitude"].float {
            self.longitude = long
        }
        
        if json["battery_level"] != JSON.null {
            self.battery_level.value = json["battery_level"].float
        }
    }
}
