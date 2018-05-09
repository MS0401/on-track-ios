//
//  FuelStatsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/29/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import UICircularProgressRing
import ActionCableClient
import Alamofire
import SwiftyJSON
import RealmSwift

class FuelStatsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let realm = try! Realm()
    var index = 0
    var client = ActionCableClient(url: URL(string: "wss://ontrackinventory.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "FuelTypeChannel"//"StatsChannel"
    var fuelTypes = [Fuel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        getAllFuel { (fuel) in
            self.fuelTypes = fuel
            //let storyboard = UIStoryboard(name: "Inventory", bundle: Bundle.main)
            //let viewController = storyboard.instantiateViewController(withIdentifier: "PageViewController") as! PageViewController
            //viewController.fuelTypes = self.fuelTypes
        }
        */
        
        tableView.tableFooterView = UIView()
        
        //NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTable(notification:)), name: NSNotification.Name(rawValue: notificationKey), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //setupActionCable()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //client.disconnect()
    }
    
    func reloadTable(notification: NSNotification) {
        print(notification.object)
        let i = notification.object as! Int
        index = i
        
        DispatchQueue.main.async {
            
            self.tableView.reloadData()
        }
    }
    
    deinit {
        //NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == "pageVCSegue" {
            print("found segue id from segue \(self.fuelTypes)")
            /*
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let dvc = segue.destination as! PageViewController
                dvc.fuelTypes = self.fuelTypes
            }
            */
            
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
        
        //let id = ["event_id": 1, "inventory_type_id": 1]
        let id = ["event_id": 1]
        
        self.channel = client.create(FuelStatsViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        //self.channel = client.create(FuelStatsViewController.ChannelIdentifier)
        
        self.channel?.onSubscribed = {
            print("Subscribed to \(FuelStatsViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let json = JSON(data!)
            print(json)
            
            self.fuelTypes.removeAll()
            
            let total = json["total"].intValue
            let one = json["1"].intValue
            let two = json["2"].intValue
            let three = json["3"].intValue
            let four = json["4"].intValue
            
            print("\(one) \(two) \(three) \(four)")
            
            let totalFuel = Fuel()
            totalFuel.id = 0
            totalFuel.name = "Total"
            totalFuel.total = total
            
            self.fuelTypes.insert(totalFuel, at: 0)
            
            let numOneFuel = Fuel()
            numOneFuel.id = 1
            numOneFuel.name = "Diesel"
            numOneFuel.total = one
            
            self.fuelTypes.insert(numOneFuel, at: 1)
            
            let numTwoFuel = Fuel()
            numTwoFuel.id = 2
            numTwoFuel.name = "Red Dot"
            numTwoFuel.total = two
            
            self.fuelTypes.insert(numTwoFuel, at: 2)
            
            let numThreeFuel = Fuel()
            numThreeFuel.id = 3
            numThreeFuel.name = "Unleaded"
            numThreeFuel.total = three
            
            self.fuelTypes.insert(numThreeFuel, at: 3)
            
            let numFourFuel = Fuel()
            numFourFuel.id = 4
            numFourFuel.name = "Propane"
            numFourFuel.total = four
            
            self.fuelTypes.insert(numFourFuel, at: 4)
            
            print(self.fuelTypes)
            
            let storyboard = UIStoryboard(name: "Inventory", bundle: Bundle.main)
            let viewController = storyboard.instantiateViewController(withIdentifier: "AllFuelViewController") as! AllFuelViewController
            viewController.fuelTypes = self.fuelTypes
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "fuel"), object: self)
            }
            
            print("JSON FROM ACTION CABLE \(json)")
            
        }
        
        self.client.connect()
    }
    
    func getAllFuel(completion: @escaping ([Fuel]) -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/fuel_types"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(json)
                var count = Int()
                var fuelTypes = [Fuel]()
                for fuel in json["data"].arrayValue {
                    let f = Fuel(json: fuel)
                    fuelTypes.append(f)
                    count = count + f.total
                }
                
                let totalFuel = Fuel()
                totalFuel.id = 0
                totalFuel.name = "Total"
                totalFuel.total = count
                
                fuelTypes.insert(totalFuel, at: 0)
                
                completion(fuelTypes)
                
            case .failure:
                break
            }
        }
    }
}

extension FuelStatsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch index {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 3
        case 3:
            return 2
        case 4:
            return 1
        default:
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fuelCell", for: indexPath)
        
        switch index {
        case 0:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Lights"
                cell.detailTextLabel?.text = "0 Gallons"
            default:
                break
            }
            return cell
        case 1:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Generators"
                cell.detailTextLabel?.text = "10,000 Gallons"
            case 1:
                cell.textLabel?.text = "Lights"
                cell.detailTextLabel?.text = "7,000 Gallons"
            default:
                break
            }
            return cell
        case 2:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Generators"
                cell.detailTextLabel?.text = "10,000 Gallons"
            case 1:
                cell.textLabel?.text = "Lights"
                cell.detailTextLabel?.text = "2,000 Gallons"
            case 2:
                cell.textLabel?.text = "Carts"
                cell.detailTextLabel?.text = "1,000 Gallons"
            default:
                break
            }
            return cell
        case 3:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Generators"
                cell.detailTextLabel?.text = "15,000 Gallons"
            case 1:
                cell.textLabel?.text = "Carts"
                cell.detailTextLabel?.text = "5,000 Gallons"
            default:
                break
            }
            return cell
        case 4:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Generators"
                cell.detailTextLabel?.text = "5,000 Gallons"
            default:
                break
            }
            return cell
            
        default:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Lights"
                cell.detailTextLabel?.text = "5,000 Gallons"
            case 1:
                cell.textLabel?.text = "Lights"
                cell.detailTextLabel?.text = "5,000 Gallons"
            case 2:
                cell.textLabel?.text = "Carts"
                cell.detailTextLabel?.text = "15,000 Gallons"
            default:
                break
            }
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
