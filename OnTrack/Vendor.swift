//
//  Vendor.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 5/10/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Vendor: Object {
    
    @objc dynamic var name: String = ""
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
    
    init(json: JSON) {
        super.init()
        self.name = json["name"].stringValue
        self.id = json["id"].intValue
    }
}
