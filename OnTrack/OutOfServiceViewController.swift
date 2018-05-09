//
//  OutOfServiceViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 8/10/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class OutOfServiceViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var checkins = [RealmDriver]()
    var routes = [Int]()
    var shifts = [Int]()
    var isAll = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Out of Service"
        
        if isAll == true {
            if let eventRoutes = currentUser?.event?.routes {
                for route in eventRoutes {
                    routes.append(route.id)
                }
            }
            
            if let eventShifts = currentUser?.event?.waves {
                for shift in eventShifts {
                    shifts.append(shift.id)
                }
            }
        }
        
        onbreakStats(type: "out_of_service", shifts: shifts, routes: routes)
        
        tableView.tableFooterView = UIView()
    }
    
    func onbreakStats(type: String, shifts: [Int], routes: [Int]) {
        if let calendarDay = currentUser?.day?.calendarDay {
            APIManager.shared.getStats(day: calendarDay, shifts: shifts, routes: routes, type: type, completion: { (drivers) in
                
                if type == "out_of_service" {
                    self.checkins = drivers
                } else {
                    //self.missings = drivers
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.title = "\(self.checkins.count) Out of Service"
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromOutOfService" {
            let dvc = segue.destination as! DriverDetailViewController
            dvc.driver = sender as! RealmDriver
            dvc.shift = dvc.driver.shifts.first
            dvc.driverId = dvc.driver.id
        }
    }
}

extension OutOfServiceViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return checkins.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "outOfServiceCell", for:
            indexPath) as! WaveTableViewCell
        let driver = checkins[indexPath.row]
        print(driver)
        cell.scanColorView.backgroundColor = UIColor.flatRed
        cell.driverLabel.text = driver.name
        cell.lastScanLabel.text = driver.lastScan?.reason
        cell.scannerNameLabel.text = driver.lastScan?.scannerName
        cell.vendorName.text = driver.vendor?.name
        cell.loopsLabel.isHidden = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let driver: RealmDriver = checkins[indexPath.row]
        
        performSegue(withIdentifier: "fromOutOfService", sender: driver)
    }
}
