//
//  RadioStatsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/5/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import UICircularProgressRing
import RealmSwift
import Alamofire
import SwiftyJSON
import ActionCableClient

class RadioStatsViewController: UIViewController, UICircularProgressRingDelegate {
    
    @IBOutlet weak var availableRing: UICircularProgressRingView!
    @IBOutlet weak var checkedOutRing: UICircularProgressRingView!
    @IBOutlet weak var outOfServiceRing: UICircularProgressRingView!
    @IBOutlet weak var availableLabel: UILabel!
    @IBOutlet weak var checkedOutLabel: UILabel!
    @IBOutlet weak var outOfServiceLabel: UILabel!
    @IBOutlet weak var numberOfItems: UILabel!
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var totalButton: UIButton!
    
    lazy var realm = try! Realm()
    var client = ActionCableClient(url: URL(string: "wss://ontrackinventory.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "StatsChannel"
    var eventId: Int!
    var inventoryTypeId: Int!
    var inventoryName: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        availableRing.delegate = self
        checkedOutRing.delegate = self
        outOfServiceRing.delegate = self
        
        numberOfItems.text = ""
        availableLabel.text = ""
        checkedOutLabel.text = ""
        outOfServiceLabel.text = ""
        
        numberOfItems.alpha = 0.0
        availableLabel.alpha = 0.0
        checkedOutLabel.alpha = 0.0
        outOfServiceLabel.alpha = 0.0
        
        if let name = inventoryName {
            title = "\(name) Stats"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getInventoryStats()
        setupActionCable()
        //tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /*
        let radios = realm.objects(Equipment.self)
        let available = radios.filter("status == 1")
        let assigned = radios.filter("status == 2")
        let service = radios.filter("status == 3")
        numberOfItems.text = "\(radios.count) TOTAL RADIOS"
        
        //availableRing.maxValue = CGFloat(radios.count)
        availableRing.setProgress(value: CGFloat(available.count), animationDuration: 1.0)
        availableLabel.text = "\(available.count) Available"
        
        //checkedOutRing.maxValue = CGFloat(radios.count)
        checkedOutRing.setProgress(value: CGFloat(assigned.count), animationDuration: 1.0)
        checkedOutLabel.text = "\(assigned.count) Assigned"
        
        //outOfServiceRing.maxValue = CGFloat(radios.count)
        outOfServiceRing.setProgress(value: CGFloat(service.count), animationDuration: 1.0)
        outOfServiceLabel.text = "\(service.count) Out of Service"
        
        UIView.animate(withDuration: 0.5, animations: {
            self.numberOfItems.alpha = 1.0
            self.availableLabel.alpha = 1.0
            self.checkedOutLabel.alpha = 1.0
            self.outOfServiceLabel.alpha = 1.0
        })
        
        getInventoryStats()
        */
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        client.disconnect()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "itemsMapSegue" {
            let dvc = segue.destination as! InventoryMapViewController
            dvc.inventoryTypeId = self.inventoryTypeId
        } else if segue.identifier == "caseOneSegue" {
            let dvc = segue.destination as! RadioStatusViewController
            dvc.inventoryTypeId = self.inventoryTypeId
            dvc.inventoryStatus = "available"
        } else if segue.identifier == "caseTwoSegue" {
            let dvc = segue.destination as! RadioStatusViewController
            dvc.inventoryTypeId = self.inventoryTypeId
            dvc.inventoryStatus = "assigned"
        } else if segue.identifier == "caseThreeSegue" {
            let dvc = segue.destination as! RadioStatusViewController
            dvc.inventoryTypeId = self.inventoryTypeId
            dvc.inventoryStatus = "out_of_service"
        }
        /*
        if segue.identifier == "caseOneSegue" {
            let dvc = segue.destination as! RadioStatusViewController
            dvc.status = 1
        } else if segue.identifier == "caseTwoSegue" {
            let dvc = segue.destination as! RadioStatusViewController
            dvc.status = 2
        } else if segue.identifier == "radioVendorSegue" {
            
        } else {
            let dvc = segue.destination as! RadioStatusViewController
            dvc.status = 3
        }
        */
    }
    
    func finishedUpdatingProgress(forRing ring: UICircularProgressRingView) {
    
    }
    
    func getInventoryStats() {
        print("get inventory")
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/stats"
        print(path)
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        print(headers)
        
        let parameters = [
            "event_id": eventId,
            "inventory_type_id": inventoryTypeId
        ]
        print(parameters)
        
        Alamofire.request(path, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print("here")
            print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let assigned = json["assigned"].intValue
                let available = json["available"].intValue
                let notScanned = json["not_scanned"].intValue
                let outOfService = json["out_of_service"].intValue
                let received = json["received"].intValue
                let total = json["total"].intValue
                
                DispatchQueue.main.async {
                    //self.totalButton.setTitle("\(notScanned) Not Scanned", for: UIControlState.normal)
                    
                    self.numberOfItems.text = "\(total) TOTAL / \(received) RECEIVED"
                    self.availableLabel.text = "\(available) Available / \(notScanned) Not Scanned"
                    self.checkedOutLabel.text = "\(assigned) Assigned"
                    self.outOfServiceLabel.text = "\(outOfService) Out"
                    
                    self.availableRing.maxValue = CGFloat(received)
                    self.availableRing.setProgress(value: CGFloat(available), animationDuration: 1.0, completion: nil)
                    
                    self.checkedOutRing.maxValue = CGFloat(received)
                    self.checkedOutRing.setProgress(value: CGFloat(assigned), animationDuration: 1.0)
                    
                    self.outOfServiceRing.maxValue = CGFloat(received)
                    self.outOfServiceRing.setProgress(value: CGFloat(outOfService), animationDuration: 1.0)
                    
                    UIView.animate(withDuration: 0.5, animations: {
                        self.numberOfItems.alpha = 1.0
                        self.availableLabel.alpha = 1.0
                        self.checkedOutLabel.alpha = 1.0
                        self.outOfServiceLabel.alpha = 1.0
                    })
                }
                
            case .failure:
                break
            }
        }
    }
    
    func setupActionCable() {
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
        
        let id = ["event_id": 1, "inventory_type_id": inventoryTypeId]
        
        self.channel = client.create(PMDashboardViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        //self.channel = client.create(PMDashboardViewController.ChannelIdentifier)
        
        self.channel?.onSubscribed = {
            print("Subscribed to \(PMDashboardViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let json = JSON(data!)
            print(json)
            
            let assigned = json["assigned"].intValue
            let available = json["available"].intValue
            let notScanned = json["not_scanned"].intValue
            let outOfService = json["out_of_service"].intValue
            let received = json["received"].intValue
            let total = json["total"].intValue
            
            DispatchQueue.main.async {
                //self.totalButton.setTitle("\(notScanned) Not Scanned", for: UIControlState.normal)
                
                self.numberOfItems.text = "\(total) TOTAL / \(received) RECEIVED"
                self.availableLabel.text = "\(available) Available / \(notScanned) Not Scanned"
                self.checkedOutLabel.text = "\(assigned) Assigned"
                self.outOfServiceLabel.text = "\(outOfService) Out"
                
                self.availableRing.maxValue = CGFloat(received)
                self.availableRing.setProgress(value: CGFloat(available), animationDuration: 1.0, completion: nil)
                
                self.checkedOutRing.maxValue = CGFloat(received)
                self.checkedOutRing.setProgress(value: CGFloat(assigned), animationDuration: 1.0)
                
                self.outOfServiceRing.maxValue = CGFloat(received)
                self.outOfServiceRing.setProgress(value: CGFloat(outOfService), animationDuration: 1.0)
            }
        }
        
        self.client.connect()
    }
    
}

extension RadioStatsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "vCell", for: indexPath)
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Exterior Perimeter"
            cell.detailTextLabel?.text = ""
        case 1:
            cell.textLabel?.text = "Interior Venue"
            cell.detailTextLabel?.text = ""
        default:
            cell.textLabel?.text = "OnTrack"
            //let rdos = realm.objects(Equipment.self)
            //let assigned = rdos.filter("status == 2")
            //cell.detailTextLabel?.text = "\(assigned.count)"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        /*
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "radioVendorSegue", sender: self)
        case 1,2:
            print("print")
        default:
            break
        }
        */
    }
}
