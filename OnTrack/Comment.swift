//
//  Comment.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/5/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//


import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Comment: Object {
    
    @objc dynamic var body: String = ""
    
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
