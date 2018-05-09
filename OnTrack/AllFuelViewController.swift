//
//  AllFuelViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 10/17/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import UICircularProgressRing
import ActionCableClient
import SwiftyJSON
import Alamofire
import RealmSwift

let notificationKey = "reloadIndex"

class AllFuelViewController: UIViewController {
    
    @IBOutlet weak var progressRing: UICircularProgressRingView!
    //@IBOutlet weak var gallonsLabel: UILabel!
    @IBOutlet weak var dollarLabel: UILabel!
    @IBOutlet weak var fuelTypeLabel: UILabel!
    
    let realm = try! Realm()
    var index: Int?
    var client = ActionCableClient(url: URL(string: "wss://ontrackinventory.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "FuelTypeChannel"//"StatsChannel"
    var fuelTypes = [Fuel]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getAllFuel { (fuel) in
            self.fuelTypes = fuel
            self.refresh()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(AllFuelViewController.refresh), name: NSNotification.Name(rawValue: "fuel"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupActionCable()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        client.disconnect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
    }
    
    @objc func refresh() {
        switch index! {
        case 0:
            print("all fuel \(fuelTypes)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.progressRing.maxValue = CGFloat(self.fuelTypes[0].total)
                self.progressRing.setProgress(value: CGFloat(self.fuelTypes[0].total), animationDuration: 2.0)
                self.dollarLabel.text = "$\(self.fuelTypes[0].total * 3)"
                self.fuelTypeLabel.text = "\(self.fuelTypes[0].total) GALLONS TOTAL"
                self.progressRing.innerRingColor = UIColor.flatOrange
                self.dollarLabel.textColor = UIColor.flatOrange
                self.progressRing.fontColor = UIColor.flatOrange
                self.title = "ALL FUEL"
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationKey), object: 0)
            }
        case 1:
            print("1")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                self.progressRing.maxValue = CGFloat(self.fuelTypes[0].total)
                self.progressRing.setProgress(value: CGFloat(self.fuelTypes[1].total), animationDuration: 2.0)
                self.dollarLabel.text = "$\(self.fuelTypes[1].total * 3)"
                self.fuelTypeLabel.text = "\(self.fuelTypes[1].total) GALLONS DIESEL"
                self.progressRing.innerRingColor = UIColor.green
                self.dollarLabel.textColor = UIColor.green
                self.progressRing.fontColor = UIColor.green
                self.title = "DIESEL"
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationKey), object: 1)
            }
        case 2:
            print("2")
            progressRing.maxValue = CGFloat(self.fuelTypes[0].total)
            progressRing.setProgress(value: CGFloat(self.fuelTypes[2].total), animationDuration: 2.0)
            dollarLabel.text = "$\(self.fuelTypes[2].total * 2)"
            self.fuelTypeLabel.text = "\(self.fuelTypes[2].total) GALLONS RED DOT DIESEL"
            self.progressRing.innerRingColor = UIColor.flatRed
            self.dollarLabel.textColor = UIColor.flatRed
            self.progressRing.fontColor = UIColor.flatRed
            self.title = "RED DOT"
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationKey), object: 2)
        case 3:
            print("3")
            progressRing.maxValue = CGFloat(self.fuelTypes[0].total)
            progressRing.setProgress(value: CGFloat(self.fuelTypes[3].total), animationDuration: 2.0)
            dollarLabel.text = "$\(self.fuelTypes[3].total * 3)"
            self.fuelTypeLabel.text = "\(self.fuelTypes[3].total) GALLONS UNLEADED"
            self.progressRing.innerRingColor = UIColor.orange
            self.dollarLabel.textColor = UIColor.orange
            self.progressRing.fontColor = UIColor.orange
            self.title = "UNLEADED"
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationKey), object: 3)
        case 4:
            print("4")
            progressRing.maxValue = CGFloat(self.fuelTypes[0].total)
            progressRing.setProgress(value: CGFloat(self.fuelTypes[4].total), animationDuration: 2.0)
            dollarLabel.text = "$\(self.fuelTypes[4].total * 4)"
            self.fuelTypeLabel.text = "\(self.fuelTypes[4].total) GALLONS PROPANE"
            self.progressRing.innerRingColor = UIColor.flatSkyBlue
            self.dollarLabel.textColor = UIColor.flatSkyBlue
            self.progressRing.fontColor = UIColor.flatSkyBlue
            self.title = "PROPANE"
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationKey), object: 4)
        default:
            break
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
            print(response)
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
