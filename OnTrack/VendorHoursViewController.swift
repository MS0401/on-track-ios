//
//  VendorHoursViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/11/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import UICircularProgressRing

class VendorHoursViewController: UIViewController, UICircularProgressRingDelegate {
    
    @IBOutlet weak var progressRing: UICircularProgressRingView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var negativeHours: UICircularProgressRingView!
    @IBOutlet weak var costPerHour: UICircularProgressRingView!
    @IBOutlet weak var totalHoursLabel: UILabel!
    @IBOutlet weak var completedHoursLabel: UILabel!
    @IBOutlet weak var negativeHoursLabel: UILabel!
    @IBOutlet weak var totalCostLabel: UILabel!
    
    var vendors = [String]()
    var time = [Int]()
    var ids = [Int]()
    var dict: [String: Any]!
    var total = ""
    var completed = ""
    var negative = ""
    var cost = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let dict = dict {
            
            title = dict["name"] as! String
            completed = "\(dict["completed"] as! Int)"
            total = "\(dict["total_time"] as! Int)"
            negative = "\(dict["time"] as! Int)"
            cost = "\(125 * (dict["time"] as! Int))"
            
            totalHoursLabel.text = "TOTAL HOURS \(total)"
            completedHoursLabel.text = "COMPLETED HOURS \(completed)"
            negativeHoursLabel.text = "NEGATIVE HOURS \(negative)"
            totalCostLabel.text = "TOTAL COST $\(cost)"
            
            var drivers = dict["drivers"]
            time.removeAll()
            vendors.removeAll()
            for driver in drivers as! Array<Any> {
                var d = driver as! [String: Any]
                vendors.append(d["name"] as! String)
                time.append(d["hours"] as! Int)
                ids.append(d["driverId"] as! Int)
            }
        
            progressRing.delegate = self
            negativeHours.delegate = self
            costPerHour.delegate = self
            
            progressRing.maxValue = CGFloat(dict["total_time"] as! Int)
            negativeHours.maxValue = CGFloat(dict["total_time"] as! Int)
            costPerHour.maxValue = CGFloat(dict["total_time"] as! Int) * 125.0
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.self.progressRing.setProgress(value: CGFloat(dict["completed"] as! Int), animationDuration: 1.0) {}
                self.negativeHours.setProgress(value: CGFloat(self.time.reduce(0,+)), animationDuration: 1.0) {}
                self.costPerHour.setProgress(value: CGFloat(125.0 * CGFloat(self.time.reduce(0,+))), animationDuration: 2.0) {}
            }
        }
        
        tableView.tableFooterView = UIView()
    }
    
    func finishedUpdatingProgress(forRing ring: UICircularProgressRingView) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let id = sender as! Int
        if segue.identifier == "statsDriverSegue" {
            let dvc = segue.destination as! DriverDetailViewController
            let driver = RealmDriver()
            let shift = Shift()
            
            driver.id = ids[id]
            shift.id = 1
            shift.eventId = 1
            shift.routeId = 1
            
            dvc.driver = driver
            dvc.driverId = ids[id]
            dvc.shift = shift
            
            if driver.id == 6 || driver.id == 7 {
                dvc.fromHours = true
                dvc.negativehours = 1
            }
        }
    }
}

extension VendorHoursViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vendors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "vendorDriverCell", for: indexPath)
        cell.textLabel?.text = vendors[indexPath.row]
        cell.detailTextLabel?.text = "\(time[indexPath.row]) Hours"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "statsDriverSegue", sender: indexPath.row)
    }
}
