//
//  TasksViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import TwicketSegmentedControl
import BTNavigationDropdownMenu

class TasksViewController: UIViewController, TwicketSegmentedControlDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: TwicketSegmentedControl!
    
    var items = ["Item One", "Item Two", "Item Three"]
    var titles = ["Open", "In Progress", "Completed"]
    var menuView: BTNavigationDropdownMenu!
    let menuItems = ["Priority", "High", "Medium", "Low"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        
        menuView = BTNavigationDropdownMenu(title: menuItems[0], items: menuItems as [AnyObject])
        
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
        }
        
        navigationItem.titleView = menuView
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func didSelect(_ segmentIndex: Int) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuView.hide()
    }
}

extension TasksViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell", for: indexPath) as! TaskTableViewCell
        switch indexPath.row {
        case 0:
            cell.reasonView.backgroundColor = UIColor.flatRed
        case 1:
            cell.reasonView.backgroundColor = UIColor.flatYellow
        case 2:
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
        default:
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
