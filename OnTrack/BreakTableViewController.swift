//
//  BreakTableViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/18/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift

class BreakTableViewController: UITableViewController {
    
    let realm = try! Realm()
    var shiftTimes = [ShiftTime]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for shift in (currentUser?.shifts)! {
            for t in shift.times {
                if t.name == "Break" {
                    shiftTimes.append(t)
                }
            }
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ScheduleTableViewController.refreshControlDidFire), for: .valueChanged)
        tableView?.refreshControl = refreshControl
        
        tableView.tableFooterView = UIView()
    }
    
    func refreshControlDidFire() {
        tableView.reloadData()
        tableView?.refreshControl?.endRefreshing()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shiftTimes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "breakCell", for: indexPath) as! BreakTableViewCell
        let shiftTime = shiftTimes[indexPath.row]
        cell.configureCell(shiftTime: shiftTime)
        return cell
    }
}
