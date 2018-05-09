//
//  Equipment.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/15/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Equipment: Object {
    
    @objc dynamic var id: Int = 0
    @objc dynamic var name: String = ""
    @objc dynamic var vendorId: Int = 0
    @objc dynamic var delivered: Bool = false
    @objc dynamic var status: Int = 0
    @objc dynamic var createdAt: String = ""
    let scans = List<Scan>()
    @objc dynamic var assignedTo: String = ""
    @objc dynamic var assignedId: Int = 0
    @objc dynamic var assignedDate: String = ""
    @objc dynamic var type: String = "Radio"
    @objc dynamic var uid: String = ""
    
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
        self.id = json["id"].intValue
        self.name = json["name"].stringValue
        self.vendorId = json["vendor_id"].intValue
        self.delivered = json["delivered"].boolValue
        self.status = json["status"].intValue
        self.createdAt = json["created_at"].stringValue
    }
}
