//
//  MessageGroup.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/24/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class MessageGroup: Object {
    
    @objc dynamic var name: String = ""
    @objc dynamic var messageType: String = ""
    @objc dynamic var groupType: String = ""
    var groupId = RealmOptional<Int>()
    var memberCount = RealmOptional<Int>()
    
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
