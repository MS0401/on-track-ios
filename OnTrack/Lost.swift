//
//  Lost.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/18/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Lost: Object {
    
    @objc dynamic var eventId: Int = 0
    @objc dynamic var driverId: Int = 0
    @objc dynamic var body: String = ""
    @objc dynamic var riderName: String = ""
    @objc dynamic var riderPhone: String = ""
    @objc dynamic var createdAt: String = ""
    @objc dynamic var found: Bool = false
    @objc dynamic var status: String = ""
    let comments = List<Comment>()

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
        self.eventId = json["event_id"].intValue
        self.driverId = json["driver_id"].intValue
        self.body = json["body"].stringValue
        self.riderName = json["rider_name"].stringValue
        self.riderPhone = json["rider_phone"].stringValue
        self.createdAt = json["created_at"].stringValue
        self.found = json["item_found"].boolValue
        self.status = json["status"].stringValue
        
        if json["comments"].arrayValue.count > 0 {
            for comment in json["comments"].arrayValue {
                let c = Comment.init()
                c.body = comment["comment"].stringValue
                self.comments.append(c)
            }
        }
    }
}
