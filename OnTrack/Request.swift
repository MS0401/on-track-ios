//
//  Request.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/15/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import SwiftyJSON

class Request: Object {
    
    @objc dynamic var id: Int = 0
    @objc dynamic var date: String = ""
    @objc dynamic var requestType: String = ""
    @objc dynamic var userId: Int = 0
    @objc dynamic var status: String = ""
    @objc dynamic var vendorId: Int = 0
    
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
        self.date = json["date"].stringValue
        self.requestType = json["request_type"].stringValue
        self.userId = json["user_id"].intValue
        self.status = json["status"].stringValue
        self.vendorId = json["vendor_id"].intValue
    }
}
