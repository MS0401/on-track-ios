//
//  Scan.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/8/16.
//  Copyright © 2016 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Scan: Object {
    @objc dynamic var reason: String? = nil
    @objc dynamic var latitude: Float = 0.0
    @objc dynamic var longitude: Float = 0.0
    @objc dynamic var comment: String? = nil
    @objc dynamic var created_at: String? = nil
    @objc dynamic var vehicle_id: Int = 0
    @objc dynamic var driver_id: Int = 0
    @objc dynamic var eventId: Int = 0
    @objc dynamic var routeId: Int = 0
    let scannerId = RealmOptional<Int>()
    @objc dynamic var scannerName: String? = nil //user who scanned driver
    @objc dynamic var driverName: String? = nil
    @objc dynamic var scanType: String? = nil
    @objc dynamic var equipmentStatus: String = ""
    @objc dynamic var fuelCount: String = ""
    
    required init() {
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    init(shiftJSON: JSON) {
        super.init()
        self.reason = shiftJSON["reason"].stringValue
        self.latitude = shiftJSON["latitude"].floatValue
        self.longitude = shiftJSON["longitude"].floatValue
    }
    
    init(json: JSON) {
        super.init()
        self.reason = json["reason"].stringValue
        self.latitude = json["latitude"].floatValue
        self.longitude = json["longitude"].floatValue
        self.comment = json["comment"].stringValue
        self.created_at = json["created_at"].stringValue
        
        if json["scanner_id"] != JSON.null {
            let jsonId = json["scanner_id"].intValue
            self.scannerId.value = jsonId
        }
        
        if json["scanner_name"] != JSON.null {
            self.scannerName = json["scanner_name"].stringValue
        }
        
        if json["driver_name"] != JSON.null {
            self.driverName = json["driver_name"].stringValue
        }
        
        if json["scanned_by"] != JSON.null {
            self.scannerName = json["scanned_by"].stringValue
        }
    }
    
    init(inventoryJson: JSON) {
        super.init()
        if inventoryJson["latitude"] != JSON.null {
            self.latitude = Float(inventoryJson["latitude"].stringValue)!
        }
        
        if inventoryJson["longitude"] != JSON.null {
            self.longitude = Float(inventoryJson["longitude"].stringValue)!
        }
        
        if inventoryJson["quantity"] != JSON.null {
            self.fuelCount = inventoryJson["quantity"].stringValue
        }

        self.created_at = inventoryJson["created_at"].stringValue
        self.reason = inventoryJson["scan_type"].stringValue
    }
    
    init(reason: String, latitude: Float, longitude: Float, comment: String, createdAt: String?) {
        super.init()
        self.reason = reason
        self.latitude = latitude
        self.longitude = longitude
        self.comment = comment
        //self.created_at = createdAt
    }
}
