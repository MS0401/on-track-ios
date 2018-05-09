//
//  Inventory.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/1/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import SwiftyJSON

class Inventory: Object {
    
    @objc dynamic var id: Int = 0
    @objc dynamic var uid: String = ""
    @objc dynamic var inventoryTypeId: Int = 0
    @objc dynamic var parentId: Int = 0
    @objc dynamic var rented: Bool = false
    @objc dynamic var name: String = ""
    @objc dynamic var departmentName: String = ""
    @objc dynamic var lastScan: InventoryScan?
    @objc dynamic var fuelType: String = ""
    @objc dynamic var fuelTypeId: Int = 0
    @objc dynamic var fuelQuantity: String = ""
    @objc dynamic var locationDescription: String = ""
    let scans = List<InventoryScan>()
    let accessories = List<Inventory>()
    let images = List<Media>()
    
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
        id = json["id"].intValue
        inventoryTypeId = json["inventory_type_id"].intValue
        name = json["name"].stringValue
        lastScan = InventoryScan(json: json["last_scan"])
        departmentName = json["department"]["name"].stringValue
        parentId = json["parent_id"].intValue
        //locationDescription = json["description"].stringValue
        
        
        
        if json["uid"] != JSON.null {
            uid = json["uid"].stringValue
        } else {
            //json["uid"] == JSON.null
        }
        
        if json["description"] != JSON.null {
            locationDescription = json["description"].stringValue
            print("from inventory model \(locationDescription)")
        }
        
        for scan in json["all_scans"].arrayValue {
            let s = InventoryScan(json: scan)
            scans.append(s)
        }
        
        for inventory in json["accessories"].arrayValue {
            let i = Inventory(json: inventory)
            if i.id != id {
                accessories.append(i)
            }
        }
        
        for image in json["all_images"].arrayValue {
            let i = Media()
            i.imageUrl = image.stringValue
            images.append(i)
        }
    }
}
