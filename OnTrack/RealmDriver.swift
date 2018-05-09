//
//  RealmDriver.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/3/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class RealmDriver: Object {
    @objc dynamic var cell: String? = nil
    @objc dynamic var id: Int = 0
    @objc dynamic var route: RealmRoute?
    @objc dynamic var role: String? = nil
    @objc dynamic var lastLocation: RealmLocation?
    @objc dynamic var event_id: Int = 0
    var shiftId = RealmOptional<Int>()
    let scans = List<Scan>()
    let shifts = List<Shift>()
    let routes = List<RealmRoute>()
    let events = List<Event>()
    @objc dynamic var appSetting: AppSetting?
    @objc dynamic var vendor: Vendor?
    @objc dynamic var name: String = ""
    @objc dynamic var lastScan: Scan?
    @objc dynamic var day: Day?
    @objc dynamic var event: Event?
    @objc dynamic var loops: Int = 0
    let equipment = List<Equipment>()
    
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
    
    init(shiftJSON: JSON) {
        super.init()
        self.id = shiftJSON["id"].intValue
        self.name = shiftJSON["first_name"].stringValue + " " + shiftJSON["last_name"].stringValue
        self.lastScan = Scan(shiftJSON: shiftJSON["last_scan"])
    }
    
    init(json: JSON) {
        super.init()
        self.cell = json["cell"].stringValue
        self.id = json["id"].intValue
        self.role = json["role"].stringValue
        self.name = json["first_name"].stringValue + " " + json["last_name"].stringValue
    }
    
    init(routeJson: JSON) {
        super.init()
        if routeJson["driver"] != nil {
            self.cell = routeJson["driver"]["cell"].stringValue
            self.id = routeJson["driver"]["id"].intValue
            self.role = routeJson["driver"]["role"].stringValue
            self.name = routeJson["driver"]["first_name"].stringValue + " " + routeJson["driver"]["last_name"].stringValue
        } else {
            self.cell = routeJson["cell"].stringValue
            self.id = routeJson["id"].intValue
            self.role = routeJson["role"].stringValue
            self.name = routeJson["first_name"].stringValue + " " + routeJson["last_name"].stringValue
            self.loops = routeJson["loops"].intValue
        }
        
        let v = Vendor(json: routeJson["vendor"])
        if routeJson["vendor_name"] != nil {
            self.vendor?.name = routeJson["vendor_name"].stringValue
        }
        self.vendor = v
        
        let location = RealmLocation(json: routeJson["last_location"])
        self.lastLocation = location
        
        if routeJson["shift"] != JSON.null {
            let s = Shift(json: routeJson["shift"])
            self.shifts.append(s)
        }
        
        let scan = Scan.init(reason: routeJson["last_scan"]["reason"].stringValue, latitude: routeJson["last_scan"]["latitude"].floatValue, longitude: routeJson["last_scan"]["longitude"].floatValue, comment: "comment", createdAt: nil)
        
        if routeJson["last_scan"]["scanner_name"] != nil {
            scan.scannerName = routeJson["last_scan"]["scanner_name"].stringValue
        }
        
        self.lastScan = scan
        
        for scan in routeJson["scans"].arrayValue {
            let s = Scan(json: scan)
            scans.append(s)
        }
    }
    
    init(cell: String, id: Int) {
        super.init()
        self.cell = cell
        self.id = id
    }
}
