//
//  Route.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/26/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import SwiftyJSON
import Realm
import RealmSwift

class RealmRoute: Object {
    @objc dynamic var name: String?
    @objc dynamic var id: Int = 0
    @objc dynamic var assignedRoute: Bool = false
    @objc dynamic var event_id: Int = 0
    var outOfServiceDrivers = RealmOptional<Int>()
    var checkedInDrivers = RealmOptional<Int>()
    var totalDrivers = RealmOptional<Int>()
    var onBreakDrivers = RealmOptional<Int>()
    var ridershipCount = RealmOptional<Int>()
    let zones = List<Zone>()
    let shifts = List<Shift>()
    let scans = List<Scan>()
    
    required init() {
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    init(driverJSON: JSON) {
        super.init()
        self.name = driverJSON["name"].stringValue
        
        if let id = driverJSON["id"].int {
            self.id = id
        }
        
        if let eventId = driverJSON["event_id"].int {
            self.event_id = eventId
        }

        let zs = driverJSON["zones"].arrayValue
        
        for z in zs {
            let zone = Zone(json: z)
            self.zones.append(zone)
        }
    }
    
    init(json: JSON) {
        super.init()
       
        self.name = json["route"]["name"].stringValue
        self.id = json["route"]["id"].intValue
        self.event_id = json["route"]["event_id"].intValue
        let zs = json["zones"].arrayValue
        
        for z in zs {
            let zone = Zone(json: z)
            self.zones.append(zone)
        }
    }
    
    init(routeJSON: JSON) {
        super.init()
        self.name = routeJSON["name"].stringValue
        
        self.outOfServiceDrivers.value = routeJSON["out_of_service_drivers"].intValue
        self.checkedInDrivers.value = routeJSON["checked_in_drivers"].intValue
        self.totalDrivers.value = routeJSON["total_drivers"].intValue
        self.onBreakDrivers.value = routeJSON["on_break_drivers"].intValue
        
        for shift in routeJSON["route_shifts"].arrayValue {
            let s = Shift(jsonStats: shift)
            self.shifts.append(s)
        }
    }
}
