//
//  Shift.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 3/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Shift: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var name: String = ""
    @objc dynamic var routeId: Int = 0
    @objc dynamic var eventId: Int = 0
    @objc dynamic var startTime: String? = nil
    @objc dynamic var endTime: String? = nil
    var outOfServiceDrivers = RealmOptional<Int>()
    var checkedInDrivers = RealmOptional<Int>()
    var totalDrivers = RealmOptional<Int>()
    var onBreakDrivers = RealmOptional<Int>()
    let times = List<ShiftTime>()
    let drivers = List<RealmDriver>()
    
    required init() {
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    init(jsonStats: JSON) {
        super.init()
        self.name = jsonStats["name"].stringValue
        self.outOfServiceDrivers.value = jsonStats["out_of_service_drivers"].intValue
        self.onBreakDrivers.value = jsonStats["on_break_drivers"].intValue
        self.checkedInDrivers.value = jsonStats["checked_in_drivers"].intValue
        self.totalDrivers.value = jsonStats["total_drivers"].intValue
        self.routeId = jsonStats["route_id"].intValue
        self.id = jsonStats["id"].intValue
        self.eventId = (currentUser?.event_id)!
    }
    
    init(json: JSON) {
        super.init()
        self.id = json["id"].intValue
        self.name = json["name"].stringValue
        self.routeId = json["route_id"].intValue
        self.eventId = json["event_id"].intValue
    }
    
    init(shiftJson: JSON) {
        super.init()
        self.id = shiftJson["shift"]["id"].intValue
        self.name = shiftJson["shift"]["name"].stringValue
        self.routeId = shiftJson["shift"]["route_id"].intValue
        self.eventId = shiftJson["shift"]["event_id"].intValue
        
        print("------------------> Name \(shiftJson["name"].stringValue)")
        
        for st in shiftJson["shift_times"].arrayValue {
            //let t = ShiftTime(name: st["name"].stringValue, time: st["day_time"].stringValue, shiftId: st["shift_id"].intValue)
            let t = ShiftTime(routeJson: st)
            times.append(t)
        }
        
        for dr in shiftJson["drivers"].arrayValue {
            let d = RealmDriver(routeJson: dr)
            let s = Shift(id: self.id, name: self.name, routeId: self.routeId, eventId: (currentUser?.event_id)!)
            d.shifts.append(s)
            drivers.append(d)
        }
    }
    
    init(id: Int, name: String, routeId: Int, eventId: Int) {
        super.init()
        self.id = id
        self.name = name
        self.routeId = routeId
        self.eventId = eventId
    }
}
