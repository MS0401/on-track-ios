//
//  StaffEquipmentViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/7/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift

class StaffEquipmentViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
    }
}
