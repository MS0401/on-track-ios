//
//  ScheduleTableViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/18/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftDate

class ScheduleTableViewController: UITableViewController {
    
    let realm = try! Realm()
    var shifts = [Shift]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for shift in (currentUser?.shifts)! {
            shifts.append(shift)
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ScheduleTableViewController.refreshControlDidFire), for: .valueChanged)
        tableView?.refreshControl = refreshControl
        
        tableView.tableFooterView = UIView()
    }
    
    @objc func refreshControlDidFire() {
        tableView.reloadData()
        tableView?.refreshControl?.endRefreshing()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return shifts.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shifts[section].times.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ScheduleTableViewCell
        let shiftTime = shifts[indexPath.section].times[indexPath.row]
        cell.configureCell(shiftTime: shiftTime)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(shifts[section].name) Schedule"
    }
}
