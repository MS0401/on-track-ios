//
//  InventoryType.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 11/30/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class InventoryType: Object {
    
    @objc dynamic var capacity: String = ""
    @objc dynamic var id: Int = 0
    @objc dynamic var companyId: Int = 0
    @objc dynamic var inventoryTypeCategoryId: Int = 0
    @objc dynamic var name: String = ""
    
    
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
        self.id = json["id"].intValue
    }
}
