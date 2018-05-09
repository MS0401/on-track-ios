//
//  Zone.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/25/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Zone: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var latitude: Float = 0
    @objc dynamic var longitude: Float = 0
    @objc dynamic var route_id: Int = 0
    @objc dynamic var point: String = ""
    @objc dynamic var id: Int = 0
    @objc dynamic var geo: Float = 0
    @objc dynamic var zoneId: Int = 0
    
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
    
    init(json: JSON) {
        super.init()
        self.name = json["name"].stringValue
        
        if (json["latitude"].null != nil) {
            self.latitude = 1.0
        } else {
            self.latitude = json["latitude"].float!
        }
        
        if json["longitude"].null != nil {
            self.longitude = 1.0
        } else {
            self.longitude = json["longitude"].float!
        }
        
        if let routeId = json["route_id"].int {
            self.route_id = routeId
        }
        
        self.point = json["point"].stringValue
        
        if let id = json["id"].int {
            self.id = id
        }
        
        if json["geo_fence"].null != nil {
            self.geo = json["geo_fence"].floatValue
        }
    }
}
