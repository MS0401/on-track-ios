//
//  RouteStatsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import UICircularProgressRing
import BTNavigationDropdownMenu
import Alamofire
import SwiftyJSON
import SwiftDate
import ActionCableClient

class RouteStatsViewController: UIViewController, UICircularProgressRingDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressRing: UICircularProgressRingView!
    @IBOutlet weak var onBreakRing: UICircularProgressRingView!
    @IBOutlet weak var outOfServiceRing: UICircularProgressRingView!
    @IBOutlet weak var checkedInLabel: UILabel!
    @IBOutlet weak var onBreakLabel: UILabel!
    @IBOutlet weak var outOfServiceLabel: UILabel!
    @IBOutlet weak var numberOfDrivers: UILabel!
    
    var items = ["All Routes"]
    var menuView: BTNavigationDropdownMenu!
    var waves = [Shift]()
    var routes = [RealmRoute]()
    var dict = [String: Int]()
    var selectedIndex: Int = 0
    var client = ActionCableClient(url: URL(string: "wss://ontrackmanagement.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "RoutesChannel"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        progressRing.delegate = self
        onBreakRing.delegate = self
        outOfServiceRing.delegate = self
        
        numberOfDrivers.text = ""
        checkedInLabel.text = ""
        onBreakLabel.text = ""
        outOfServiceLabel.text = ""
        
        numberOfDrivers.alpha = 0.0
        checkedInLabel.alpha = 0.0
        onBreakLabel.alpha = 0.0
        outOfServiceLabel.alpha = 0.0
        
        self.menuView = BTNavigationDropdownMenu(title: self.items[0], items: self.items as [AnyObject])
        self.navigationItem.titleView = self.menuView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupRoutes()
        
        self.client.willConnect = {
            print("Will Connect")
        }
        
        self.client.onConnected = {
            print("Connected to \(self.client.url)")
        }
        
        self.client.onDisconnected = {(error: ConnectionError?) in
            print("Disconected with error: \(error)")
        }
        
        self.client.willReconnect = {
            print("Reconnecting to \(self.client.url)")
            return true
        }
        
        let day = currentUser!.day!.calendarDay
        let date = DateInRegion(string: day, format: DateFormat.iso8601Auto)
        let year = date?.year
        let month = date?.month
        let d = date?.day
        let calc = year! + month! + d!
        let id = ["event_id" : currentUser?.event?.eventId, "day": calc]
        
        self.channel = client.create(RouteStatsViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        
        self.channel?.onSubscribed = {
            print("Subscribed to \(RouteStatsViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let json = JSON(data!)
            let outOfService = json["out_of_service_drivers"].intValue
            let onBreak = json["on_break_drivers"].intValue
            let checkedIn = json["checked_in_drivers"].intValue
            let totalDrivers = json["total_drivers"].intValue
            
            let statsDict = ["out_of_service_drivers": outOfService, "on_break_drivers": onBreak,
                             "checked_in_drivers": checkedIn, "total_drivers": totalDrivers] as [String : Int]
            
            self.dict = statsDict
            
            var routes = [RealmRoute]()
            
            routes.removeAll()
            for route in json["routes"].arrayValue {
                let r = RealmRoute(routeJSON: route)
                routes.append(r)
            }
            
            self.routes.removeAll()
            self.waves.removeAll()
            self.items.removeAll()
            
            self.routes = routes.sorted { $1.id > $0.id }
            self.routes = self.routes.reversed()
            
            for r in self.routes {
                self.items.append(r.name!)
                for w in r.shifts {
                    self.waves.append(w)
                }
            }
            
            self.waves = self.waves.sorted { $1.id > $0.id }
            self.items.insert("All Routes", at: 0)
            
            DispatchQueue.main.async {
                
                self.menuView.updateItems((self.items as [AnyObject]))
                self.tableView.reloadData()
                self.menuView.updateItems((self.items as [AnyObject]))
                
                if let total = self.dict["total_drivers"] {
                    self.numberOfDrivers.text = "\(total) DRIVERS"
                }
                
                if let checkedIn = self.dict["checked_in_drivers"] {
                    self.checkedInLabel.text = "\(checkedIn) Checked In"
                    self.progressRing.setProgress(value: CGFloat(checkedIn), animationDuration: 1.0, completion: nil)
                }
                
                if let onBreak = self.dict["on_break_drivers"] {
                    self.onBreakLabel.text = "\(onBreak) On Break"
                    self.onBreakRing.setProgress(value: CGFloat(onBreak), animationDuration: 1.0, completion: nil)
                }
                
                if let out = self.dict["out_of_service_drivers"] {
                    self.outOfServiceLabel.text = "\(out) Out"
                    self.outOfServiceRing.setProgress(value: CGFloat(out), animationDuration: 1.0, completion: nil)
                }
                
                self.menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
                    self.selectedIndex = indexPath
                    print(self.selectedIndex)
                    switch indexPath {
                    case 0:
                        print(self.dict["total_drivers"])
                        if let total = self.dict["total_drivers"] {
                            self.numberOfDrivers.text = "\(total) DRIVERS"
                        }
                        
                        if let checkedIn = self.dict["checked_in_drivers"] {
                            self.checkedInLabel.text = "\(checkedIn) Checked In"
                            self.progressRing.setProgress(value: CGFloat(checkedIn), animationDuration: 1.0, completion: nil)
                        }
                        
                        if let onBreak = self.dict["on_break_drivers"] {
                            self.onBreakLabel.text = "\(onBreak) On Break"
                            self.onBreakRing.setProgress(value: CGFloat(onBreak), animationDuration: 1.0, completion: nil)
                        }
                        
                        if let out = self.dict["out_of_service_drivers"] {
                            self.outOfServiceLabel.text = "\(out) Out"
                            self.outOfServiceRing.setProgress(value: CGFloat(out), animationDuration: 1.0, completion: nil)
                        }
                    case 1:
                        print(routes[0].totalDrivers.value)
                        self.setupDropDown(indexPath: indexPath)
                    case 2:
                        print(routes[1].totalDrivers.value)
                        self.setupDropDown(indexPath: indexPath)
                    case 3:
                        print(routes[2].totalDrivers.value)
                        self.setupDropDown(indexPath: indexPath)
                    default:
                        self.setupDropDown(indexPath: indexPath)
                    }
                    self.tableView.reloadData()
                    
                }
            }
        }
        
        self.client.connect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuView.hide()
        client.disconnect()
    }
    
    func setupRoutes() {
        APIManager.shared.getAllRoutes { (routes, dict) in
            
            self.routes.removeAll()
            self.waves.removeAll()
            self.items.removeAll()
            
            self.routes = routes.sorted { $1.id > $0.id }
            self.routes = self.routes.reversed()
            self.dict = dict
            
            for r in self.routes {
                self.items.append(r.name!)
                for w in r.shifts {
                    self.waves.append(w)
                }
            }
            
            self.waves = self.waves.sorted { $1.id > $0.id }
            
            self.items.insert("All Routes", at: 0)
            self.menuView.updateItems((self.items as [AnyObject]))
            self.tableView.reloadData()
            
            DispatchQueue.main.async {
                
                if let total = self.dict["total_drivers"] {
                    self.numberOfDrivers.text = "\(total) DRIVERS"
                }
                
                if let checkedIn = self.dict["checked_in_drivers"] {
                    self.checkedInLabel.text = "\(checkedIn) Checked In"
                    self.progressRing.setProgress(value: CGFloat(checkedIn), animationDuration: 1.0, completion: nil)
                }
                
                if let onBreak = self.dict["on_break_drivers"] {
                    self.onBreakLabel.text = "\(onBreak) On Break"
                    self.onBreakRing.setProgress(value: CGFloat(onBreak), animationDuration: 1.0, completion: nil)
                }
                
                if let out = self.dict["out_of_service_drivers"] {
                    self.outOfServiceLabel.text = "\(out) Out"
                    self.outOfServiceRing.setProgress(value: CGFloat(out), animationDuration: 1.0, completion: nil)
                }
                
                self.menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
                    self.selectedIndex = indexPath
                    print(self.selectedIndex)
                    switch indexPath {
                    case 0:
                        print(self.dict["total_drivers"])
                        if let total = self.dict["total_drivers"] {
                            self.numberOfDrivers.text = "\(total) DRIVERS"
                        }
                        
                        if let checkedIn = self.dict["checked_in_drivers"] {
                            self.checkedInLabel.text = "\(checkedIn) Checked In"
                            self.progressRing.setProgress(value: CGFloat(checkedIn), animationDuration: 1.0, completion: nil)
                        }
                        
                        if let onBreak = self.dict["on_break_drivers"] {
                            self.onBreakLabel.text = "\(onBreak) On Break"
                            self.onBreakRing.setProgress(value: CGFloat(onBreak), animationDuration: 1.0, completion: nil)
                        }
                        
                        if let out = self.dict["out_of_service_drivers"] {
                            self.outOfServiceLabel.text = "\(out) Out"
                            self.outOfServiceRing.setProgress(value: CGFloat(out), animationDuration: 1.0, completion: nil)
                        }
                    case 1:
                        print(routes[0].totalDrivers.value)
                        self.setupDropDown(indexPath: indexPath)
                    case 2:
                        print(routes[1].totalDrivers.value)
                        self.setupDropDown(indexPath: indexPath)
                    case 3:
                        print(routes[2].totalDrivers.value)
                        self.setupDropDown(indexPath: indexPath)
                    default:
                        self.setupDropDown(indexPath: indexPath)
                    }
                    self.tableView.reloadData()
                    
                }
                
            }
            
            UIView.animate(withDuration: 0.5, animations: {
                self.numberOfDrivers.alpha = 1.0
                self.checkedInLabel.alpha = 1.0
                self.onBreakLabel.alpha = 1.0
                self.outOfServiceLabel.alpha = 1.0
            })
        }
    }
    
    func setupDropDown(indexPath: Int) {

        let route = routes[indexPath - 1]
        
        if let nd = route.totalDrivers.value {
            self.numberOfDrivers.text = "\(nd) DRIVERS"
        }
        
        if let cd = route.checkedInDrivers.value {
            self.progressRing.setProgress(value: CGFloat(cd), animationDuration: 1.0, completion: nil)
            self.checkedInLabel.text = "\(cd) Checked In"
        }
        
        if let ob = route.onBreakDrivers.value {
            self.onBreakRing.setProgress(value: CGFloat(ob), animationDuration: 1.0, completion: nil)
            self.onBreakLabel.text = "\(ob) On Break"
        }
        
        if let os = route.outOfServiceDrivers.value {
            self.outOfServiceRing.setProgress(value: CGFloat(os), animationDuration: 1.0, completion: nil)
            self.outOfServiceLabel.text = "\(os) Out"
        }
        
        //tableView.reloadData()
    }
    
    func finishedUpdatingProgress(forRing ring: UICircularProgressRingView) {}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "dashWaveSegue" {
            let dvc = segue.destination as! WaveStatsViewController
            dvc.shift = sender as! Shift
        } else if segue.identifier == "toggleCheckInSegue" {
            let dvc = segue.destination as! ToggleDriverViewController
            if let eventRoutes = currentUser?.event?.routes {
                var segueRoutes = [Int]()
                for route in eventRoutes {
                    segueRoutes.append(route.id)
                }
                dvc.routes = segueRoutes
            }
            
            if let eventShifts = currentUser?.event?.waves {
                var segueShifts = [Int]()
                for shift in eventShifts {
                    segueShifts.append(shift.id)
                }
                dvc.shifts = segueShifts
            }

            /*
            switch selectedIndex {
            case 0:
                if let eventRoutes = currentUser?.event?.routes {
                    var segueRoutes = [Int]()
                    for route in eventRoutes {
                        segueRoutes.append(route.id)
                    }
                    dvc.routes = segueRoutes
                }
                
                if let eventShifts = currentUser?.event?.waves {
                    var segueShifts = [Int]()
                    for shift in eventShifts {
                        segueShifts.append(shift.id)
                    }
                    dvc.shifts = segueShifts
                }
            default:
                break
                /*
                let r = routes[selectedIndex - 1]
                var s = [Int]()
                
                for shift in r.shifts {
                    s.append(shift.id)
                }
                
                dvc.routes = [(r.shifts.first?.routeId)!]
                dvc.shifts = s
                */
            }
            */
    
            
        } else if segue.identifier == "toggleOnBreakSegue" {
            let dvc = segue.destination as! BreakToggleViewController
        }
    }
}

extension RouteStatsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedIndex {
        case 0:
            return waves.count
        default:
            return routes[selectedIndex - 1].shifts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "routeStatsCell", for: indexPath) as! RouteStatsTableViewCell
        switch selectedIndex {
        case 0:
            cell.routeNameLabel.text = waves[indexPath.row].name
            cell.routeNumberLabel.text = "\(String(describing: waves[indexPath.row].totalDrivers.value!))/\(String(describing: waves[indexPath.row].checkedInDrivers.value!))"
            cell.routePercentLabel.text = "\(((Double(waves[indexPath.row].totalDrivers.value!) * 0.10)))"//wavePercents[indexPath.row]
            cell.routeProgressView.setProgress(Float(Double(cell.routePercentLabel.text!)!), animated: true)
            cell.progress = (Float(cell.routePercentLabel.text!))
            return cell
        default:
            cell.routeNameLabel.text = routes[selectedIndex - 1].shifts[indexPath.row].name
            cell.routeNumberLabel.text = "\(String(describing: routes[selectedIndex - 1].shifts[indexPath.row].totalDrivers.value!))/\(String(describing: routes[selectedIndex - 1].shifts[indexPath.row].checkedInDrivers.value!))"
            cell.routePercentLabel.text = "\(((Double(routes[selectedIndex - 1].shifts[indexPath.row].totalDrivers.value!) * 0.10)))"//wavePercents[indexPath.row]
            cell.routeProgressView.setProgress(Float(Double(cell.routePercentLabel.text!)!), animated: true)
            cell.progress = (Float(cell.routePercentLabel.text!))
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch selectedIndex {
        case 0:
            let shift = waves[indexPath.row]
            performSegue(withIdentifier: "dashWaveSegue", sender: shift)
        default:
            let shift = routes[selectedIndex - 1].shifts[indexPath.row]
            performSegue(withIdentifier: "dashWaveSegue", sender: shift)
        }
    }
}
