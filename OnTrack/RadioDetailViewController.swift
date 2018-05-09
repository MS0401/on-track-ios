//
//  RadioDetailViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/6/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftDate

class RadioDetailViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var checkoutButton: UIButton!
    @IBOutlet weak var returnButton: UIButton!
    
    lazy var realm = try! Realm()
    var radio: Equipment!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Radio \(radio.id)"
        tableView.tableFooterView = UIView()
        setupButtons(radio: radio)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupButtons(radio: radio)
        tableView.reloadData()
    }
    
    func setupButtons(radio: Equipment) {
        
        checkoutButton.layer.cornerRadius = 4
        checkoutButton.layer.borderWidth = 1
        
        returnButton.layer.cornerRadius = 4
        returnButton.layer.borderWidth = 1
        
        switch radio.status {
        case 1,3:
            checkoutButton.isEnabled = true
            returnButton.isEnabled = false
            checkoutButton.setTitleColor(UIColor.flatSkyBlue, for: .normal)
            checkoutButton.layer.borderColor = UIColor.flatSkyBlue.cgColor
            returnButton.setTitleColor(UIColor.flatGray, for: .disabled)
            returnButton.layer.borderColor = UIColor.flatGray.cgColor
        case 2:
            checkoutButton.isEnabled = false
            returnButton.isEnabled = true
            checkoutButton.setTitleColor(UIColor.flatGray, for: .disabled)
            checkoutButton.layer.borderColor = UIColor.flatGray.cgColor
            returnButton.setTitleColor(UIColor.flatSkyBlue, for: .normal)
            returnButton.layer.borderColor = UIColor.flatSkyBlue.cgColor
        default:
            checkoutButton.isEnabled = true
            returnButton.isEnabled = true
            checkoutButton.setTitleColor(.white, for: .normal)
            checkoutButton.layer.borderColor = UIColor.white.cgColor
            returnButton.setTitleColor(UIColor.flatSkyBlue, for: .normal)
            returnButton.layer.borderColor = UIColor.flatSkyBlue.cgColor
        }
    }

    @IBAction func checkOutRadio(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Assign Staff", message: "Assign radio to staff member", preferredStyle: .alert)
        let submitAction = UIAlertAction(title: "Scan", style: UIAlertActionStyle.default) { (action) in
            self.performSegue(withIdentifier: "itemScanSegue", sender: self)
        }
        
        let searchAction = UIAlertAction(title: "Search Staff", style: .default) { (action) in
            self.performSegue(withIdentifier: "radioDetailStaffSegue", sender: self)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(submitAction)
        alertController.addAction(searchAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion:nil)
        
        /*
        let scan = Scan()
        scan.reason = "checkout"
        
        try! realm.write {
            radio.status = 2
            radio.scans.append(scan)
            self.tableView.reloadData()
            self.setupButtons(radio: radio)
        }
        */
    }
    
    @IBAction func returnRadio(_ sender: UIButton) {
        
        let alertController = UIAlertController(title: "Return Radio", message: "Return Radio back to inventory?", preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            let now = DateInRegion()
            let scan = Scan()
            scan.reason = "return"
            scan.created_at = now.string()
            scan.equipmentStatus = "\(self.radio.type) ID: \(self.radio.id)"
            
            let rid = self.radio.assignedId
            let dr = self.realm.objects(RealmDriver.self).filter("id == %@", rid).first
            let i = dr?.equipment.index(of: self.radio)
            
            scan.driverName = dr?.name
            
            try! self.realm.write {
                self.radio.status = 1
                self.radio.assignedTo = ""
                self.radio.assignedId = 0
                self.radio.scans.append(scan)
                dr?.scans.append(scan)
                
                if i != nil {
                    dr?.equipment.remove(objectAtIndex: i!)
                }
            
                self.tableView.reloadData()
                self.setupButtons(radio: self.radio)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "radioDetailStaffSegue" {
            let dvc = segue.destination as! SearchStaffViewController
            dvc.radio = radio
            dvc.isFromOtherVC = true
        } else if segue.identifier == "itemStaffSegue" {
            let id = sender as! Int
            if id == 0 || id == nil {
                
            } else {
                let staff = realm.objects(RealmDriver.self).filter("id == %@", id).first
                let dvc = segue.destination as! ItemStaffViewController
                //dvc.staff = staff
            }
        } else if segue.identifier == "itemScanSegue" {
            if #available(iOS 11.0, *) {
                let dvc = segue.destination as! BarcodeScannerViewController
                dvc.isFromItem = true
                dvc.item = self.radio
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

extension RadioDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return radio.scans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rdCell", for: indexPath) as! ItemTableViewCell
        let scan = radio.scans[indexPath.row]
        
        if let sdn = scan.driverName {
            cell.checkOutLabel.text = "\(scan.reason!): \(sdn)"
            cell.timeLabel.text = "Time: \(scan.created_at!)"
        }
        
            /*
        else {
            cell.checkOutLabel.text = "\(scan.reason!)"
            cell.timeLabel.text = "Time: \(scan.created_at!): \(scan.driverName!)"
        }
        */

        switch scan.reason {
        case "checkout"?:
            cell.reasonView.backgroundColor = UIColor.flatGreen
        case "return"?:
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
        default:
            cell.reasonView.backgroundColor = UIColor.flatGray
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let scan = radio.scans[indexPath.row]
        if scan.driver_id == 0 || scan.driver_id == nil {
            
        } else {
            performSegue(withIdentifier: "itemStaffSegue", sender: scan.driver_id)
        }
    }
}
