//
//  Constants.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/23/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

let BASE_URL: String = "https://ontrackmanagement.herokuapp.com"
let BASE_URL_INVENTORY: String = "https://ontrackinventory.herokuapp.com"
//let BASE_URL: String = "https://ontrackdevelopment.herokuapp.com"
//let BASE_URL: String = "http://localhost:3000" //http://127.0.0.1:3000/events
let dayTime = currentUser!.day!.calendarDay

let driverTimer = Notification.Name("DriverTimer")
let staffTimer = Notification.Name("StaffTimer")

let baseColor = UIColor(red: 93/255, green: 75/255, blue: 153/255, alpha: 1.0)
let navBarColor = UIColor(red: 41/255, green: 50/255, blue: 65/255, alpha: 1.0)

//Add to extensions
func convertTime(dt: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    let d = dateFormatter.date(from: dt)
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: d!)
    let minute = calendar.component(.minute, from: d!)
    return "\(hour):\(minute)"
}

var appSetting: AppSetting? {
    get {
        let realm = try! Realm()
        let d = realm.objects(AppSetting.self).first
        if d != nil {
            return d!
        } else {
            return nil
        }
    }
}
