//
//  Incident.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/21/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import SwiftyJSON
import CoreLocation

class Incident: Object {
    
    @objc dynamic var id: Int = 0
    @objc dynamic var incidentType: String = ""
    @objc dynamic var inventoryId: Int = 0
    @objc dynamic var departmentId: Int = 0
    @objc dynamic var departmentName: String = ""
    @objc dynamic var incidentDescription: String = ""
    @objc dynamic var createdAt: String = ""
    @objc dynamic var status: String = ""
    @objc dynamic var longitude: Double = 0.0
    @objc dynamic var latitude: Double = 0.0
    //dynamic var incidentCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
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
    
    init(json: JSON) {
        super.init()
        
        self.id = json["id"].intValue
        self.status = json["status"].stringValue
        self.createdAt = json["created_at"].stringValue
        self.departmentName = json["department"]["name"].stringValue
        
        if json["inventory_id"] != JSON.null {
            inventoryId = json["inventory_id"].intValue
        }
        
        if json["description"] != JSON.null {
            self.incidentDescription = json["description"].stringValue
        }
        
        if json["location"]["latitude"] != JSON.null && json["location"]["longitude"] != JSON.null {
            latitude = Double(json["location"]["latitude"].stringValue)!
            longitude = Double(json["location"]["longitude"].stringValue)!
        }
        
        for image in json["all_images"].arrayValue {
            let i = Media()
            i.imageUrl = image.stringValue
            images.append(i)
        }
        
        
        /*
        if json["latitude"] != JSON.null {
            latitude = Double(json["latitude"].stringValue)!
        }
        
        if json["longitude"] != JSON.null {
            longitude = Double(json["longitude"].stringValue)!
        }
        
        if json["quantity"] != JSON.null {
            self.fuelCount = json["quantity"].stringValue
        }
        */
        
        
    }
}
