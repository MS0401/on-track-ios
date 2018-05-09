//
//  ItemStaffViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/6/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import TwicketSegmentedControl
import SwiftDate
import Alamofire
import SwiftyJSON

class ItemStaffViewController: UIViewController, SettingsViewDelegate, TwicketSegmentedControlDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var equipmentButton: UIButton!
    @IBOutlet weak var segmentedControl: TwicketSegmentedControl!
    
    let realm = try! Realm()
    var staff: User!
    var toggleEquipment = false
    internal var count: Int = 0
    internal var tbHeight: Int = 0
    var viewItems = [String]()
    var imageName = [String]()
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        return st
    }()
    var titles = ["Scans", "Inventory"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = staff.name
        tableView.tableFooterView = UIView()
        
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        
        /*
        equipmentButton.setTitle("\(staff.equipment.count) equipment assigned", for: .normal)
        equipmentButton.layer.cornerRadius = 4
        equipmentButton.layer.borderWidth = 1
        equipmentButton.layer.borderColor = UIColor.flatSkyBlue.cgColor
        equipmentButton.setTitleColor(UIColor.flatSkyBlue, for: .normal)
        */
        
        setupSettingsView()
        getStaffMember(eventId: 1, userId: staff.id) {
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
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
        count = 4
        tbHeight = 48 * count
        
        let originalFrame = settingsView.tableView.frame
        let newHeight = count * tbHeight
        settingsView.tableView.frame = CGRect(x: originalFrame.origin.x, y: originalFrame.origin.y, width: originalFrame.size.width, height:CGFloat(Int(newHeight)))
        
        viewItems.append("Text \(staff.name)")
        imageName.append("comments")
        viewItems.append("Call \(staff.name)")
        imageName.append("phone")
        viewItems.append("Assign Equipment")
        imageName.append("blue_scan")
        viewItems.append("Remove Equipment")
        imageName.append("blue_scan")
        settingsView.items = viewItems
        settingsView.imageNames = imageName
    }
    
    func didSelectRow(indexPath: Int) {
        if indexPath == 0 {
            
            if staff.cell != "" {
                let number = "sms:+1\(String(describing: staff.cell))"
                UIApplication.shared.openURL(NSURL(string: number)! as URL)
            } else {
                throwAlert()
            }
            
        } else if indexPath == 1 {
            if staff.cell != "" {
                callDriver()
            } else {
                throwAlert()
            }
        } else if indexPath == 2 {
            let ac = UIAlertController(title: "Associate", message: "Associate Inventory Item", preferredStyle: .alert)
            ac.addTextField { (textfield) in
                textfield.keyboardType = .numberPad
            }
            let aAction = UIAlertAction(title: "Associate", style: .default, handler: { (action) in
                
                self.associateItem(inventoryId: Int(ac.textFields![0].text!)!, userId: self.staff.id, completion: {
                    
                })
            })
            
            let cAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            ac.addAction(aAction)
            ac.addAction(cAction)
            
            present(ac, animated: true, completion: nil)
        } else if indexPath == 3 {
            let ac = UIAlertController(title: "Remove", message: "Remove Inventory Item", preferredStyle: .alert)
            ac.addTextField { (textfield) in
                textfield.keyboardType = .numberPad
            }
            let aAction = UIAlertAction(title: "Remove", style: .default, handler: { (action) in
                
                self.removeItem(inventoryId: Int(ac.textFields![0].text!)!, userId: self.staff.id, completion: {
                    
                })
            })
            
            let cAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            ac.addAction(aAction)
            ac.addAction(cAction)
            
            present(ac, animated: true, completion: nil)
        }
    }
    
    func getStaffMember(eventId: Int, userId: Int, completion: @escaping () -> ()) {
        
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/users/\(userId)?event_id=\(eventId)"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                
                completion()
            case .failure:
                break
            }
        }
    }
    
    
    func associateItem(inventoryId: Int, userId: Int, completion: @escaping () -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/scans/\(inventoryId)/associate"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let params = [
            "event_id": 1,
            "inventory_id": inventoryId,
            "user_id": userId
            ] as [String : Any]
        
        
        Alamofire.request(path, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            print(response)
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let code = json["meta"]["code"].intValue
                let meta = json["meta"]
                
                if code == 200 {
                    completion()
                } else {
                    //Not received
                    print(meta)
                }
                
            case .failure:
                break
            }
        }
    }
    
    func removeItem(inventoryId: Int, userId: Int, completion: @escaping () -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/scans/\(inventoryId)/disassociate"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let params = [
            "event_id": 1,
            "inventory_id": inventoryId,
            "user_id": userId
            ] as [String : Any]
        
        
        Alamofire.request(path, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            print(response)
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let code = json["meta"]["code"].intValue
                let meta = json["meta"]
                
                if code == 200 {
                    completion()
                } else {
                    //Not received
                    print(meta)
                }
                
            case .failure:
                break
            }
        }
    }
    
    func throwAlert() {
        let alert = UIAlertController(title: "Driver Cell", message: "Driver Cell was not provided", preferredStyle: UIAlertControllerStyle.alert)
        let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true, completion: nil)
    }
    
    func hideSettingsView(status: Bool) {
        if status == true {
            settingsView.removeFromSuperview()
        }
    }
    
    func callDriver() {
        if staff.cell != nil {
            UIApplication.shared.open(URL(string: "telprompt://1\(String(describing: staff.cell))")!, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func moreAction(_ sender: Any) {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
        }
    }
    
    @IBAction func toggle(_ sender: UIButton) {

        if toggleEquipment == true {
            toggleEquipment = false
            //equipmentButton.setTitle("\(staff.equipment.count) Equipment", for: .normal)
        } else {
            toggleEquipment = true
            //equipmentButton.setTitle("\(staff.scans.count) Scans", for: .normal)
        }
        
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*
        if segue.identifier == "staffToEquipmentSegue" {
            let radio = sender as! Equipment
            let dvc = segue.destination as! RadioDetailViewController
            dvc.radio = radio
        } else if segue.identifier == "staffScanEquipmentSegue" {
            if #available(iOS 11.0, *) {
                let dvc = segue.destination as! BarcodeScannerViewController
                dvc.staff = self.staff
                dvc.isFromStaff = true
            } else {
                // Fallback on earlier versions
            }
        }
        */
    }
}

extension ItemStaffViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return 5//staff.scans.count
        } else {
            return 5//staff.equipment.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ItemTableViewCell
        return cell
        /*
        if segmentedControl.selectedSegmentIndex == 0  {
            let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ItemTableViewCell
            let scan = staff.scans[indexPath.row]
            cell.checkOutLabel.text = "\(scan.reason!): \(scan.equipmentStatus)"
            cell.timeLabel.text = scan.created_at
            switch scan.reason {
            case "checkout"?:
                cell.reasonView.backgroundColor = UIColor.flatGreen
            case "return"?:
                cell.reasonView.backgroundColor = UIColor.flatSkyBlue
            default:
                cell.reasonView.backgroundColor = UIColor.flatSkyBlue
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "staffEquipmentCell", for: indexPath) as! ItemTableViewCell
            let scan = staff.equipment[indexPath.row]
            cell.checkOutLabel.text = "\(scan.type) ID: \(scan.id)"
            cell.timeLabel.text = "Assigned"
            cell.itemImageView.layer.cornerRadius = 4
            //cell.textLabel?.text = scan.name
            //cell.detailTextLabel?.text = scan.createdAt
            return cell
        }
        */
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        /*
        var radio: Equipment!
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            print("false")
            //equipment = staff.scans[indexPath.row]
        case 1:
            radio = staff.equipment[indexPath.row]
            
            let alertController = UIAlertController(title: "Return \(radio.type)", message: "Return \(radio.type) ID: \(radio.id)", preferredStyle: .alert)
            let returnAction = UIAlertAction(title: "Return", style: .default, handler: { (action) in
                let now = DateInRegion()
                let scan = Scan()
                scan.reason = "return"
                scan.created_at = now.string()
                scan.equipmentStatus = "\(radio.type) ID: \(radio.id)"
                
                let rid = radio.assignedId
                let dr = self.realm.objects(RealmDriver.self).filter("id == %@", rid).first
                let i = dr?.equipment.index(of: radio)
                
                scan.driverName = dr?.name
                
                try! self.self.realm.write {
                    radio.status = 1
                    radio.assignedTo = ""
                    radio.assignedId = 0
                    radio.scans.append(scan)
                    dr?.scans.append(scan)
                    if i != nil {
                        dr?.equipment.remove(objectAtIndex: i!)
                    }
                    self.tableView.reloadData()
                }
            })
            
            let itemAction = UIAlertAction(title: "View Item", style: .default, handler: { (action) in
                self.performSegue(withIdentifier: "staffToEquipmentSegue", sender: radio)
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alertController.addAction(returnAction)
            alertController.addAction(itemAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)

        default:
            break
        }
        */
    }
}
