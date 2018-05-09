//
//  AppSettings.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 3/27/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class AppSetting: Object {
    
    @objc dynamic var phoneNumber: String? = nil
    @objc dynamic var passengers: Bool = false
    @objc dynamic var setTour: Bool = false
    @objc dynamic var driverScan: Bool = false
    @objc dynamic var segmentIndex: Int = 0
    @objc dynamic var menuIndex: Int = 0
    
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
        self.phoneNumber = json["phone_number"].stringValue
        self.passengers = json["passengers"].boolValue
        self.setTour = json["set_tour"].boolValue
        self.driverScan = json["driver_scan"].boolValue
    }
}
