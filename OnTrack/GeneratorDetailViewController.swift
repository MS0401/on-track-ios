//
//  GeneratorDetailViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/29/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import SwiftDate
import RealmSwift
import Alamofire
import SwiftyJSON
import ActionCableClient
import TwicketSegmentedControl
import ACProgressHUD_Swift

typealias Params = [String: String]

class GeneratorDetailViewController: UIViewController, SettingsViewDelegate, TwicketSegmentedControlDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var uidLabel: UILabel!
    //@IBOutlet weak var fuelLabel: UILabel!
    //@IBOutlet weak var departmentLabel: UILabel!
    //@IBOutlet weak var collectionView: UICollectionView!
    //@IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var segmentedControl: TwicketSegmentedControl!
    
    let realm = try! Realm()
    internal var count: Int = 0
    internal var tbHeight: Int = 0
    var viewItems = [String]()
    var imageName = [String]()
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        return st
    }()
    var departments = ["Transportation", "Site Ops", "Food & Beverage", "Artist Compound", "Perimeter"]
    var scans = [InventoryScan]()
    var images = [UIImage]()
    var originalImage: UIImage!
    var ip: Int!
    var inventoryItem: Inventory!
    var client = ActionCableClient(url: URL(string: "wss://ontrackinventory.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "InventoryChannel"
    var id: Int!
    var titles = ["Scans", "Inventory"]
    var accessories = [Inventory]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for scan in self.inventoryItem.scans {
            self.scans.append(scan)
        }
        
        for inventory in self.inventoryItem.accessories {
            self.accessories.append(inventory)
        }
        
        self.accessories = self.accessories.sorted { $0.id < $1.id }.reversed()
        self.scans = self.scans.sorted { $0.id < $1.id }.reversed()
        
        //print(inventoryItem)
        
        DispatchQueue.main.async {
            self.title = "\(self.inventoryItem.name)"
            //self.nameLabel.text = ""//"\(self.inventoryItem.name)"
            self.uidLabel.text = "UID: \(self.inventoryItem.uid)"
            self.tableView.reloadData()
        }
        
        tableView.tableFooterView = UIView()
        
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        
        /*
        getInventoryItem(id: id) { (item) in
            self.inventoryItem = item
            
            for scan in self.inventoryItem.scans {
                self.scans.append(scan)
            }
            
            self.scans = self.scans.reversed()
            
            DispatchQueue.main.async {
                self.nameLabel.text = "\(self.inventoryItem.name)"
                self.uidLabel.text = "UID \(self.inventoryItem.id)"
                self.tableView.reloadData()
            }
            
            print(self.inventoryItem)
        }
        */
        
        setupSettingsView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupActionCable()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        client.disconnect()
    }
    
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
    
    func setupSettingsView() {
        count = 8
        tbHeight = 48 * count
        
        let originalFrame = settingsView.tableView.frame
        let newHeight = count * tbHeight
        settingsView.tableView.frame = CGRect(x: originalFrame.origin.x, y: originalFrame.origin.y, width: originalFrame.size.width, height:CGFloat(Int(newHeight)))
        
        viewItems.append("Add Fuel")
        imageName.append("blue_scan")
        viewItems.append("New Scan")
        imageName.append("blue_scan")
        viewItems.append("Assign to Department")
        imageName.append("blue_scan")
        /*
        viewItems.append("Assign to Staff Member")
        imageName.append("blue_scan")
        */
        viewItems.append("Add Images")
        imageName.append("blue_scan")
        viewItems.append("Add Location Description")
        imageName.append("blue_scan")
        viewItems.append("Update UID")
        imageName.append("blue_scan")
        
        viewItems.append("Associate Inventory")
        imageName.append("blue_scan")
        viewItems.append("Remove Inventory")
        imageName.append("blue_scan")
        /*
        viewItems.append("Report Incident")
        imageName.append("blue_scan")
        viewItems.append("Associate Inventory")
        imageName.append("blue_scan")
        viewItems.append("Remove Inventory")
        imageName.append("blue_scan")
        viewItems.append("Refresh")
        imageName.append("blue_scan")
        */
        settingsView.items = viewItems
        settingsView.imageNames = imageName
    }
    
    func createScan() {
        let ac = UIAlertController(title: "Scan", message: "Scan Item", preferredStyle: .alert)
        /*
        let dialog = AZDialogViewController(title: "Scan", message: "Scan inventory item")
        
        dialog.dismissDirection = .bottom
        dialog.dismissWithOutsideTouch = true
        dialog.showSeparator = false
        dialog.separatorColor = UIColor.flatSkyBlue
        dialog.allowDragGesture = true
        
        dialog.buttonStyle = { (button,height,position) in
            //button.setBackgroundImage(UIImage.imageWithColor(self.primaryColorDark), for: .highlighted)
            button.setTitleColor(UIColor.white, for: .highlighted)
            button.setTitleColor(UIColor.flatSkyBlue, for: .normal)
            button.layer.masksToBounds = true
            button.layer.borderColor = UIColor.flatSkyBlue.cgColor//self.primaryColor.cgColor
        }
        
        dialog.addAction(AZDialogAction(title: "Received") { (dialog) -> (Void) in
            
            dialog.dismiss()
            
            self.postScan(scanType: "received", inventoryId: self.inventoryItem.id, fuel: nil, parentId: nil, fuelType: nil, completion: {
                
            })
        })
        
        dialog.addAction(AZDialogAction(title: "Assigned") { (dialog) -> (Void) in
           
            dialog.dismiss()
            
            self.postScan(scanType: "assigned", inventoryId: self.inventoryItem.id, fuel: nil, parentId: nil, fuelType: nil, completion: {
                
            })
        })
        
        dialog.addAction(AZDialogAction(title: "Check In") { (dialog) -> (Void) in

            dialog.dismiss()
            
            self.postScan(scanType: "checked_in", inventoryId: self.inventoryItem.id, fuel: nil, parentId: nil, fuelType: nil, completion: {
                
            })
        })
        
        dialog.addAction(AZDialogAction(title: "Check Out") { (dialog) -> (Void) in
            
            dialog.dismiss()
            
            self.postScan(scanType: "checked_out", inventoryId: self.inventoryItem.id, fuel: nil, parentId: nil, fuelType: nil, completion: {
                
            })
        })
        
        dialog.addAction(AZDialogAction(title: "Out of Service") { (dialog) -> (Void) in
            
            dialog.dismiss()
            
            self.postScan(scanType: "out_of_service", inventoryId: self.inventoryItem.id, fuel: nil, parentId: nil, fuelType: nil, completion: {
                
            })
        })
        
        dialog.cancelEnabled = true
        
        dialog.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor.flatSkyBlue
            button.setTitle("CANCEL", for: [])
            return true //must return true, otherwise cancel button won't show.
        }
        
        self.present(dialog, animated: false, completion: nil)
        */

        let received = UIAlertAction(title: "Received", style: .default, handler: { (action) in
            
            let progressView = ACProgressHUD.shared
            progressView.progressText = "Sending Scan..."
            progressView.showHUD()
            
            self.postScan(scanType: "received", inventoryId: self.inventoryItem.id, fuel: nil, parentId: nil, fuelType: nil, completion: {
                progressView.hideHUD()
            })
        })
        
        let assigned = UIAlertAction(title: "Assigned", style: .default, handler: { (action) in
            
            let progressView = ACProgressHUD.shared
            progressView.progressText = "Sending Scan..."
            progressView.showHUD()
            
            self.postScan(scanType: "assigned", inventoryId: self.inventoryItem.id, fuel: nil, parentId: nil, fuelType: nil, completion: {
                progressView.hideHUD()
            })
        })
        /*
        let checkin = UIAlertAction(title: "Check In", style: .default, handler: { (action) in
            self.postScan(scanType: "checked_in", inventoryId: self.inventoryItem.id, fuel: nil, parentId: nil, completion: {
                
            })
        })
        
        let checkout = UIAlertAction(title: "Check Out", style: .default, handler: { (action) in
            self.postScan(scanType: "checked_out", inventoryId: self.inventoryItem.id, fuel: nil, parentId: nil, completion: {
                
            })
        })
        */
        let out = UIAlertAction(title: "Out of Service", style: .default, handler: { (action) in
            
            let progressView = ACProgressHUD.shared
            progressView.progressText = "Sending Scan..."
            progressView.showHUD()
            
            self.postScan(scanType: "out_of_service", inventoryId: self.inventoryItem.id, fuel: nil, parentId: nil, fuelType: nil, completion: {
                progressView.hideHUD()
            })
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
        })
        
        ac.addAction(received)
        ac.addAction(assigned)
        //ac.addAction(checkin)
        //ac.addAction(checkout)
        ac.addAction(out)
        ac.addAction(cancel)
        self.present(ac, animated: true, completion: nil)

    }
    
    func createIncident(departmentId: Int, inventoryId: Int, description: String, status: String) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/incidents"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let parameters = [
            "event_id": 1,
            "department_id": departmentId,
            "inventory_id": inventoryId,
            "description": description,
            "status": status,
            "incident_type": "inventory",
            "location_attributes": ["longitude": "\(user!.lastLocation!.longitude)", "latitude": "\(user!.lastLocation!.latitude)"],
            "images": [["base64_image": ""]]
            
        ] as [String : Any]
        
        Alamofire.request(path, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(response)
                
            case .failure:
                break
            }
        }
    }
    
    func assignDepartment() {
        let ac = UIAlertController(title: "Assign Department", message: "Please assign a department", preferredStyle: .alert)
        let dept = UIAlertAction(title: "Exterior Perimeter", style: .default) { (action) in
            
            let progressView = ACProgressHUD.shared
            progressView.progressText = "Assigning Department..."
            progressView.showHUD()
            
            self.changeDepartment(id: self.inventoryItem.id, departmentId: 1, completion: {
                progressView.hideHUD()
            })
        }
        
        let dept2 = UIAlertAction(title: "Interior Venue", style: .default) { (action) in
            
            let progressView = ACProgressHUD.shared
            progressView.progressText = "Assigning Department..."
            progressView.showHUD()
            
            self.changeDepartment(id: self.inventoryItem.id, departmentId: 2, completion: {
                progressView.hideHUD()
            })
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        ac.addAction(dept)
        ac.addAction(dept2)
        ac.addAction(cancel)
        self.present(ac, animated: true, completion: nil)
        /*
        let dialog = AZDialogViewController(title: "Scan", message: "Scan inventory item")
        
        dialog.dismissDirection = .bottom
        dialog.dismissWithOutsideTouch = true
        dialog.showSeparator = false
        dialog.separatorColor = UIColor.flatSkyBlue
        dialog.allowDragGesture = true
        
        dialog.buttonStyle = { (button,height,position) in
            //button.setBackgroundImage(UIImage.imageWithColor(self.primaryColorDark), for: .highlighted)
            button.setTitleColor(UIColor.white, for: .highlighted)
            button.setTitleColor(UIColor.flatSkyBlue, for: .normal)
            button.layer.masksToBounds = true
            button.layer.borderColor = UIColor.flatSkyBlue.cgColor//self.primaryColor.cgColor
        }
        
        
            
        dialog.addAction(AZDialogAction(title: "Site Ops") { (dialog) -> (Void) in
            
            dialog.dismiss()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.changeDepartment(id: self.inventoryItem.id, departmentId: 1)
            }
            
        })
        
        dialog.addAction(AZDialogAction(title: "Transportation") { (dialog) -> (Void) in
            
            dialog.dismiss()
            
            self.changeDepartment(id: self.inventoryItem.id, departmentId: 2)
            
        })
        
        
        dialog.cancelEnabled = true
        
        dialog.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor.flatSkyBlue
            button.setTitle("CANCEL", for: [])
            return true //must return true, otherwise cancel button won't show.
        }
        
        */
        
        //self.present(dialog, animated: false, completion: nil)
        
    }
    
    func didSelectRow(indexPath: Int) {
        
        switch indexPath {
        case 0:
            let ac = UIAlertController(title: "Add Fuel", message: "Add fuel to Light Tower", preferredStyle: .alert)
            ac.addTextField { (textfield) in
                textfield.keyboardType = .decimalPad
                //textfield.text = "\(50)"
            }
            let aAction = UIAlertAction(title: "Add Fuel", style: .default, handler: { (action) in
                
                let progressView = ACProgressHUD.shared
                progressView.progressText = "Sending Scan..."
                progressView.showHUD()
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    
                    self.postScan(scanType: "fuel", inventoryId: self.inventoryItem.id, fuel: ac.textFields![0].text, parentId: nil, fuelType: 1, completion: {
                        
                        //progressView.progressText = "Success"
                        //progressView.showHUD()
                        
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                            progressView.hideHUD()
                        }
                    })
                }
                //progressView.hideHUD()
            })
            /*
            let bAction = UIAlertAction(title: "Red Dot", style: .default, handler: { (action) in
                
                self.postScan(scanType: "fuel", inventoryId: self.inventoryItem.id, fuel: ac.textFields![0].text, parentId: nil, fuelType: 2, completion: {
                    
                })
            })
            
            let cAction = UIAlertAction(title: "Unleaded", style: .default, handler: { (action) in
                
                self.postScan(scanType: "fuel", inventoryId: self.inventoryItem.id, fuel: ac.textFields![0].text, parentId: nil, fuelType: 3, completion: {
                    
                })
            })
            
            let dAction = UIAlertAction(title: "Propane", style: .default, handler: { (action) in
                
                self.postScan(scanType: "fuel", inventoryId: self.inventoryItem.id, fuel: ac.textFields![0].text, parentId: nil, fuelType: 4, completion: {
                    
                })
            })
            */
   
            let eAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            ac.addAction(aAction)
            /*
            ac.addAction(bAction)
            ac.addAction(cAction)
            ac.addAction(dAction)
            */
            ac.addAction(eAction)
            
            present(ac, animated: true, completion: nil)
        case 1:
            createScan()
        case 2:
            assignDepartment()
        case 3:
            popImagePicker()
        case 4:
            print("location")
            /*
            let ac = UIAlertController(title: "Add Location", message: "Add location description", preferredStyle: .alert)
            ac.addTextField { (textfield) in
                textfield.keyboardType = .default
                //textfield.text = "\(50)"
            }
            let aAction = UIAlertAction(title: "Add Location", style: .default, handler: { (action) in
                
                let progressView = ACProgressHUD.shared
                progressView.progressText = "Sending Update..."
                progressView.showHUD()
                
                self.addLocationDescription(id: self.inventoryItem.id, locationDescription: "\((ac.textFields?.first?.text)!)", completion: {
                    progressView.hideHUD()
                })
                
                
            })
            
            let eAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            ac.addAction(aAction)
            ac.addAction(eAction)
            
            present(ac, animated: true, completion: nil)
            */

        case 5:
            let ac = UIAlertController(title: "Update UID", message: "Update Unique Identifier", preferredStyle: .alert)
            ac.addTextField { (textfield) in
                textfield.keyboardType = .numbersAndPunctuation
            }
            
            let aAction = UIAlertAction(title: "Update UID", style: .default, handler: { (action) in
                
                self.updateUID(id: self.inventoryItem.id, uid: (ac.textFields?.first?.text)!, completion: {
                    
                })
            })
            
            let eAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            ac.addAction(aAction)
            ac.addAction(eAction)
            
            present(ac, animated: true, completion: nil)
            //createIncident(departmentId: 1, inventoryId: inventoryItem.id, description: "Created Incident", status: "open")
        case 6:
            let ac = UIAlertController(title: "Associate", message: "Associate Inventory Item", preferredStyle: .alert)
            ac.addTextField { (textfield) in
                textfield.keyboardType = .numberPad
            }
            let aAction = UIAlertAction(title: "Associate", style: .default, handler: { (action) in
                
                self.postScan(scanType: "associated", inventoryId: Int(ac.textFields![0].text!)!, fuel: nil, parentId: self.inventoryItem.id, fuelType: nil, completion: {
                    
                })
            })
            
            let cAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            ac.addAction(aAction)
            ac.addAction(cAction)
            
            present(ac, animated: true, completion: nil)
            
            
        case 7:
            let ac = UIAlertController(title: "Remove Assoication", message: "Remove associated item", preferredStyle: .alert)
            ac.addTextField { (textfield) in
                textfield.keyboardType = .numberPad
            }
            let aAction = UIAlertAction(title: "Remove", style: .default, handler: { (action) in
                
                self.postScan(scanType: "disassociated", inventoryId: Int(ac.textFields![0].text!)!, fuel: nil, parentId: self.inventoryItem.id, fuelType: nil, completion: {
                    
                })
            })
            
            let cAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            ac.addAction(aAction)
            ac.addAction(cAction)
            
            present(ac, animated: true, completion: nil)
            
        case 8:
            print("refresh")
        default:
            break
        }
        
    }
    /*
    func addImagesAlert() {
        let ac = UIAlertController(title: "Add Image", message: "Add Image", preferredStyle: .alert)
        let aa1 = UIAlertAction(title: "Front", style: .default, handler: { (action) in
            self.popImagePicker(item: 0)
        })
        
        let aa2 = UIAlertAction(title: "Side One", style: .default, handler: { (action) in
            self.popImagePicker(item: 1)
        })
        
        let aa3 = UIAlertAction(title: "Back", style: .default, handler: { (action) in
            self.popImagePicker(item: 2)
        })
        
        let aa4 = UIAlertAction(title: "Side Two", style: .default, handler: { (action) in
            self.popImagePicker(item: 3)
        })
        
        let cancel = UIAlertAction(title: "Done", style: .default, handler: { (action) in
            let img = UIImage(named: "gen")
            self.images.insert(img!, at: 4)
            //self.collectionView.reloadData()
        })
        
        ac.addAction(aa1)
        ac.addAction(aa2)
        ac.addAction(aa3)
        ac.addAction(aa4)
        ac.addAction(cancel)
        
        present(ac, animated: true, completion: {
            
        })
    }
    */
    
    func hideSettingsView(status: Bool) {
        if status == true {
            settingsView.removeFromSuperview()
        }
    }
    
    @IBAction func moreAction(_ sender: Any) {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
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
        
        let id = ["event_id": 1, "inventory_id": inventoryItem.id]
        
        self.channel = client.create(GeneratorDetailViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        //self.channel = client.create(PMDashboardViewController.ChannelIdentifier)
        
        self.channel?.onSubscribed = {
            print("Subscribed to \(GeneratorDetailViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let json = JSON(data!)
            
            print("JSON FROM ACTION CABLE \(json)")
            
            //let ii = Inventory(json: json)
            //self.inventoryItem = ii
            
            
            self.scans.removeAll()
            self.inventoryItem.scans.removeAll()
            for scan in json["all_scans"].arrayValue {
                let s = InventoryScan(json: scan)
                self.scans.append(s)
                self.inventoryItem.scans.append(s)
            }
            
            self.inventoryItem.departmentName = json["department"]["name"].stringValue
            self.inventoryItem.parentId = json["parent_id"].intValue
            
            if json["description"] != JSON.null {
                self.inventoryItem.locationDescription = json["description"].stringValue
                print("from action cable \(self.inventoryItem.locationDescription)")
            }
            
            self.uidLabel.text = "UID: \(json["uid"].stringValue)"
            
            let scan = InventoryScan(json: json["last_scan"])
            self.inventoryItem.lastScan = scan
            
            self.accessories.removeAll()
            for a in json["accessories"].arrayValue {
                let i = Inventory(json: a)
                if i.id != self.inventoryItem.id {
                    self.accessories.append(i)
                }
            }
            
            self.inventoryItem.images.removeAll()
            for i in json["all_images"].arrayValue {
                let m = Media()
                m.imageUrl = i.stringValue
                self.inventoryItem.images.append(m)
            }
            
            self.accessories = self.accessories.sorted { $0.id < $1.id }.reversed()
            self.scans = self.scans.sorted { $0.id < $1.id }.reversed()
            
            let storyboard = UIStoryboard(name: "Inventory", bundle: Bundle.main)
            
            let viewController = storyboard.instantiateViewController(withIdentifier: "InventoryStatsViewController") as! InventoryStatsViewController
            viewController.inventoryItem = self.inventoryItem
            
            let viewController1 = storyboard.instantiateViewController(withIdentifier: "InventoryImagesViewController") as! InventoryImagesViewController
            viewController1.inventoryItem = self.inventoryItem
            
            let viewController2 = storyboard.instantiateViewController(withIdentifier: "InventoryItemMapViewController") as! InventoryItemMapViewController
            viewController2.inventoryItem = self.inventoryItem
            
            let viewController3 = storyboard.instantiateViewController(withIdentifier: "InventoryDetailsViewController") as! InventoryDetailsViewController
            viewController3.inventoryItem = self.inventoryItem
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "inventory"), object: self)
                self.tableView.reloadData()
            }
        }
        
        self.client.connect()
    }
    
    
    func changeDepartment(id: Int, departmentId: Int, completion: @escaping () -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/\(id)?company_id=1&department_id=\(departmentId)"

        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let parameters = [
            "company_id": 1,
            "department_id": 1
        ]
        
        Alamofire.request(path, method: .put, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(response)
                completion()
                //self.loadingIndicator(title: "Assigning Department...", message: "Please wait untile completed", dialogTitle: "Success", dialogMessage: "Inventory item has been reassigned", dialogButtonTitle: "OK")
            case .failure:
                break
            }
        }
    }
    
    func updateUID(id: Int, uid: String, completion: @escaping () -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/\(id)?company_id=1&uid=\(uid)"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let parameters = [
            "company_id": 1,
            "department_id": 1
        ]
        
        Alamofire.request(path, method: .put, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(response)
                completion()
            //self.loadingIndicator(title: "Assigning Department...", message: "Please wait untile completed", dialogTitle: "Success", dialogMessage: "Inventory item has been reassigned", dialogButtonTitle: "OK")
            case .failure:
                break
            }
        }
    }
    
    func addLocationDescription(id: Int, locationDescription: String, completion: @escaping () -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/\(id)?description=\(locationDescription)"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let parameters = [
            "company_id": 1
        ]
        
        Alamofire.request(path, method: .put, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(response)
                completion()
            //self.loadingIndicator(title: "Assigning Department...", message: "Please wait untile completed", dialogTitle: "Success", dialogMessage: "Inventory item has been reassigned", dialogButtonTitle: "OK")
            case .failure:
                break
            }
        }
    }
    
    
    func uploadImage(id: Int, image: String) {
        
        let progressView = ACProgressHUD.shared
        progressView.progressText = "Uploading Image..."
        progressView.showHUD()
        
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/\(id)/upload_images"
        //print(path)
        let headers = [
            "Content-type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        //var multi = MultipartFormData()
        //multi.append(imageData, withName: "image", fileName: "image.png", mimeType: "image/png")
        //multi = multipartFormData
        
        let parameters = [
            "images": [
                 ["image": "data:image/png;base64,\(image)"]
            ]
        ] as [String: Any]

        Alamofire.request(path, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            print(response)
            
            if let requestBody = response.request?.httpBody {
                do {
                    let jsonArray = try JSONSerialization.jsonObject(with: requestBody, options: [])
                    //print("Array: \(jsonArray)")
                }
                catch {
                    print("Error: \(error)")
                }
            }
           
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                
                /*
                self.loadingIndicator(title: "Uploading...", message: "Uploading image, please wait", dialogTitle: "Success!", dialogMessage: "Image Uploaded", dialogButtonTitle: "Add Image")
                */
                progressView.hideHUD()
                
                let ac = UIAlertController(title: "Success", message: "Image uploaded", preferredStyle: .alert)
                
                let a1 = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    
                })
                
                let a2 = UIAlertAction(title: "Add Image", style: .default, handler: { (action) in
                    self.popImagePicker()
                })
                
                ac.addAction(a1)
                ac.addAction(a2)
                
                self.present(ac, animated: true, completion: nil)
            
            case .failure:
                progressView.hideHUD()
                break
            }
        }
 
    }
    
    func postScan(scanType: String, inventoryId: Int, fuel: String?, parentId: Int?, fuelType: Int?, completion: @escaping () -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/scans"
        let lat = String(describing: user!.lastLocation!.latitude)
        let long = String(describing: user!.lastLocation!.longitude)
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let params = [
            "event_id": 1,
            "scan_type": scanType,
            "latitude": lat,
            "longitude": long,
            "inventory_id": inventoryId,
            "quantity": fuel,
            "parent_id": parentId,
            "fuel_type_id": fuelType
            ] as [String : Any]
        
        print(params)
        
        Alamofire.request(path, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            print(response.request?.httpBody)
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let code = json["meta"]["code"].intValue
                let meta = json["meta"]
                
                if code == 200 {
                    //self.loadingIndicator(title: "Scan...", message: "Sending Scan, please wait", dialogTitle: "Success!", dialogMessage: "Scan Created", dialogButtonTitle: "Add Scan")
                    completion()
                } else {
                    //Not received
                    print(meta)
                    
                    let ac = UIAlertController(title: "Error", message: meta["message"].stringValue, preferredStyle: UIAlertControllerStyle.alert)
                    let aa = UIAlertAction(title: "OK", style: .default, handler: { (action) in

                    })
                    
                    ac.addAction(aa)
                    self.present(ac, animated: true, completion: nil)
                }
                
            case .failure:
                break
            }
        }
    }
    
    func getInventoryItem(id: Int, completion: @escaping (Inventory) -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/\(id)"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                
                let item = Inventory(json: json["data"])
                    
                completion(item)
                
            case .failure:
                break
            }
        }
    }
    
    
    func updateFuelQuantity(id: Int, quantity: String) {
        
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/scans/\(id)"
        //print(path)
        let headers = [
            "Content-type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let parameters = [
            "event_id": 1,
            "quantity": quantity
            ] as [String: Any]
        
        Alamofire.request(path, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(json)
            case .failure:
                break
            }
        }
        
    }
    func loadingIndicator(title: String, message: String, dialogTitle: String, dialogMessage: String, dialogButtonTitle: String){
        //Uploading...
        //"Uploading image, please wait"
        //"Success!"
        //"Image Uploaded"
        //"Add Image"
        let dialog = AZDialogViewController(title: title, message: message)
        
        let container = dialog.container
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        dialog.container.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        indicator.startAnimating()
        
        dialog.buttonStyle = { (button,height,position) in
            //button.setBackgroundImage(UIImage.imageWithColor(self.primaryColorDark), for: .highlighted)
            button.setTitleColor(UIColor.white, for: .highlighted)
            button.setTitleColor(UIColor.flatSkyBlue, for: .normal)
            button.layer.masksToBounds = true
            button.layer.borderColor = UIColor.flatSkyBlue.cgColor//self.primaryColor.cgColor
        }
        
        //dialog.animationDuration = 5.0
        dialog.customViewSizeRatio = 0.2
        dialog.dismissDirection = .none
        dialog.allowDragGesture = false
        dialog.dismissWithOutsideTouch = true
        
        dialog.cancelEnabled = true
        
        dialog.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor.flatSkyBlue
            button.setTitle("CANCEL", for: [])
            return true //must return true, otherwise cancel button won't show.
        }
        
        dialog.show(in: self)
        
        var when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            dialog.title = dialogTitle
            dialog.message = dialogMessage
            ///dialog.image = #imageLiteral(resourceName: "image")
            dialog.customViewSizeRatio = 0
            
            dialog.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                dialog.dismiss()
            }))
            
            dialog.addAction(AZDialogAction(title: dialogButtonTitle, handler: { (dialog) -> (Void) in
                dialog.dismiss()
                
                if dialogButtonTitle == "Add Scan" {
                    var when = DispatchTime.now() + 1
                    DispatchQueue.main.asyncAfter(deadline: when) {
                        self.createScan()
                    }
                } else if dialogButtonTitle == "Add Image" {
                    var when = DispatchTime.now() + 1
                    DispatchQueue.main.asyncAfter(deadline: when) {
                        self.popImagePicker()
                    }
                }
            }))
            
            //dialog.cancelEnabled = !dialog.cancelEnabled
            dialog.dismissDirection = .bottom
            dialog.allowDragGesture = true
        }
    
    }
    
  
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pageViewSegue" {
            //let when = DispatchTime.now() + 1
            //DispatchQueue.main.asyncAfter(deadline: when) {
            let dvc = segue.destination as! InventoryItemPageViewController
            dvc.inventoryItem = self.inventoryItem
            //}
        } else if segue.identifier == "selfSegue" {
            
            let dvc = segue.destination as! GeneratorDetailViewController
            
            
            //let s = sender as! Inventory
            dvc.inventoryItem = sender as! Inventory
            dvc.id = dvc.inventoryItem.id
            
        }
    }
}

extension GeneratorDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return scans.count
        case 1:
            return accessories.count
        default:
            return scans.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "generatorFuelCell", for: indexPath) as! ItemTableViewCell
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            let scan = scans[indexPath.row]
            let date = DateInRegion(string: scan.createdAt, format: DateFormat.iso8601Auto)?.string()
            print("from cell \(date)")
            /*
            if let d = date {
              cell.timeLabel.text = "\(d) Scan Id: \(scan.id)"
            } else {
                cell.timeLabel.text = "Scan Id: \(scan.id)"
            }
            */
            
            if let d = date {
                cell.timeLabel.text = "\(d)"
            }
            
            
            //print("\(date!) Scan Id: \(scan.id)")
            
            switch scan.scanType {
            case "received":
                cell.checkOutLabel.text = scan.scanType
                cell.reasonView.backgroundColor = UIColor.flatSkyBlue
            case "assigned":
                cell.checkOutLabel.text = scan.scanType
                cell.reasonView.backgroundColor = UIColor.flatGreen
            case "fuel":
                cell.checkOutLabel.text = "\(scan.scanType) gallons \(scan.fuelCount)"
                cell.reasonView.backgroundColor = UIColor.flatOrange
            case "out_of_service":
                cell.checkOutLabel.text = scan.scanType
                cell.reasonView.backgroundColor = UIColor.flatRed
            case "checked_in":
                cell.checkOutLabel.text = scan.scanType
                cell.reasonView.backgroundColor = UIColor.flatForestGreen
            case "checked_out":
                cell.checkOutLabel.text = scan.scanType
                cell.reasonView.backgroundColor = UIColor.flatBlueDark
            case "associated":
                if scan.accessoryId != 0 {
                    cell.checkOutLabel.text = "\(scan.scanType) with child id: \(scan.accessoryId)"
                } else {
                    cell.checkOutLabel.text = "\(scan.scanType) with parent id: \(scan.parentId)"
                }
                cell.reasonView.backgroundColor = UIColor.flatGray
            case "disassociated":
                if scan.accessoryId != 0 {
                    cell.checkOutLabel.text = "\(scan.scanType) with child id: \(scan.accessoryId)"
                } else {
                    cell.checkOutLabel.text = "\(scan.scanType) with parent id: \(scan.parentId)"
                }
                cell.reasonView.backgroundColor = UIColor.flatGray
            default:
                cell.reasonView.backgroundColor = UIColor.flatGray
            }
        case 1:
            let item = accessories[indexPath.row]
            cell.checkOutLabel.text = "\(item.name) \(item.id)"
            cell.timeLabel.text = item.lastScan?.scanType
            
            switch item.lastScan!.scanType {
            case "received":
                cell.reasonView.backgroundColor = UIColor.flatSkyBlue
            case "assigned":
                cell.reasonView.backgroundColor = UIColor.flatGreen
            case "fuel":
                cell.reasonView.backgroundColor = UIColor.flatOrange
            case "out_of_service":
                cell.reasonView.backgroundColor = UIColor.flatRed
            case "checked_in":
                cell.reasonView.backgroundColor = UIColor.flatForestGreen
            case "checked_out":
                cell.reasonView.backgroundColor = UIColor.flatBlueDark
                //cell.backgroundColor = UIColor.lightGray
            default:
                cell.reasonView.backgroundColor = UIColor.flatGray
            }
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            let scan = scans[indexPath.row]
            if scan.scanType == "fuel" {
                let ac = UIAlertController(title: "Adjust Fuel", message: "Adjust Fuel Total", preferredStyle: .alert)
                ac.addTextField { (textfield) in
                    textfield.keyboardType = .decimalPad
                }
                
                let aAction = UIAlertAction(title: "Adjust Fuel", style: .default, handler: { (action) in
                    
                    self.updateFuelQuantity(id: scan.id, quantity: (ac.textFields!.first?.text!)!)
                    
                })
                
                let eAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                ac.addAction(aAction)
                ac.addAction(eAction)
                
                present(ac, animated: true, completion: nil)
            } else {
                moreAction(self)
            }
            
        case 1:
            let item = accessories[indexPath.row]
            getInventoryItem(id: item.id, completion: { (inventory) in
                //print(inventory)
                self.performSegue(withIdentifier: "selfSegue", sender: inventory)
            })
            
        default:
            break
        }
    }
    
    /*
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            print("delete")
        case 1:
            if editingStyle == .delete {
                self.postScan(scanType: "disassociated", inventoryId: accessories[indexPath.row].id, fuel: nil, parentId: self.inventoryItem.id, fuelType: nil, completion: {
                    
                })
            }
        default:
            break
        }
    }
    */
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove"
    }
}
/*
extension GeneratorDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCollectionCell", for: indexPath) as! ImageCollectionViewCell
        cell.imageView.image = images[indexPath.row]
        cell.imageView.layer.cornerRadius = 5
        cell.imageView.layer.borderWidth = 2
        cell.imageView.layer.borderColor = UIColor.flatGray.cgColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        imageView.image = images[indexPath.item]
    }
}
*/
extension GeneratorDetailViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func popImagePicker() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            imagePicker.delegate = self
            
            imagePicker.modalPresentationStyle = .popover
            imagePicker.popoverPresentationController?.delegate = self
            imagePicker.popoverPresentationController?.sourceView = view
            imagePicker.modalPresentationStyle = .popover
            imagePicker.popoverPresentationController?.delegate = self
            imagePicker.popoverPresentationController?.sourceView = view
            //view.alpha = 0.5
            //imagePicker.tag = item
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        //addImagesAlert()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            // Use editedImage Here
            //print(picker.tag)
            originalImage = editedImage
            
            
            let img = originalImage
            let jpegCompressionQuality: CGFloat = 0.1
            //let data = UIImageJPEGRepresentation(img!, 1.0)
            
            //uploadImage(id: picker.tag!, imageData: data!)
            //requestWith(id: picker.tag!, imageData: data)
            
            
            if let base64String = UIImageJPEGRepresentation(originalImage.resize(maxWidthHeight: 200.0)!, jpegCompressionQuality)?.base64EncodedString() {
                // Upload base64String to your database
                //print(base64String)
                //self.setupActionCable()
                self.uploadImage(id: inventoryItem.id, image: base64String)
            }

           /*
            switch picker.tag! {
            case 0:
                images.insert(originalImage, at: 0)
                images.remove(at: 1)
                //collectionView.reloadData()
            case 1:
                images.insert(originalImage, at: 1)
                images.remove(at: 2)
                //collectionView.reloadData()
            case 2:
                images.insert(originalImage, at: 2)
                images.remove(at: 3)
                //collectionView.reloadData()
            case 3:
                images.insert(originalImage, at: 3)
                images.remove(at: 4)
                //collectionView.reloadData()
            default:
                break
            }
             */
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Use originalImage Here
            print("original")
        }
        
 
        picker.dismiss(animated: true)
        
        //addImagesAlert()
        //view.alpha = 1.0
    }
}

extension GeneratorDetailViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        //view.alpha = 1.0
    }
}
