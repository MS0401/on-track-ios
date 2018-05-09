//
//  Notification.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/6/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class RealmNotification: Object {
    
    @objc dynamic var reason: String = ""
    @objc dynamic var createdAt: String = ""
    @objc dynamic var driver: RealmDriver?
    @objc dynamic var routeName: String? = nil
    @objc dynamic var shiftName: String? = nil
    var routeId = RealmOptional<Int>()
    var shiftId = RealmOptional<Int>()
    var driverId = RealmOptional<Int>()
    
    required init() {
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
}


