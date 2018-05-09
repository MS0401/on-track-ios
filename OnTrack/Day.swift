//
//  Day.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/12/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Day: Object {
    @objc dynamic var calendarDay: String = ""
    
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
        self.calendarDay = json["calendar_day"].stringValue
    }
}
