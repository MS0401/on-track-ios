//
//  ToggleDriverViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import TwicketSegmentedControl
import Alamofire
import SwiftyJSON

class ToggleDriverViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var segmentedControl: TwicketSegmentedControl!
    var titles = ["Checked In", "Not Scanned"]
    var checkins = [RealmDriver]()
    var missings = [RealmDriver]()
    var routes = [Int]()
    var shifts = [Int]()
    var isAll = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
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
        */
        
        let frame = CGRect(x: 0, y: 0, width: Int(view.frame.width), height: 40)
        segmentedControl = TwicketSegmentedControl(frame: frame)
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        view.addSubview(segmentedControl)
        view.bringSubview(toFront: segmentedControl)
        
        getUpdatedStats(type: "checked_in", shifts: shifts, routes: routes)
        
        print(shifts)
        print(routes)
        
        tableView.tableFooterView = UIView()
    }
    
    func getUpdatedStats(type: String, shifts: [Int], routes: [Int]) {
        APIManager.shared.getStatistics(day: (currentUser!.day!.calendarDay), shifts: shifts, routes: routes, type: type, completion: { (drivers) in
            
            //self.checkins.removeAll()
            //self.missings.removeAll()
            
            if type == "checked_in" {
                self.checkins = drivers
                print("checkings count -----> \(self.checkins.count)")
            } else {
                self.missings = drivers
                print("missings count -----> \(self.missings.count)")
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
}

extension ToggleDriverViewController: TwicketSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
        switch segmentIndex {
        case 0:
            checkins.removeAll()
            missings.removeAll()
            tableView.reloadData()
            getUpdatedStats(type: "checked_in", shifts: shifts, routes: routes)
        case 1:
            checkins.removeAll()
            missings.removeAll()
            tableView.reloadData()
            getUpdatedStats(type: "missing", shifts: shifts, routes: routes)
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "checkinSegue" {
            let dvc = segue.destination as! DriverDetailViewController
            dvc.driver = sender as! RealmDriver
            dvc.shift = dvc.driver.shifts.first
            dvc.driverId = dvc.driver.id
        }
    }
}

extension ToggleDriverViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return checkins.count
        case 1:
            return missings.count
        default:
            return checkins.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "checkedInCell", for:
            indexPath) as! WaveTableViewCell
        let driver: RealmDriver!
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            driver = checkins[indexPath.row]
            cell.driver = driver
        case 1:
            driver = missings[indexPath.row]
            cell.driver = driver
        default:
            driver = checkins[indexPath.row]
        }
        //cell.driverLabel.text = driver.name
        //cell.lastScanLabel.text = driver.lastScan?.reason //driver.role
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let driver: RealmDriver!
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            driver = checkins[indexPath.row]
            print(driver)
        case 1:
            driver = missings[indexPath.row]
        default:
            driver = checkins[indexPath.row]
        }
        
        performSegue(withIdentifier: "checkinSegue", sender: driver)
    }
}
