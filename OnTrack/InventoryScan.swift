//
//  InventoryScan.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/1/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class InventoryScan: Object {
    
    @objc dynamic var id: Int = 0
    @objc dynamic var inventoryType: String = ""
    @objc dynamic var longitude: Double = 0.0
    @objc dynamic var latitude: Double = 0.0
    @objc dynamic var scanType: String = ""
    @objc dynamic var createdAt: String = ""
    @objc dynamic var fuelCount: String = ""
    @objc dynamic var accessoryId: Int = 0
    @objc dynamic var parentId: Int = 0
    
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
        print("from model \(json)")
    
        if json["location"]["latitude"] != JSON.null {
            latitude = Double(json["location"]["latitude"].stringValue)!
        }
        
        if json["location"]["longitude"] != JSON.null {
            longitude = Double(json["location"]["longitude"].stringValue)!
        }
        
        if json["quantity"] != JSON.null {
            self.fuelCount = json["quantity"].stringValue
        }
        
        id = json["id"].intValue
        //inventoryType = json["inventory_type"].stringValue
        scanType = json["scan_type"].stringValue
        
        //if json["created_at"] != JSON.null {
            createdAt = json["location"]["created_at"].stringValue
        //} else {
            //createdAt = "No Date Info"
        //}
    
        if json["accessory_id"] != JSON.null {
            accessoryId = json["accessory_id"].intValue
        }
        
        if json["parent_id"] != JSON.null {
            parentId = json["parent_id"].intValue
        }
    }
}

