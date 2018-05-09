//
//  ShiftTime.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 3/21/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class ShiftTime: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var time: String = ""
    @objc dynamic var shiftId: Int = 0
    @objc dynamic var comment: String? = nil
    @objc dynamic var scanType: String? = nil
    
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
        self.time = json["day_time"].stringValue
        self.shiftId = json["shift_id"].intValue
        self.scanType = json["scan_type"].stringValue
    }
    
    
    init(routeJson: JSON) {
        super.init()
        print(routeJson)
        self.name = routeJson["name"].stringValue
        self.time = routeJson["day_time"].stringValue
        self.shiftId = routeJson["shift_id"].intValue
        self.scanType = routeJson["scan_type"].stringValue
    }
    
    init(name: String, time: String, shiftId: Int) {
        super.init()
        self.name = name
        self.time = time
        self.shiftId = shiftId
    }
}
