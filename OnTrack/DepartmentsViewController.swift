//
//  DepartmentsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/28/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import UICircularProgressRing

class DepartmentsViewController: UIViewController {

    @IBOutlet weak var progressRing: UICircularProgressRingView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.progressRing.maxValue = CGFloat(100000.0)
            self.progressRing.setProgress(value: CGFloat(100000.0), animationDuration: 2.0)
            
            //self.progressRing.innerRingColor = UIColor.flatOrange
            //self.dollarLabel.textColor = UIColor.flatOrange
            //self.progressRing.fontColor = UIColor.flatOrange
            

        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "departmentSegue" {
            let dvc = segue.destination as! SingleDepartmentController
            dvc.departmentNumber = sender as! Int
        }
    }

}

extension DepartmentsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "departmentsCell", for: indexPath)
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Merchandise"
            cell.detailTextLabel?.text = "$15,000"
        case 1:
            cell.textLabel?.text = "Food & Beverage"
            cell.detailTextLabel?.text = "$22,000"
        case 2:
            cell.textLabel?.text = "Operations"
            cell.detailTextLabel?.text = "$20,000"
        case 3:
            cell.textLabel?.text = "Site Ops"
            cell.detailTextLabel?.text = "$15,000"
        case 4:
            cell.textLabel?.text = "Transportation"
            cell.detailTextLabel?.text = "$28,000"
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "departmentSegue", sender: indexPath.row)
    }
}


