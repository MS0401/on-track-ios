//
//  NotificationsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/30/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import TwicketSegmentedControl
import Alamofire
import SwiftyJSON
import ActionCableClient

class NotificationsViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: TwicketSegmentedControl!
    @IBOutlet weak var tableView: UITableView!

    var titles = ["All", "Drivers", "Staff"]
    var notifications = [RealmNotification]()
    var drivers = [RealmNotification]()
    var staffs = [RealmNotification]()
    var client = ActionCableClient(url: URL(string: "wss://ontrackmanagement.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "NotificationsChannel"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        
        title = "Notifications"
        
        //Potential issue with multiple active shifts
        APIManager.shared.getNotifications { (notifications) in
            self.notifications = notifications.reversed()
            for n in self.notifications {
                if n.driver?.role == "driver" {
                    self.drivers.append(n)
                } else {
                    self.staffs.append(n)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        
        let id = ["event_id" : currentUser?.event?.eventId]
        
        self.channel = client.create(NotificationsViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        
        //self.channel = client.create(DriverDetailViewController.ChannelIdentifier)
        self.channel?.onSubscribed = {
            print("Subscribed to \(NotificationsViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let JSONObject = JSON(data!)
            print("JSONObject -----------> \(JSONObject)")
            //let counts = JSONObject["data"]["ridership_counts"]
            //print(counts)
            
            
            /*
             let msg = ChatMessage(name: JSONObject["name"].string!, message: JSONObject["message"].string!)
             self.history.append(msg)
             self.chatView?.tableView.reloadData()
             
             
             // Scroll to our new message!
             if (msg.name == self.name) {
             let indexPath = IndexPath(row: self.history.count - 1, section: 0)
             self.chatView?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
             }
             */
        }
        
        self.client.connect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        client.disconnect()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let notification = sender as! RealmNotification
        let shift = Shift()
        shift.id = notification.shiftId.value!
        shift.routeId = notification.routeId.value!
        shift.eventId = (currentUser?.event_id)!
        
        if segue.identifier == "notificationDriverSegue" {
            let dvc = segue.destination as! DriverDetailViewController
            dvc.driver = notification.driver
            dvc.shift = shift
            dvc.driverId = notification.driverId.value!
            
        } else if segue.identifier == "notificationStaffSegue" {
            let notification = sender as! RealmNotification
            let dvc = segue.destination as! StaffDetailViewController
            dvc.driver = notification.driver
            dvc.driver.shifts.append(shift)
        }
    }
}

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return notifications.count
        case 1:
            return drivers.count
        case 2:
            return staffs.count
        default:
            return notifications.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nCell", for: indexPath) as! NotificationTableViewCell
        var notification: RealmNotification!
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            notification = notifications[indexPath.row]
        case 1:
            notification = drivers[indexPath.row]
        case 2:
            notification = staffs[indexPath.row]
        default:
            notification = notifications[indexPath.row]
        }
        cell.notification = notification
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let notification: RealmNotification!
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            notification = notifications[indexPath.row]
        case 1:
            notification = drivers[indexPath.row]
        case 2:
            notification = staffs[indexPath.row]
        default:
            notification = notifications[indexPath.row]
        }
        
        if notification.driver?.role == "driver" {
            performSegue(withIdentifier: "notificationDriverSegue", sender: notification)
        } else {
            performSegue(withIdentifier: "notificationStaffSegue", sender: notification)
        }
    }
}

extension NotificationsViewController: TwicketSegmentedControlDelegate {
    
    func didSelect(_ segmentIndex: Int) {
        switch segmentIndex {
        case 0:
            tableView.reloadData()
        case 1:
            tableView.reloadData()
        default:
            tableView.reloadData()
        }
    }
}
