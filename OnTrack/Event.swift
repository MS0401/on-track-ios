//
//  Event.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/12/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Event: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var eventId = 0
    let days = List<Day>()
    let routes = List<RealmRoute>()
    let zones = List<Zone>()
    let waves = List<Shift>()
    @objc dynamic var vehicleCount: Int = 0
    @objc dynamic var active: Bool = false
    @objc dynamic var totalHours: Int = 0
    @objc dynamic var hourlyRate: Int = 0
    
    
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
        self.name = json["name"].stringValue
        self.eventId = json["id"].intValue
    }
}
