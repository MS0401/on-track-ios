//
//  Media.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/7/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Media: Object {
    
    @objc dynamic var imageUrl: String = ""
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
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    init(json: JSON) {
        super.init()
        
        //self.imageUrl = json[""]
    }
}
