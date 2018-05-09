//
//  GeneratorsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/29/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class GeneratorsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Generators"
        tableView.tableFooterView = UIView()
    }
}

extension GeneratorsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gCell", for: indexPath)
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Generator ID 10"
            cell.detailTextLabel?.text = "250 Gallons"
        case 1:
            cell.textLabel?.text = "Generator ID 11"
            cell.detailTextLabel?.text = "300 Gallons"
        case 2:
            cell.textLabel?.text = "Generator ID 12"
            cell.detailTextLabel?.text = "150 Gallons"
        case 3:
            cell.textLabel?.text = "Generator ID 13"
            cell.detailTextLabel?.text = "200 Gallons"
        case 4:
            cell.textLabel?.text = "Generator ID 14"
            cell.detailTextLabel?.text = "100 Gallons"
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
