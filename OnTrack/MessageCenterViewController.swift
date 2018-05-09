//
//  MessageCenterTableViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/30/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import TwicketSegmentedControl
import Alamofire
import SwiftyJSON
import ACProgressHUD_Swift
import ActionCableClient

class MessageCenterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: TwicketSegmentedControl!
    
    var titles = ["Received", "Groups", "Drivers", "Staff"]
    var messages = [[String: Any]]()
    var groups = [MessageGroup]()
    //var timer: Timer!
    var drivers = [RealmDriver]()
    var staff = [RealmDriver]()
    var client = ActionCableClient(url: URL(string: "wss://ontrackmanagement.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "BroadcastMessagesChannel"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        
        title = "Message Center"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getLatestMessages()
        //timer = Timer.scheduledTimer(timeInterval: 3000, target: self, selector: #selector(getLatestMessages), userInfo: nil, repeats: true)
        
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
        
        self.channel = client.create(MessageCenterViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        
        //self.channel = client.create(DriverDetailViewController.ChannelIdentifier)
        self.channel?.onSubscribed = {
            print("Subscribed to \(MessageCenterViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let JSONObject = JSON(data!)
            //print("JSONObject -----------> \(JSONObject)")
            //let counts = JSONObject["data"]["ridership_counts"]
            //print(counts)
            var message = JSONObject["messages"].dictionaryValue
            print(message["last_scan"]!["reason"])
            //var messages = [[String: Any]]()
            
            //print(message)
            
            
            let dict = ["driverId": message["driver_id"]!.intValue,
                            "driverName": message["driver_name"]!.stringValue,
                            "body": message["body"]!.stringValue,
                            "createdAt": message["created_at"]!.stringValue, "from": message["from_number"]!.stringValue,
                            "routeName": message["route_name"]!.stringValue, "shiftName": message["shift_name"]!.stringValue,
                            "lastScan": message["last_scan"]!["reason"].stringValue, "id": message["id"]!.intValue,
                            "unread": message["unread"]!.boolValue] as [String: Any]
            
            
            if let did: Int = dict["driverId"] as! Int {
                for item in self.messages {
                    if item["driverId"] as! Int == did {
                        if let index = self.messages.index(where: { $0["driverId"] as! Int == did }) {
                            self.messages.remove(at: index)
                            self.messages.append(dict)
                            self.messages = self.messages.sorted(by: {$0["createdAt"] as! String > $1["createdAt"] as! String})
                            self.tableView.reloadData()
                        }
                    }
                }
            }
            
            
            //self.messages.append(dict)
            //self.tableView.reloadData()
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
        //timer.invalidate()
        client.disconnect()
    }
    
    func getLatestMessages() {
        messages.removeAll()
        APIManager.shared.getMessages { (messages) in
            
            self.messages = messages.sorted(by: {$0["createdAt"] as! String > $1["createdAt"] as! String})
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func getAll() {
        let progressView = ACProgressHUD.shared
        progressView.progressText = "Updating Drivers..."
        progressView.showHUD()
        
        APIManager.shared.getDrivers(roles: ["driver"]) { (drivers) in
            self.drivers = drivers.sorted { $0.name < $1.name }
            
            progressView.hideHUD()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func getStaff() {
        let progressView = ACProgressHUD.shared
        progressView.progressText = "Updating Staff..."
        progressView.showHUD()
        
        APIManager.shared.getAllStaffMembers(roles: ["admin", "manager", "route_managers"]) { (drivers) in
            self.staff = drivers.sorted { $0.name < $1.name }
            
            progressView.hideHUD()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    func textMessages(index: Int) {
        let layout = UICollectionViewFlowLayout()
        let controller = MessageCollectionViewController(collectionViewLayout: layout)
        let driver = RealmDriver()
        driver.id = messages[index]["driverId"] as! Int
        driver.name = messages[index]["driverName"] as! String
        driver.cell = messages[index]["from"] as? String
        driver.event = currentUser?.event
        driver.route = currentUser?.event?.routes.first
        controller.driver = driver
        present(controller, animated: true, completion: nil)
    }
    
    func groupText(groupId: Int) {
        let layout = UICollectionViewFlowLayout()
        let controller = MessageCollectionViewController(collectionViewLayout: layout)
        let group = groups[groupId].groupId.value
        controller.groupId = group
        controller.isGroup = true
        present(controller, animated: true, completion: nil)
    }
    
    func allMessages(driver: RealmDriver) {
        let layout = UICollectionViewFlowLayout()
        let controller = MessageCollectionViewController(collectionViewLayout: layout)
        
        controller.driver = driver
        present(controller, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return messages.count
        } else if segmentedControl.selectedSegmentIndex == 1 {
            return groups.count
        } else if segmentedControl.selectedSegmentIndex == 2 {
            return drivers.count
        } else {
            return staff.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentedControl.selectedSegmentIndex == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mcCell", for: indexPath) as! MessageTableViewCell
            let sender = messages[indexPath.row]
            cell.dict = sender
            cell.senderName.text = sender["driverName"] as? String
            cell.senderMessage.text = sender["body"] as? String
            cell.routeWaveLabel.text = "\(sender["routeName"]!) - \(sender["shiftName"]!)"
            
            if sender["lastScan"] as! String == "" || sender["lastScan"] == nil {
                cell.lastScanLabel.text = "No last scan"
            } else {
                cell.lastScanLabel.text = sender["lastScan"] as! String
            }
            
            return cell
        } else if segmentedControl.selectedSegmentIndex == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath)
            cell.textLabel?.text = groups[indexPath.row].name
            cell.detailTextLabel?.text = "\(groupeType(groupType: groups[indexPath.row].groupType)) (\(groups[indexPath.row].memberCount.value!))"
            return cell
        } else if segmentedControl.selectedSegmentIndex == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath)
            cell.textLabel?.text = drivers[indexPath.row].name
            cell.detailTextLabel?.text = drivers[indexPath.row].vendor?.name
            print(drivers[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath)
            cell.textLabel?.text = staff[indexPath.row].name
            cell.detailTextLabel?.text = staff[indexPath.row].vendor?.name
            print(staff[indexPath.row])
            return cell
        }
    }
    
    func groupeType(groupType: String) -> String {
        
        var returnType = ""
        
        switch groupType {
        case "ALL_DRIVERS_AND_STAFF":
            returnType = "All"
        case "ALL_STAFF":
            returnType = "Staff"
        case "ALL_DRIVERS":
            returnType = "Drivers"
        case "SHIFT_STAFF":
            returnType = "Staff"
        case "SHIFT_DRIVERS":
            returnType = "Drivers"
        case "ROUTE_STAFF":
            returnType = "Staff"
        case "ROUTE_DRIVERS":
            returnType = "Drivers"
        case "SHIFT_OUT_OF_SERVICE":
            return "Out of Service"
        case "SHIFT_ON_BREAK":
            return "On Break"
        default:
            break
        }
        
        return returnType
    }
    
    func updateMessage(id: Int) {
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event_id)/messages/\(id)/mark_read"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .put, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
            case .failure:
                break
            }
        }
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if segmentedControl.selectedSegmentIndex == 0 {
            let m = messages[indexPath.row] as [String: Any]
            let id: Int = m["id"]! as! Int
            
            updateMessage(id: id)
            
            textMessages(index: indexPath.row)
            
        } else if segmentedControl.selectedSegmentIndex == 1 {
            groupText(groupId: indexPath.row)
        } else if segmentedControl.selectedSegmentIndex == 2  {
            let driver = drivers[indexPath.row]
            driver.event = currentUser?.event
            driver.route = currentUser?.route
            allMessages(driver: driver)
        } else {
            let driver = staff[indexPath.row]
            driver.event = currentUser?.event
            driver.route = currentUser?.route
            allMessages(driver: driver)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if segmentedControl.selectedSegmentIndex == 1 || segmentedControl.selectedSegmentIndex == 2 || segmentedControl.selectedSegmentIndex == 3 {
            return 50
        } else {
            return 125
        }
    }
}

extension MessageCenterViewController: TwicketSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
        switch segmentIndex {
        case 0:
            //timer.invalidate()
            getLatestMessages()
            //timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(getLatestMessages), userInfo: nil, repeats: true)
        case 1:
            //timer.invalidate()
            APIManager.shared.getMessageGroups(completion: { (groups) in
                self.groups = groups
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
        case 2:
            //timer.invalidate()
            getAll()
        case 3:
            //timer.invalidate()
            getStaff()
        default:
            //timer.invalidate()
            getLatestMessages()
            //timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(getLatestMessages), userInfo: nil, repeats: true)
        }
    }
}
