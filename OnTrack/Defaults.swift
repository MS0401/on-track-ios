//
//  Defaults.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 3/27/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Defaults: Object {
    @objc dynamic var didWalkthrough = false
    @objc dynamic var cell: String? = nil
    
    required init() {
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    init(walk: Bool) {
        super.init()
        didWalkthrough = walk
    }
    
}
