//
//  TrafficViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/3/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class TrafficViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var notifications = [RealmNotification]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Traffic Alerts"
        
        tableView.tableFooterView = UIView()
        
        APIManager.shared.getNotifications { (notifications) in
            for n in notifications {
                if n.reason == "traffic_slow" || n.reason == "traffic_under_10" ||
                    n.reason == "traffic_not_moving" || n.reason == "road_closed" {
                    self.notifications.append(n)
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

extension TrafficViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trafficCell", for: indexPath) as! TrafficTableViewCell
        let notification = notifications[indexPath.row]
        cell.notification = notification
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
