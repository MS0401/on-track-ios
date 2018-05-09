//
//  RealmManager.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import RealmSwift

class RealmManager: NSObject {
    
    static let shared = RealmManager()
    let realm = try! Realm()
    
    func realmLocation(currentUser: RealmDriver, latitude: Float, longitude: Float, batteryLevel: Float) {
        let location = RealmLocation()
        location.driver_id = currentUser.id
        location.latitude = latitude
        location.longitude = longitude
        location.battery_level.value = batteryLevel
        
        //print(location)
        
        try! realm.write {
            if self.realm.objects(RealmLocation.self).first != nil {
                self.realm.delete(self.realm.objects(RealmLocation.self))
            }
            realm.add(location)
            currentUser.lastLocation = location
        }
    }
    
    func realmLocationUser(currentUser: User, latitude: Float, longitude: Float, batteryLevel: Float) {
        let location = RealmLocation()
        location.driver_id = currentUser.id
        location.latitude = latitude
        location.longitude = longitude
        location.battery_level.value = batteryLevel
        
        //print(location)
        
        try! realm.write {
            if self.realm.objects(RealmLocation.self).first != nil {
                self.realm.delete(self.realm.objects(RealmLocation.self))
            }
            realm.add(location)
            currentUser.lastLocation = location
        }
    }
}
