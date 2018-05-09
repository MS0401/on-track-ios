//
//  APIManager.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/23/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import RealmSwift
import SwiftDate

class APIManager: NSObject {
    
    static let shared = APIManager()
    let baseURL = NSURL(string: BASE_URL)
    let realm = try! Realm()
    
    //App Settings
    func getSettings() {
       Alamofire.request(Router.getSettings).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                print(jsonObject)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    //TODO: Separate getUser and createPin
    func createPin(phoneNumber: String, completion: @escaping (_ object: JSON) -> ()) {
        Alamofire.request(Router.createPin(phoneNumber: phoneNumber)).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                completion(jsonObject as! JSON)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    //TODO: url encode breaking on router
    func verifyCode(_ cell: String, code: String,
                    completion: @escaping (_ response: DataResponse<Any>, _ error: Error?) -> ()) {
        
        let url = "\(BASE_URL)/api/v1/drivers/\(cell)/verify?pin=\(code)"
        let headers = [
            "Content-Type": "application/json"
        ]
        print(url)
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                
                if response.response?.statusCode == 422 {
                    completion(response, nil)
                } else {
                    let json = JSON(jsonObject)
                    //print(json)
                    
                    let jsonEvent = json.arrayValue[0]["event"]
                    let jsonDays = json.arrayValue[0]["event_days"]
                    let jsonDriver = json.arrayValue[1]["driver"]
                    let jsonVendor = json.arrayValue[2]["vendor"]
                    let scans = json.arrayValue[3]["scans"].arrayValue
                    let route = json.arrayValue[5]["route"]
                    let zones = json.arrayValue[6]["zones"].arrayValue
                    let shifts = json.arrayValue[7]["shifts"].arrayValue
                    let shiftTimes = json.arrayValue[7]["shift_times"].arrayValue
                    let appSetting = json.arrayValue[8]["app"]
                    let jsonEvents = json.arrayValue[9]["events"].arrayValue
                    
                    try! self.realm.write {
                        
                        if self.realm.objects(RealmDriver.self).first != nil {
                            self.realm.deleteAll()
                        }
                        
                        let driver = RealmDriver(json: jsonDriver)
                        
                        
                        /*
                        let event = Event(json: jsonEvent)
                        driver.event = event
                        
                        let r = RealmRoute(driverJSON: route)
                        driver.event?.routes.append(r)
                        */
                        
                        if driver.role != "admin" {
                            
                            let event = Event(json: jsonEvent)
                            driver.event = event
                            
                            for day in jsonDays.arrayValue {
                                let d = Day(json: day)
                                event.days.append(d)
                            }
                            
                            driver.day = (event.days.first)!
                            let vendor = Vendor(json: jsonVendor)
                            
                            
                            let r = RealmRoute(driverJSON: route)
                            r.assignedRoute = true
                            driver.route = r
                            driver.event_id = route["event_id"].intValue
                            driver.appSetting = AppSetting.init(json: appSetting)
                            driver.vendor = vendor
                            driver.event?.routes.append(r)
                            
                            if zones.count > 0 {
                                for zone in zones {
                                    let z = Zone(json: zone)
                                    driver.route?.zones.append(z)
                                    driver.event?.zones.append(z)
                                }
                            }
                            
                            if scans.count > 0 {
                                for scan in scans {
                                    let s = Scan.init(reason: scan["reason"].stringValue, latitude: scan["latitude"].floatValue, longitude: scan["longitude"].floatValue, comment: scan["comment"].stringValue, createdAt: scan["created_at"].stringValue)
                                    driver.scans.append(s)
                                }
                            }
                            
                            if shifts.count > 0 {
                                for shift in shifts {
                                    let s = Shift.init(id: shift["id"].intValue, name: shift["name"].stringValue, routeId: shift["route_id"].intValue, eventId: shift["event_id"].intValue)
                                    
                                    for time in shiftTimes {
                                        let t = ShiftTime(name: time["name"].stringValue, time: time["day_time"].stringValue, shiftId: time["shift_id"].intValue)
                                        t.comment = time["comment"].stringValue
                                        t.scanType = time["scan_type"].stringValue
                                        if t.shiftId == s.id {
                                            //print(t)
                                            s.times.append(t)
                                        }
                                    }
                                    if s.eventId == driver.event?.eventId {
                                        driver.shifts.append(s)
                                        driver.event?.waves.append(s)
                                    }
                                }
                            }
                        } else {
                            for event in jsonEvents {
                                let e = Event(json: event)
                                let find = self.realm.objects(Event.self).filter("eventId == \(e.eventId)").first
                                if find == nil {
                                    driver.events.append(e)
                                }
                            }
                        }
                        
                        self.realm.add(driver, update: true)
                        let appSet = AppSetting()
                        self.realm.add(appSet)
                    }
                }
                completion(response, nil)
            case .failure(let error):
                print(error)
                completion(response, error)
            }
        }
    }
    
    func verifyUserCell(_ phoneNumber: String, completion: @escaping (_ response: DataResponse<Any>, _ error: Error?) -> ()) {
        Alamofire.request(Router.getUser(phoneNumber: phoneNumber)).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                _ = JSON(jsonObject)
                /*
                let role = json.arrayValue[1]["driver"]["role"].stringValue
                
                if role == "driver" {
                //print(json)
                
                    let jsonEvent = json.arrayValue[0]["event"]
                    let jsonDays = json.arrayValue[0]["event_days"]
                    let jsonDriver = json.arrayValue[1]["driver"]
                    let jsonVendor = json.arrayValue[2]["vendor"]
                    let scans = json.arrayValue[3]["scans"].arrayValue
                    let route = json.arrayValue[5]["route"]
                    let zones = json.arrayValue[6]["zones"].arrayValue
                    let shifts = json.arrayValue[7]["shifts"].arrayValue
                    let shiftTimes = json.arrayValue[7]["shift_times"].arrayValue
                    let appSetting = json.arrayValue[8]["app"]
                    let jsonEvents = json.arrayValue[9]["events"].arrayValue

                    try! self.realm.write {
                        
                        if self.realm.objects(RealmDriver.self).first != nil {
                            self.realm.deleteAll()
                        }
                        
                        let driver = RealmDriver(json: jsonDriver)
                        
                        for event in jsonEvents {
                            let e = Event(json: event)
                            driver.events.append(e)
                        }
                        
                        if driver.role != "admin" {
                            
                            let event = Event(json: jsonEvent)
                            
                            for day in jsonDays.arrayValue {
                                let d = Day(json: day)
                                event.days.append(d)
                            }
                            
                            driver.day = (event.days.first)!
                            let vendor = Vendor(json: jsonVendor)
                            
                            
                            let r = RealmRoute(driverJSON: route)
                            r.assignedRoute = true
                            driver.route = r
                            driver.event_id = route["event_id"].intValue
                            driver.appSetting = AppSetting.init(json: appSetting)
                            driver.vendor = vendor
                        
                            if zones.count > 0 {
                                for zone in zones {
                                    let z = Zone(json: zone)
                                    driver.route?.zones.append(z)
                                }
                            }
                            
                            if scans.count > 0 {
                                for scan in scans {
                                    let s = Scan.init(reason: scan["reason"].stringValue, latitude: scan["latitude"].floatValue, longitude: scan["longitude"].floatValue, comment: scan["comment"].stringValue, createdAt: scan["created_at"].stringValue)
                                    driver.scans.append(s)
                                }
                            }
                            
                            if shifts.count > 0 {
                                for shift in shifts {
                                    let s = Shift.init(id: shift["id"].intValue, name: shift["name"].stringValue, routeId: shift["route_id"].intValue, eventId: shift["event_id"].intValue)
                                    
                                    for time in shiftTimes {
                                        let t = ShiftTime(name: time["name"].stringValue, time: time["day_time"].stringValue, shiftId: time["shift_id"].intValue)
                                        t.comment = time["comment"].stringValue
                                        t.scanType = time["scan_type"].stringValue
                                        if t.shiftId == s.id {
                                            //print(t)
                                            s.times.append(t)
                                        }
                                    }
                                    driver.shifts.append(s)
                                }
                            }
                        }
                        
                        self.realm.add(driver, update: true)
                    }
                }
                */
                completion(response, nil)
                
            case .failure(let error):
                completion(response, error)
            }
        }
    }
    
    func getEvent(eventId: Int) {
        
        let path = "\(BASE_URL)/api/v1/events/\(eventId).json"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonDays = json["days"].arrayValue
                let jsonRoutes = json["routes"].arrayValue
                let jsonZones = json["zones"].arrayValue
                let jsonWaves = json["waves"].arrayValue
                let jsonEventId = json["event"]["id"].intValue
                let event = self.realm.objects(Event.self).filter("eventId == \(jsonEventId)").first
                
                let realmDays = self.realm.objects(Day.self)
                try! self.realm.write {
                    self.realm.delete(realmDays)
                }
                
                for day in jsonDays {
                    let d = Day()
                    d.calendarDay = day["calendar_day"].stringValue
                    
                    try! self.realm.write {
                        event?.days.append(d)
                    }
                }
                
                let realmRoutes = self.realm.objects(RealmRoute.self)
                try! self.realm.write {
                    self.realm.delete(realmRoutes)
                }
                for route in jsonRoutes {
                    let r = RealmRoute()
                    r.id = route["id"].intValue
                    r.name = route["name"].stringValue
                    
                    try! self.realm.write {
                        event?.routes.append(r)
                    }
                }
                
                let realmZones = self.realm.objects(Zone.self)
                try! self.realm.write {
                    self.realm.delete(realmZones)
                }
                
                for zone in jsonZones {
                    let z = Zone(json: zone)
                    
                    try! self.realm.write {
                        event?.zones.append(z)
                    }
                }
                
                let realmWaves = self.realm.objects(Shift.self)
                let realmShiftTimes = self.realm.objects(ShiftTime.self)
                try! self.realm.write {
                    self.realm.delete(realmWaves)
                    self.realm.delete(realmShiftTimes)
                }
                for wave in jsonWaves {
                    let w = Shift(json: wave["wave"])
                    //w.id = wave["id"].intValue
                    //w.name = wave["name"].stringValue
                    //w.routeId = wave["route_id"].intValue
                    //w.eventId = wave["event_id"].intValue
                    
                    try! self.realm.write {
                        event?.waves.append(w)
                    }
                    
                    for st in wave["shift_times"].arrayValue {
                        let s = ShiftTime(json: st)
                        
                        try! self.realm.write {
                            w.times.append(s)
                        }
                    }
                    
                    try! self.realm.write {
                        event?.waves.append(w)
                    }
                    
                    
                }
                
                for r in (event?.routes)! {
                    for z in (event?.zones)! {
                        if z.route_id == r.id {
                            try! self.realm.write {
                                r.zones.append(z)
                            }
                        }
                    }
                }
                
                try! self.realm.write {
                    currentUser?.route = event?.routes.first
                }
                
            case .failure:
                break
            }
        }
    }
    
    func getDrivers(roles: [String], completion: @escaping (_ drivers: [RealmDriver]) -> ()) {
        //api/v1/events/1/staff_members?roles=['driver', 'admin']
        //let progressView = ACProgressHUD.shared
        //progressView.progressText = "Updating Drivers..."
        //progressView.showHUD()
        
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event!.eventId)/staff_members"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let parameters = [
            "roles": roles
        ]
        
        Alamofire.request(path, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let data = json["data"].arrayValue
                var drivers = [RealmDriver]()
                
                for driver in data {
                    let d = RealmDriver()
                    d.id = driver["id"].intValue
                    d.name = "\(driver["first_name"].stringValue) \(driver["last_name"].stringValue)"
                    d.cell = driver["cell"].stringValue
                    
                    let v = Vendor()
                    v.name = driver["vendor_name"].stringValue
                    d.vendor = v
                    
                    for s in driver["shifts"].arrayValue {
                        let shift = Shift()
                        shift.id = s["id"].intValue
                        shift.routeId = s["route_id"].intValue
                        shift.name = s["name"].stringValue
                        shift.eventId = (currentUser?.event?.eventId)!
                        d.shifts.append(shift)
                    }
                    drivers.append(d)
                }
                //progressView.hideHUD()
                
                completion(drivers)
            case .failure:
                break
            }
        }
    }
    
    func getDriverInfo(eventId: Int, shiftId: Int, driverId: Int, completion: @escaping (_ driver: RealmDriver) -> ()) {
        
        let path = "\(BASE_URL)/api/v1/events/\(eventId)/shifts/\(shiftId)/drivers/\(driverId).json?day=\((currentUser!.day!.calendarDay))"
        print(path)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                
                let driver = RealmDriver(routeJson: json)
                print(json)
                completion(driver)
            case .failure:
                break
            }
        }
    }
    
    func getAllRoutes(eventId: Int, completion: @escaping (_ routes: [RealmRoute]) -> ()) {
        let path = "\(BASE_URL)/api/v1/routes/all_routes.json?event_id=\(eventId)"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            //print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonRoutes = json["routes"].arrayValue
                var routes = [RealmRoute]()
                for route in jsonRoutes {
                    let r = RealmRoute(json: route)
                    routes.append(r)
                }
                completion(routes)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }

    }
    
    func getStaffDetail(_ eventId: Int, _ shiftId: Int, _ driverId: Int, _ completion: @escaping (_ driver: RealmDriver) -> ()) {
        let path = "\(BASE_URL)/api/v1/events/\(eventId)/shifts/\(shiftId)/drivers/\(driverId)/staff_member.json?day=\(currentUser!.day!.calendarDay)"
        
        print(path)
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            //print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let d = RealmDriver(json: json["driver"])
                let l = RealmLocation(json: json["last_location"])
                d.lastLocation = l
                let scans = json["scans"].arrayValue
                for scan in scans {
                    let s = Scan(json: scan)
                    d.scans.append(s)
                }
                completion(d)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func getAllStaffMembers(roles: [String], completion: @escaping (_ drivers: [RealmDriver]) -> ()) {
        
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event!.eventId)/staff_members"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let parameters = [
            "roles": roles
        ]
        
        Alamofire.request(path, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let data = json["data"].arrayValue
                var drivers = [RealmDriver]()
                
                for driver in data {
                    let d = RealmDriver()
                    d.id = driver["id"].intValue
                    d.name = "\(driver["first_name"].stringValue) \(driver["last_name"].stringValue)"
                    d.role = driver["role"].stringValue
                    d.cell = driver["cell"].stringValue
                    
                    let v = Vendor()
                    v.name = driver["vendor_name"].stringValue
                    d.vendor = v
                    
                    for s in driver["shifts"].arrayValue {
                        let shift = Shift()
                        shift.id = s["id"].intValue
                        shift.routeId = s["route_id"].intValue
                        shift.name = s["name"].stringValue
                        shift.eventId = (currentUser?.event?.eventId)!
                        d.shifts.append(shift)
                    }
                    drivers.append(d)
                }
                
                completion(drivers)
            case .failure:
                break
            }
        }
    }

    
    func getAllRoutes(completion: @escaping ([RealmRoute], [String: Int]) -> ()) {
        let path = "\(BASE_URL)/api/v1/routes.json?event_id=\(currentUser!.event_id)&day=\(currentUser!.day!.calendarDay)"
        print(path)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let outOfService = json["out_of_service_drivers"].intValue
                let onBreak = json["on_break_drivers"].intValue
                let checkedIn = json["checked_in_drivers"].intValue
                let totalDrivers = json["total_drivers"].intValue
                
                let statsDict = ["out_of_service_drivers": outOfService, "on_break_drivers": onBreak,
                                 "checked_in_drivers": checkedIn, "total_drivers": totalDrivers] as [String : Int]
                var routes = [RealmRoute]()
                
                routes.removeAll()
                for route in json["routes"].arrayValue {
                    let r = RealmRoute(routeJSON: route)
                    routes.append(r)
                }
                
                completion(routes, statsDict)
            case .failure:
                break
            }
        }
    }
    
    func getStats(completion: @escaping ([[DateInRegion: Int]], _ num: Int, _ ingress: [[DateInRegion: Int]], _ egress: [[DateInRegion: Int]], _ items: [String], _ routes: [RealmRoute]) -> ()) {
        
        //https://ontrackmanagement.herokuapp.com/api/v1/events/1/ridership.json?day=2017-07-21&type=total
        //https://ontrackmanagement.herokuapp.com/api/v1/events/1/ridership.json?day=2017-07-21&type=ingress
        //https://ontrackmanagement.herokuapp.com/api/v1/events/1/ridership.json?day=2017-07-21&type=egress
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event!.eventId)/ridership.json?day=\(currentUser!.day!.calendarDay)&type=total"
        print(path)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            var scans = [[DateInRegion: Int]]()
            var ingress = [[DateInRegion: Int]]()
            var egress = [[DateInRegion: Int]]()
            var routes = [RealmRoute]()
            var items = ["All Routes"]
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let routesRiders = json["data"]["routes_riderships"].dictionaryValue
                for r in routesRiders {
                    let route = RealmRoute()
                    route.id = Int(r.key)!
                    route.name = r.value["name"].stringValue
                    route.ridershipCount.value = r.value["ridership_counts"].intValue
                    
                    items.append(route.name!)
                    
                    let jsonScans = r.value["scans"].arrayValue
                    
                    for s in jsonScans {
                        var dict = [DateInRegion: Int]()
                        let time = DateInRegion(string: s[2].stringValue, format: DateFormat.iso8601Auto)
                        dict = [time!: s[0].intValue]
                        scans.append(dict)
                        
                        if s[1] == false {
                            egress.append(dict)
                        } else {
                            ingress.append(dict)
                        }
                    }
                    
                    routes.append(route)
                }
                
                let number = json["data"]["ridership_counts"].intValue
                
                /*
                 let scs = json["scan"].arrayValue
                 
                 for s in scs {
                 var dict = [DateInRegion: Int]()
                 let time = DateInRegion(string: s[0].stringValue, format: DateFormat.iso8601Auto)
                 dict = [time!: s[1].intValue]
                 scans.append(dict)
                 
                 if s[2] == false {
                 egress.append(dict)
                 } else {
                 ingress.append(dict)
                 }
                 }
                 */
                
                completion(scans, number, ingress, egress, items, routes)
            case .failure:
                break
            }
        }
    }
    
    func getStats(day: String, shifts: [Int], routes: [Int], type: String, completion: @escaping ([RealmDriver]) -> ()) {
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event_id)/drivers.json"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        //{day: "18-06-2017", filters: {shifts: [1,2,3], routes: [1], type: "checked_in"}}
        //missing, checked_in, on_break or out_of_service
        let parameters = [
            "day": day,
            "filters": ["shifts": shifts, "routes": routes, "type": type]
            ] as [String : Any]
        
        Alamofire.request(path, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { response in
            
            var drivers = [RealmDriver]()
            drivers.removeAll()
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
               
                let jsonDrivers = json["data"]["drivers"].arrayValue
                for driver in jsonDrivers {
                    let d = RealmDriver()
                    d.cell = driver["cell"].stringValue
                    d.id = driver["id"].intValue
                    d.name = "\(driver["first_name"]) \(driver["last_name"])"
                    d.role = driver["shift_name"].stringValue
                    
                    let vendor = Vendor()
                    vendor.name = driver["vendor_name"].stringValue
                    d.vendor = vendor
                    
                    let scan = Scan()
                    scan.latitude = driver["last_scan"]["latitude"].floatValue
                    scan.longitude = driver["last_scan"]["longitude"].floatValue
                    scan.reason = driver["last_scan"]["reason"].stringValue
                    scan.scannerName = driver["last_scan"]["scanned_by"].stringValue
                    
                    d.lastScan = scan
                    
                    let s = Shift()
                    s.id = driver["shift_id"].intValue
                    s.eventId = (currentUser?.event?.eventId)!
                    
                    //Remove this is a test
                    //Need from json
                    s.routeId = (currentUser?.route?.id)!
                    
                    d.shifts.append(s)
                    drivers.append(d)
                }
                completion(drivers)
            case .failure:
                break
            }
        }
    }
    
    func getNotifications(completion: @escaping ([RealmNotification]) -> ()) {
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event!.eventId)/notifications.json"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                var notifications = [RealmNotification]()
                let json = JSON(jsonObject)
                
                for notification in json.arrayValue {
                    let n = RealmNotification.init()
                    n.reason = notification["notification"]["reason"].stringValue
                    n.createdAt = notification["notification"]["created_at"].stringValue
                    n.driverId.value = notification["notification"]["driver_id"].intValue
                    n.routeId.value = notification["notification"]["route_id"].intValue
                    n.shiftId.value = notification["notification"]["shift_id"].intValue
                    n.routeName = notification["notification"]["route_name"].stringValue
                    n.shiftName = notification["notification"]["shift_name"].stringValue
                    n.driver = RealmDriver(json: notification["driver"])
                    n.driver?.id = n.driverId.value!
                    notifications.append(n)
                }
                completion(notifications)
            case .failure:
                break
            }
        }
    }
    
    func getStatistics(day: String, shifts: [Int], routes: [Int], type: String, completion: @escaping ([RealmDriver]) -> ()) {
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event_id)/drivers.json"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        //{day: "18-06-2017", filters: {shifts: [1,2,3], routes: [1], type: "checked_in"}}
        //missing, checked_in, on_break or out_of_service
        let parameters = [
            "day": day,
            "filters": ["shifts": shifts, "routes": routes, "type": type]
            ] as [String : Any]
        
        print(parameters)
        
        print(path)
        
        Alamofire.request(path, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { response in
            
            var drivers = [RealmDriver]()
            drivers.removeAll()
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonDrivers = json["data"]["drivers"].arrayValue
                
                for driver in jsonDrivers {
                    let d = RealmDriver()
                    d.cell = driver["cell"].stringValue
                    d.id = driver["id"].intValue
                    d.name = "\(driver["first_name"]) \(driver["last_name"])"
                    d.role = driver["shift_name"].stringValue
                    
                    let s = Shift()
                    s.id = driver["shift_id"].intValue
                    s.eventId = (currentUser?.event?.eventId)!
                    
                    //Remove this is to prevent issue
                    //Need from JSON
                    s.routeId = (currentUser?.route?.id)!
                    
                    //print(driver["last_scan"])
                    let vendor = Vendor()
                    vendor.name = driver["vendor_name"].stringValue
                    d.vendor = vendor
                    
                    let scan = Scan()
                    scan.latitude = driver["last_scan"]["latitude"].floatValue
                    scan.longitude = driver["last_scan"]["longitude"].floatValue
                    scan.reason = driver["last_scan"]["reason"].stringValue
                    scan.scannerName = driver["last_scan"]["scanned_by"].stringValue
                    
                    d.lastScan = scan
                    //d.scans.append(scan)
                    
                    d.shifts.append(s)
                    drivers.append(d)
                }
                completion(drivers)
            case .failure:
                break
            }
        }
    }
    
    func getShiftStats(eventId: Int, routeId: Int, shiftId: Int, completion: @escaping ([RealmDriver], [String: Int]) -> ()) {
        
        let path = "\(BASE_URL)/api/v1/events/\(eventId)/routes/\(routeId)/shifts/\(shiftId).json?day=\(currentUser!.day!.calendarDay)"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        print(path)
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let outOfService = json["out_of_service_drivers"].intValue
                let onBreak = json["on_break_drivers"].intValue
                let checkedIn = json["checked_in_drivers"].intValue
                let totalDrivers = json["total_drivers"].intValue
                let statsDict = ["out_of_service_drivers": outOfService, "on_break_drivers": onBreak,
                                 "checked_in_drivers": checkedIn, "total_drivers": totalDrivers] as [String : Int]
                var drivers = [RealmDriver]()
                
                drivers.removeAll()
                for driver in json["shift_all_drivers"].arrayValue {
                    let d = RealmDriver(routeJson: driver)
                    let name = driver["vendor_name"].stringValue
                    d.vendor?.name = name
                    drivers.append(d)
                }
                
                completion(drivers, statsDict)
            case .failure:
                break
            }
        }
    }

    
    ///api/v1/events/1/messages.json last 30 messages received
    /*
     1) API to list all message groups of an event.
     GET `/api/v1/events/:event_id/message_groups`
     2) API to list last 30 messages of particular message group
     GET `/api/v1/events/:event_id/message_groups/:id: `
     3) API to send a message to a message group
     POST `/api/v1/events/:event_id/message_groups/:id/send_message`
     in last api you need to send 2 parameters
     `{event_id: 1, body: ""}`
     */
    
    func getMessages(completion: @escaping (_ messages: [[String: Any]]) -> ()) {
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event_id)/messages.json"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonMessages = json["messages"].arrayValue
                var messages = [[String: Any]]()
                
                for message in jsonMessages {
                    let dict = ["driverId": message["driver_id"].intValue,
                                "driverName": message["driver_name"].stringValue,
                                "body": message["body"].stringValue,
                                "createdAt": message["created_at"].stringValue, "from": message["from_number"].stringValue,
                                "routeName": message["route_name"].stringValue, "shiftName": message["shift_name"].stringValue,
                                "lastScan": message["last_scan"]["reason"].stringValue, "id": message["id"].intValue,
                                "unread": message["unread"].boolValue] as [String: Any]
                    
                    messages.append(dict)
                }
                completion(messages)
            case .failure:
                break
            }
        }
    }
    
    func getMessageGroups(completion: @escaping (_ groups: [MessageGroup]) -> ()) {
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event_id)/message_groups"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonGroups = json["data"].arrayValue
                var groups = [MessageGroup]()
                for group in jsonGroups {
                    let g = MessageGroup()
                    g.groupId.value = group["id"].intValue
                    g.memberCount.value = group["group_members_count"].intValue
                    g.name = group["name"].stringValue
                    g.messageType = group["message_group_type"].stringValue
                    g.groupType = group["group_type"].stringValue
                    groups.append(g)
                }
                groups.reverse()
                
                completion(groups)
            case .failure:
                break
            }
        }
    }


    //Driver
    func getDriver(_ driverId: Int, completion: @escaping (_ driver: RealmDriver) -> ()) {
        Alamofire.request(Router.getDriver(driverId: driverId)).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                //let location = json["location"]
                //let messages = json["messages"]
                //let vendor = json["vendor"]
                //let scans = json["scans"]
                //let driver = json["driver"]
                let d = RealmDriver(routeJson: json)
                //let zones = json["zones"]
                //let route = json["route"]
                completion(d)
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func getStaff(completion: @escaping (_ drivers: [RealmDriver], _ error: Error?) -> ()) {
        Alamofire.request(Router.getStaff).responseJSON { response in
            var drivers = [RealmDriver]()
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonDrivers = json["drivers"].arrayValue
                
                for driver in jsonDrivers {
                    let d = RealmDriver(json: driver["driver"])
                    let s = Scan(json: driver["last_scan"])
                    d.lastScan = s
                    drivers.append(d)
                }
                completion(drivers, nil)
            case .failure(let error):
                completion(drivers, error)
            }
        }
    }
    
    func getStaffMember(_ eventId: Int, _ shiftId: Int, _ driverId: Int, _ completion: @escaping (_ driver: RealmDriver) -> ()) {
        
        Alamofire.request(Router.getStaffMember(eventId: eventId, shiftId: shiftId, driverId: driverId)).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                var driver: RealmDriver!
                let json = JSON(jsonObject)
                let d = RealmDriver(json: json["driver"])
                let l = RealmLocation(json: json["location"])
                d.lastLocation = l
                let scans = json["scans"].arrayValue
                for scan in scans {
                    let s = Scan(json: scan)
                    d.scans.append(s)
                }
                driver = d
                completion(driver)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
    }

    //MARK: Locations
    func getLastLocation(_ driver: Int, _ completion: @escaping (_ location: Location) -> ()) {
        Alamofire.request(Router.getLastLocation(driverId: driver)).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                var location: Location!
                let json = JSON(jsonObject)
                let jsonLocation = json["location"]
                location = Location(json: jsonLocation)
                completion(location)
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    //Text Messages 
    //Working
    func postText(body: String, from_number: String, event_id: Int, route_id: Int, completion: @escaping (_ object: JSON) -> ()) {
        let parameters: Parameters = [
            "message": [
                "body": body,
                "from_number": from_number,
                "event_id": event_id,
                "route_id": route_id
            ]
        ]
        
        Alamofire.request(Router.postText(parameters: parameters)).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                completion(jsonObject as! JSON)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func getCheckedins() {
        let parameters: Parameters = [
            "day": "2017-07-12",
            "filters": ["shifts": [1], "routes": [1], "type": "checked_in"]
            ]
        
        Alamofire.request(Router.getCheckedIn(parameters: parameters)).responseJSON { response in
            //print(response)
        }
    }
    
    // Notifications
    //Not working with Router
    func postNotification(reason: Int, latitude: Float, longitude: Float, driver_id: Int, phone_number: String, event_id: Int, changeRouteId: Int?, completion: @escaping (_ error: Error?) -> ()) {
        let path = "api/v1/notifications"
        let url = baseURL!.appendingPathComponent(path)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "driver_id": driver_id,
            "latitude": latitude,
            "longitude": longitude,
            "reason": reason,
            "phone_number": phone_number,
            "event_id": event_id,
            "change_route_id": changeRouteId != nil ? changeRouteId! : 0
        ]
        
        Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
                break
            }
        }
    }
    
    //Locations
    //Not working with router
    func postLocation(eventId: Int, driverId: Int, lat: Float, long: Float, course: Float?, speed: Float?, load_arrival: Int?, drop_arrival: Int?, battery_level: Float) {
        
        let path = "api/v1/locations.json"
        let url = baseURL!.appendingPathComponent(path)
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "event_id": eventId,
            "driver_id": driverId,
            "latitude": lat,
            "longitude": long,
            "course": course,
            "speed": speed,
            "load_arrival": load_arrival,
            "drop_arrival": drop_arrival,
            "battery_level": battery_level
        ]
        
        Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
        }
    }
    
    func getLocations() {
        
        Alamofire.request(Router.getLocations).responseJSON { response in }
    }
    
    //Routes
    func getRoutes(_ eventId: Int, completion: @escaping () -> ()) {
        //let path = "api/v1/routes?event_id=\(eventId)"
        let url = "\(BASE_URL)/api/v1/routes.json?event_id=\(eventId)"
        print(url)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            //print(response)
        //Alamofire.request(Router.getRoutes).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(json)
                let routes = json["routes"].arrayValue
                let assignedRoute = self.realm.objects(RealmRoute.self).filter("assignedRoute = true").first
                
                for route in routes {
                    let r = RealmRoute(json: route)
                    if r.id == assignedRoute?.id {
                        
                    } else {
                        try! self.realm.write {
                            self.realm.add(r, update: true)
                        }
                    }
                }
                completion()
            case .failure:
                break
            }
        }
    }
    
    func getZones(_ eventId: Int, completion: @escaping (_ zones: [Zone]) -> ()) {
        let url = "\(BASE_URL)/api/v1/zones.json?event_id=\(eventId)"
        let headers = [
            "Content-Type": "application/json"
        ]

        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonZones = json["zones"].arrayValue
                var zones = [Zone]()
                for zone in jsonZones {
                    let z = Zone(json: zone)
                    zones.append(z)
                    try! self.realm.write {
                        self.realm.add(z, update: true)
                    }
                }
                completion(zones)
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }

    }
    
    //Scan
    func postScan(_ vehicle: Int, comment: String, reason: Int, lat: Float, long: Float) {
        let path = "api/v1/scans"
        let url = baseURL!.appendingPathComponent(path)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "vehicle_id": vehicle,
            "reason": reason,
            "comment": comment,
            "latitude": lat,
            "longitude": long
        ]
        
        Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).response { response in }
    }
    
    func postDriverScan(_ driver: Int, comment: String, reason: Int, lat: Float, long: Float, eventId: Int, routeId: Int, passengerCount: Int?, scannerId: Int, scanType: String, ingress: Bool?, shiftId: Int?, completion: @escaping (_ error: Error?) -> ()) {
        
        let path = "api/v1/scans"
        let url = baseURL!.appendingPathComponent(path)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "driver_id": driver,
            "reason": reason,
            "comment": comment,
            "latitude": lat,
            "longitude": long,
            "event_id": eventId,
            "route_id": routeId,
            "passenger_count": passengerCount != nil ? passengerCount! : 0,
            "scanner_id": scannerId,
            "scan_type": scanType,
            "ingress": ingress,
            "shift_id": shiftId
        ]
        
        Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    func bulkScan(_ scans: [[String: Any]]) {
        
        let path = "api/v1/scans"
        let url = baseURL!.appendingPathComponent(path)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        
        let parameters: Parameters = [
            "scans": scans
        ]
        
        Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
        }
    }
    
    //Messages
    ///api/v1/events/:event_id/driver_messages/:id 
    func getMessages(_ driverId: Int, completion: @escaping (_ messages: [Message]) -> ()) {
        Alamofire.request(Router.getMessages(driverId: driverId)).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonMessages = json["messages"]
                var messages = [Message]()

                for message in jsonMessages.arrayValue {
                    let m = Message(json: message)
                    m.eventId = message["event_id"].intValue
                    m.id = message["id"].intValue
                    
                    if m.eventId == currentUser?.event?.eventId {
                        messages.append(m)
                    }
                }
                completion(messages)
            case .failure:
                break
            }
        }
    }
    
    func postMessage(body: String, phoneNumber: String, eventId: Int, routeId: Int) {
        let path = "messages"
        let url = baseURL!.appendingPathComponent(path)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "body": body,
            "phone_number": phoneNumber,
            "event_id": eventId,
            "route_id": routeId
            ]
        
        print(url!)
        
        Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
        }
    }
    
    //Routes
    func getRouteInfo(routeId: Int, completion: @escaping (_ drivers: [RealmDriver], _ zones: [Zone]) -> ()) {
        Alamofire.request(Router.getRouteInfo(routeId: routeId)).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonDrivers = json["drivers"].arrayValue
                let jsonZones = json["zones"].arrayValue
                var drivers = [RealmDriver]()
                var zones = [Zone]()
                //print(json)
                
                for driver in jsonDrivers {
                    let d = RealmDriver(cell: driver["driver"]["cell"].stringValue, id: driver["driver"]["id"].int!)
                    //let d = RealmDriver(json: driver["driver"])
                    d.role = driver["driver"]["role"].stringValue
                    let ll = RealmLocation(json: driver["location"])
                    d.lastLocation = ll
                    drivers.append(d)
                }
                
                for zone in jsonZones {
                    let z = Zone(json: zone)
                    zones.append(z)
                }
                
                completion(drivers, zones)
                
                //self.addPins()
                
            case .failure:
                break
            }
        }
    }
    
    func getRouteDrivers(routeId: Int, completion: @escaping (_ drivers: [RealmDriver]) -> ()) {
        Alamofire.request(Router.getRouteDrivers(routeId: routeId)).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonDrivers = json["drivers"].arrayValue
                var drivers = [RealmDriver]()
                
                for driver in jsonDrivers {
                    //let d = RealmDriver(json: driver["driver"])
                    let d = RealmDriver(routeJson: driver)//RealmDriver(cell: driver["driver"]["cell"].stringValue, id: driver["driver"]["id"].int!)
                    /*
                    let v = Vendor(json: driver["vendor"])
                    d.vendor = v
                    
                    let scan = Scan(reason: driver["scan"]["reason"].stringValue, latitude: driver["scan"]["latitude"].floatValue, longitude: driver["scan"]["longitude"].floatValue, comment: driver["scan"]["comment"].stringValue, createdAt: driver["scan"]["created_at"].stringValue)
                    
                    //TODO: All realm model objects like this
                    let location = RealmLocation(json: driver["location"])
                    let shift = Shift(id: driver["shift"]["id"].intValue, name: driver["shift"]["name"].stringValue, routeId: driver["shift"]["route_id"].intValue, eventId: driver["shift"]["event_id"].intValue)
                    
                    for time in driver["times"].arrayValue {
                        //print(time)
                        let t = ShiftTime(name: time["time"]["name"].stringValue, time: time["time"]["day_time"].stringValue, shiftId: time["time"]["shift_id"].intValue)
                        t.scanType = time["time"]["scan_type"].stringValue
                        shift.times.append(t)
                    }
                    
                    d.scans.append(scan)
                    d.lastLocation = location
                    d.shifts.append(shift)
                    */
                    if d.role == "driver" {
                        drivers.append(d)
                    }
                }
                
                completion(drivers)
                
            case .failure:
                break
            }
        }
    }
    
    //Shifts
    //Breaking on router, put back to old temp
    func getRouteShifts(eventId: Int, routeId: Int, completion: @escaping(_ shifts: [Shift], _ error: Error?) -> ()) {
        
        var shifts = [Shift]()
        let path = BASE_URL +  "/api/v1/events/\(eventId)/routes/\(routeId)/shifts.json?day=\(currentUser!.day!.calendarDay)" //"/api/v1/shifts.json?route_id=\(routeId)"
        let url = baseURL!.appendingPathComponent(path)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
           
            if response.response?.statusCode == 200 {
                switch response.result {
                case .success(let jsonObject):
                    let json = JSON(jsonObject)
                    
                    let jsonShifts = json["shifts"].arrayValue
                    var shifts = [Shift]()
                    
                    for shift in jsonShifts {
                        var s = Shift(shiftJson: shift)
                        shifts.append(s)
                    }
                        
                        /*
                        var s = Shift(id: shift["id"].intValue, name: shift["shift"]["name"].stringValue, routeId: shift["route_id"].intValue, eventId: shift["event_id"].intValue)
                        for st in shift["shift_times"].arrayValue {
                            let t = ShiftTime(name: st["name"].stringValue, time: st["day_time"].stringValue, shiftId: st["shift_id"].intValue)
                            s.times.append(t)
                        }
                        
                        for dr in shift["drivers"].arrayValue {
                            
                            print("-------------> \(dr)")
                            let d = RealmDriver(json: dr["driver"])
                            
                            
                            let v = Vendor(json: dr["vendor"])
                            //let d = RealmDriver(cell: dr["driver"]["cell"].stringValue, id: dr["driver"]["id"].intValue)
                            d.shiftId.value = s.id
                            d.vendor = v
                            
                            var scans = [Scan]()
                            scans.removeAll()
                            //print(dr)
                            for sc in dr["scans"].arrayValue {
                                
                     
                                let scan = Scan(reason: sc["scan"]["reason"].stringValue, latitude: sc["scan"]["latitude"].floatValue, longitude: sc["scan"]["longitude"].floatValue, comment: sc["scan"]["comment"].stringValue, createdAt: sc["scan"]["created_at"].stringValue)
                                //print(scan)
                                //scans.append(scan)
                                d.scans.append(scan)
                                
                            }
                            
                            
                            //TODO: All realm model objects like this
                            let location = RealmLocation(json: dr["location"])
                            //try! self.realm.write {
                                /*
                                for scan in scans {
                                    d.scans.append(scan)
                                }
                                */
                                d.lastLocation = location
                                s.drivers.append(d)
                            //}
                            
                        }
                        try! self.realm.write {
                            //shifts.append(s)
                        }
                        shifts.append(s)
                    }
                    //shifts.append(shi)
                    //let sh = self.realm.objects(Shift.self).first
                    //print(shifts)
                    */
                    completion(shifts, nil)
                    
                case .failure(let error):
                    completion(shifts, error)
                }
            } else {
                print("handle error")
                let error = NSError()
                completion(shifts, error)
            }
        }
    }
    
    func getPassenger(phoneNumber: String, completion: @escaping (_ response: DataResponse<Any>) -> ()) {
        Alamofire.request(Router.getPassenger(phoneNumber: phoneNumber)).responseJSON { response in
            completion(response)
        }
    }
    
    //Losts
    func getEventLosts(_ eventId: Int, completion: @escaping (_ losts: [Lost]) -> ()) {
        Alamofire.request(Router.getLosts(eventId: eventId)).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonLosts = json["losts"]
                var losts = [Lost]()
                
                for lost in jsonLosts.arrayValue {
                    let l = Lost(json: lost["lost"])
                    losts.append(l)
                }
                completion(losts)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    //Working with router
    func postLost(_ driverId: Int, _ eventId: Int, _ body: String, _ riderName: String,
                  _ riderPhone: String, _ comments: [[String: Any]], status: Int, completion: @escaping (_ success: DataResponse<Any>) -> ()) {
        
        let path = BASE_URL +  "/api/v1/events/\(eventId)/lost_and_founds.json" //"/api/v1/shifts.json?route_id=\(routeId)"
        //let url = baseURL!.appendingPathComponent(path)
        let headers = [
            "Content-Type": "application/json"
        ]

        let params: Parameters = [
            "driver_id": driverId,
            "event_id": eventId,
            "status": status,
            "body": body,
            "rider_name": riderName,
            "rider_phone": riderPhone,
            "comments": comments
         ]
        
        Alamofire.request(path, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success:
                completion(response)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    //MARK: Login
    /* are we going to login through devise?
     func login() {
     let path = "users/sign_in"
     let url = baseURL!.appendingPathComponent(path)
     let headers = [
     "Content-Type": "application/json"
     ]
     
     let parameters: Parameters = [
     "user": [
     "email": "eprleads@gmail.com",
     "password": "password"]
     ]
     
     Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
     
     switch response.result {
     case .success:
     if let JSON = response.result.value {
     
     }
     
     case .failure:
     break
     }
     }
     }
     */

}
