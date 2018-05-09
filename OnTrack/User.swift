//
//  User.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 11/30/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class User: Object {
    
    @objc dynamic var email: String = ""
    @objc dynamic var cell: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var token: String = ""
    @objc dynamic var id: Int = 0
    @objc dynamic var role: String = "superAdmin"
    @objc dynamic var lastLocation: RealmLocation?
    
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
        self.cell = json["cell"].stringValue
        self.email = json["email"].stringValue
        self.name = json["name"].stringValue
        self.token = json["token"].stringValue
        self.id = json["id"].intValue
        self.role = "superAdmin"
    }
}
