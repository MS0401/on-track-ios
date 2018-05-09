//
//  BreakToggleViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class BreakToggleViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    var checkins = [RealmDriver]()
    var routes = [Int]()
    var shifts = [Int]()
    var isAll = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "On Break"
        
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
        } else {
            
        }
        
        onbreakStats(type: "on_break", shifts: shifts, routes: routes)
        
        tableView.tableFooterView = UIView()
    }
    
    func onbreakStats(type: String, shifts: [Int], routes: [Int]) {
        if let calendarDay = currentUser?.day?.calendarDay {
            APIManager.shared.getStats(day: calendarDay, shifts: shifts, routes: routes, type: type, completion: { (drivers) in
                
                if type == "on_break" {
                    self.checkins = drivers
                } else {
                    //self.missings = drivers
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.title = "\(self.checkins.count) On Break"
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "offClockSegue" {
            let dvc = segue.destination as! DriverDetailViewController
            dvc.driver = sender as! RealmDriver
            dvc.shift = dvc.driver.shifts.first
            dvc.driverId = dvc.driver.id
        }
    }
}

extension BreakToggleViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return checkins.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "offClockCell", for:
            indexPath) as! WaveTableViewCell
        let driver = checkins[indexPath.row]
        cell.driver = driver
        //cell.textLabel?.text = driver.name
        //cell.detailTextLabel?.text = driver.role
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let driver: RealmDriver = checkins[indexPath.row]
        
        performSegue(withIdentifier: "offClockSegue", sender: driver)
    }
}
