//
//  Fuel.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/11/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Fuel: Object {
    
    @objc dynamic var name: String = ""
    @objc dynamic var total: Int = 0
    @objc dynamic var id: Int = 0
    
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
        self.total = json["stats"]["event_id_1"]["total_used"].intValue
        self.id = json["id"].intValue
    }
}
