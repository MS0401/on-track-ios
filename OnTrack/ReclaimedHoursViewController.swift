//
//  ReclaimedHoursViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/10/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import UICircularProgressRing

class ReclaimedHoursViewController: UIViewController, UICircularProgressRingDelegate {

    @IBOutlet weak var progressRing: UICircularProgressRingView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var negativeHours: UICircularProgressRingView!
    @IBOutlet weak var costPerHour: UICircularProgressRingView!
    @IBOutlet weak var totalHoursLabel: UILabel!
    @IBOutlet weak var completedHoursLabel: UILabel!
    @IBOutlet weak var negativeHoursLabel: UILabel!
    @IBOutlet weak var totalCostLabel: UILabel!
    
    var vendors = ["OnTrack", "Board Or Bus", "King's", "Johnny’s Express", "Silverado"]
    var time = [2, 4, 7, 2, 12]
    var total = ""
    var completed = ""
    var negative = ""
    var cost = ""
    
    var data = [[String : Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dict = ["name": "OnTrack", "time": 2, "total_time": 65, "completed": 50, "drivers": [["name": "Jimmy Engelman", "hours": 1, "driverId": 6], ["name": "Lauren Rippee", "hours": 1, "driverId": 7]] ] as [String : Any]
        
        let dict1 = ["name": "Board Or Bus", "time": 4, "total_time": 40, "completed": 20, "drivers": [["name": "Irene Coronado", "hours": 4, "driverId": 9]] ] as [String : Any]
        
        let dict2 = ["name": "King's", "time": 7, "total_time": 35, "completed": 22, "drivers": [["name": "Driver One", "hours": 3, "driverId": 9], ["name": "Driver Two", "hours": 4, "driverId": 9]] ] as [String : Any]
        
        let dict3 = ["name": "Johnny’s Express", "time": 2, "total_time": 50, "completed": 35, "drivers": [["name": "Driver One", "hours": 1, "driverId": 9], ["name": "Driver Two", "hours": 1, "driverId": 9]] ] as [String : Any]
        
        let dict4 = ["name": "Silverado", "time": 12, "total_time": 60, "completed": 48, "drivers": [["name": "Driver One", "hours": 3, "driverId": 9], ["name": "Driver Two", "hours": 2, "driverId": 9], ["name": "Driver Three", "hours": 5, "driverId": 9], ["name": "Driver Four", "hours": 2, "driverId": 9]] ] as [String : Any]
        
        data.append(dict)
        data.append(dict1)
        data.append(dict2)
        data.append(dict3)
        data.append(dict4)
        
        title = "Total Hours"
        
        progressRing.delegate = self
        negativeHours.delegate = self
        costPerHour.delegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.self.progressRing.setProgress(value: 321, animationDuration: 1.0) {}
            self.negativeHours.setProgress(value: CGFloat(self.time.reduce(0,+)), animationDuration: 1.0) {}
            self.costPerHour.setProgress(value: CGFloat(125.0 * CGFloat(self.time.reduce(0,+))), animationDuration: 2.0) {}
        }
        
        completed = "\(321)"
        total = "\(400)"
        negative = "\(time.reduce(0,+))"
        cost = "\(125 * time.reduce(0,+))"
        
        totalHoursLabel.text = "TOTAL HOURS \(total)"
        completedHoursLabel.text = "COMPLETED HOURS \(completed)"
        negativeHoursLabel.text = "NEGATIVE HOURS \(negative)"
        totalCostLabel.text = "TOTAL COST $\(cost)"
        
        tableView.tableFooterView = UIView()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        ///api/v1/events/:id/statistics/:type drivers vendors event_id
        //https://ontrackmanagement.herokuapp.com/events/1/statistics
    }

    func finishedUpdatingProgress(forRing ring: UICircularProgressRingView) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "vendorHoursSegue" {
            let ip = sender as! Int
            let dvc = segue.destination as! VendorHoursViewController
            dvc.dict = data[ip]
        }
    }
}

extension ReclaimedHoursViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vendors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "vendorCell", for: indexPath)
        cell.textLabel?.text = vendors[indexPath.row]
        cell.detailTextLabel?.text = "\(time[indexPath.row]) Hours"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "vendorHoursSegue", sender: indexPath.row)
    }
}
