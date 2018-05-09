//
//  WaveStatsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/21/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import UICircularProgressRing
import BTNavigationDropdownMenu
import MapKit
import Alamofire
import SwiftyJSON
import SwiftDate
import ActionCableClient

class WaveStatsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressRing: UICircularProgressRingView!
    @IBOutlet weak var onBreakRing: UICircularProgressRingView!
    @IBOutlet weak var outOfServiceRing: UICircularProgressRingView!
    @IBOutlet weak var checkedInLabel: UILabel!
    @IBOutlet weak var onBreakLabel: UILabel!
    @IBOutlet weak var outOfServiceLabel: UILabel!
    @IBOutlet weak var numberOfDrivers: UILabel!
    
    var items = ["Check In", "Pick Up", "Drop", "On Break", "Out of Service", "Not Scanned"]
    var menuView: BTNavigationDropdownMenu!
    var drivers = [RealmDriver]()
    var filter = [RealmDriver]()
    var dict = [String: Int]()
    var shift: Shift!
    var client = ActionCableClient(url: URL(string: "wss://ontrackmanagement.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "RoutesChannel"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        items.insert("\(shift.name) All Scans", at: 0)
        
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
        
        menuView = BTNavigationDropdownMenu(title: items[0], items: items as [AnyObject])
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
            self.filterScans(indexPath: indexPath)
        }
        
        navigationItem.titleView = menuView
    
        tableView.tableFooterView = UIView()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (shift) != nil {
            getStats()
        }
        /*
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
        
        self.channel = client.create(WaveStatsViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        
        self.channel?.onSubscribed = {
            print("Subscribed to \(WaveStatsViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let JSONObject = JSON(data!)
            print("JSONObject -----------> \(JSONObject)")
        }
        
        self.client.connect()
        */
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuView.hide()
        //client.disconnect()
    }
    
    func filterScans(indexPath: Int) {
        
        switch indexPath {
        case 0:
            filter = drivers
        case 1:
            self.filter = self.drivers.filter { $0.lastScan?.reason! == "driver_check_in" }
        case 2:
            self.filter = self.drivers.filter { $0.lastScan?.reason! == "pick_up_pax" }
        case 3:
            self.filter = self.drivers.filter { $0.lastScan?.reason! == "drop_unload" }
        case 4:
            self.filter = self.drivers.filter { $0.lastScan?.reason! == "break_in" }
        case 5:
            self.filter = self.drivers.filter { $0.lastScan?.reason! == "out_of_service_mechanical" || $0.lastScan?.reason! == "out_of_service_emergency" }
        case 6:
            self.filter = self.drivers.filter { $0.lastScan?.reason! == nil || $0.lastScan?.reason! == "" }
        default:
            filter = drivers
        }
        
        tableView.reloadData()
    }
    
    func getStats() {
        APIManager.shared.getShiftStats(eventId: shift.eventId, routeId: shift.routeId, shiftId: shift.id, completion: { (drivers, dict) in
            self.drivers = drivers
            self.filter = drivers
            self.dict = dict
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                
                self.numberOfDrivers.text = "\(dict["total_drivers"]!) DRIVERS"
                self.checkedInLabel.text = "\(dict["checked_in_drivers"]!) Checked In"
                self.onBreakLabel.text = "\(dict["on_break_drivers"]!) On Break"
                self.outOfServiceLabel.text = "\(dict["out_of_service_drivers"]!) Out"
                
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.numberOfDrivers.alpha = 1.0
                    self.checkedInLabel.alpha = 1.0
                    self.outOfServiceLabel.alpha = 1.0
                    self.onBreakLabel.alpha = 1.0
                })
            }
            
            self.progressRing.setProgress(value: CGFloat(dict["checked_in_drivers"]!), animationDuration: 1.0, completion: nil)
            self.onBreakRing.setProgress(value: CGFloat(dict["on_break_drivers"]!), animationDuration: 1.0, completion: nil)
            self.outOfServiceRing.setProgress(value: CGFloat(dict["out_of_service_drivers"]!), animationDuration: 1.0, completion: nil)
        })
    }
    
    @IBAction func outOfService(_ sender: UIButton) {
        performSegue(withIdentifier: "waveOutOfServiceSegue", sender: self)
    }
    
    @IBAction func onBreak(_ sender: UIButton) {
        performSegue(withIdentifier: "waveOnBreakSegue", sender: self)
    }
    
    @IBAction func checkedIn(_ sender: UIButton) {
        performSegue(withIdentifier: "waveToToggleSegue", sender: self)
    }
    
    @IBAction func openMessages(_ sender: UIBarButtonItem) {
        //groupText(groupId: <#T##Int#>)
    }
    
    /* Need to download all groups into realm
    func groupText(groupId: Int) {
        let layout = UICollectionViewFlowLayout()
        let controller = MessageCollectionViewController(collectionViewLayout: layout)
        let group = groups[groupId].groupId.value
        controller.groupId = group
        controller.isGroup = true
        present(controller, animated: true, completion: nil)
    }
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if sender != nil {
            if segue.identifier == "segueFromWaveStats" {
                let dvc = segue.destination as! DriverDetailViewController
                dvc.driver = sender as! RealmDriver
                dvc.shift = shift
            }
        }
        
        if segue.identifier == "waveOnBreakSegue" {
            let dvc = segue.destination as! BreakToggleViewController
            dvc.isAll = false
            dvc.routes = [shift.routeId]
            dvc.shifts = [shift.id]
        }
        
        if segue.identifier == "waveOutOfServiceSegue" {
            let dvc = segue.destination as! OutOfServiceViewController
            dvc.isAll = false
            dvc.routes = [shift.routeId]
            dvc.shifts = [shift.id]
        } else if segue.identifier == "waveToToggleSegue" {
            let dvc = segue.destination as! ToggleDriverViewController
            dvc.isAll = false
            dvc.routes = [shift.routeId]
            dvc.shifts = [shift.id]
        }
    }
}

extension WaveStatsViewController: UICircularProgressRingDelegate {
    func finishedUpdatingProgress(forRing ring: UICircularProgressRingView) {
        //print(ring)
    }
}

extension WaveStatsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filter.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "statsWaveCell", for: indexPath) as! WaveTableViewCell
        let driver = filter[indexPath.row]
        cell.driver = driver
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let driver = filter[indexPath.row]
        performSegue(withIdentifier: "segueFromWaveStats", sender: driver)
    }
}
