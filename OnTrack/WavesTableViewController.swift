//
//  WavesTableViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import TwicketSegmentedControl
import ACProgressHUD_Swift
import SwiftDate
import BTNavigationDropdownMenu
import RealmSwift

class WavesTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SettingsViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var waveTimesLabel: UILabel!
    @IBOutlet weak var waveNameLabel: UILabel!
    
    var realm = try! Realm()
    var shifts = [Shift]()
    var reverse = [Shift]()
    var filter = [RealmDriver]()
    var all = [RealmDriver]()
    var segmentedControl: TwicketSegmentedControl!
    var titles = ["All"]
    var items = ["All Scans", "Check In", "Pick Up", "Drop", "On Break", "Out of Service", "Not Scanned"]
    var menuView: BTNavigationDropdownMenu!
    var timer: Timer?
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(WavesTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()
    var indexP = 0
    var shift: Shift!
    lazy var settingsView: SettingsView = {
        let st = SettingsView.init(frame: UIScreen.main.bounds)
        st.delegate = self
        return st
    }()
    internal var count: Int = 0
    internal var tbHeight: Int = 0
    var viewItems = [String]()
    var imageName = [String]()
    var isChangingRoute = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        waveNameLabel.text = ""
        waveTimesLabel.text = ""
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        menuView = BTNavigationDropdownMenu(title: items[0], items: items as [AnyObject])
    
        let frame = CGRect(x: 0, y: 33, width: Int(view.frame.width), height: 40)

        segmentedControl = TwicketSegmentedControl(frame: frame)
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        view.addSubview(segmentedControl)
        view.bringSubview(toFront: segmentedControl)
        segmentedControl.alpha = 0
    
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
            self.filterScans(indexPath: indexPath, selectedSegmentIndex: self.segmentedControl.selectedSegmentIndex)
        }
        
        navigationItem.titleView = menuView
        
        tableView.tableFooterView = UIView()
        tableView.addSubview(refreshControl)
        
        //timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(getShifts), userInfo: nil, repeats: true)
        if currentUser?.role == "admin" {
            getShifts(route: (currentUser?.event?.routes.first)!)
            items.remove(at: 0)
            items.insert("All Scans \((currentUser?.event?.routes.first?.name)!)", at: 0)
        } else {
            //getShifts(route: (currentUser?.event?.routes.first)!)
            getShifts(route: (currentUser?.route)!)
            items.remove(at: 0)
            items.insert("All Scans \((currentUser?.route?.name)!)", at: 0)
        }
        
        menuView.updateItems(items as [AnyObject])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /*
        if currentUser?.role == "admin" {
            getShifts(route: (currentUser?.event?.routes.first)!)
            items.remove(at: 0)
            items.insert("All Scans \((currentUser?.event?.routes.first?.name)!)", at: 0)
        } else {
            //getShifts(route: (currentUser?.event?.routes.first)!)
            getShifts(route: (currentUser?.route)!)
            items.remove(at: 0)
            items.insert("All Scans \((currentUser?.route?.name)!)", at: 0)
        }
        
        menuView.updateItems(items as [AnyObject])
        */
    }
    
    func updateAppSetting(segmentIndex: Int?, menuIndex: Int?) {
        

        try! realm.write {
            if let seg = segmentIndex {
                appSetting?.segmentIndex = seg
            }
            
            if let mi = menuIndex {
                appSetting?.menuIndex = mi
            }
        }
        
    }
    
    func filterScans(indexPath: Int, selectedSegmentIndex: Int) {
        
        let index = selectedSegmentIndex - 1
        
        updateAppSetting(segmentIndex: selectedSegmentIndex, menuIndex: indexPath)
        
        switch indexPath {
            case 0:
                filter.removeAll()
                if selectedSegmentIndex == 0 {
                    for shift in self.shifts {
                        for driver in shift.drivers {
                            if driver.role == "driver" {
                                self.filter.append(driver)
                            }
                        }
                    }
                } else {
                    filter.removeAll()
                    for d in shifts[index].drivers {
                        if d.role == "driver" {
                            self.filter.append(d)
                        }
                    }
                }
            case 1:
                if selectedSegmentIndex == 0 {
                    filter.removeAll()
                    for shift in self.shifts {
                        for driver in shift.drivers {
                            if driver.role == "driver" {
                                self.filter.append(driver)
                            }
                        }
                    }
                    self.filter = self.filter.filter { $0.lastScan?.reason! == "driver_check_in" }
                    
                } else {
                    filter.removeAll()
                    for d in self.shifts[index].drivers {
                        if d.role == "driver" {
                            self.filter.append(d)
                        }
                    }
                    self.filter = self.filter.filter { $0.lastScan?.reason! == "driver_check_in" }
                }
            case 2:
                if selectedSegmentIndex == 0 {
                    filter.removeAll()
                    for shift in self.shifts {
                        for driver in shift.drivers {
                            if driver.role == "driver" {
                                self.filter.append(driver)
                            }
                        }
                    }
                    self.filter = self.filter.filter { $0.lastScan?.reason! == "pick_up_pax" }
                } else {
                    filter.removeAll()
                    for d in self.shifts[index].drivers {
                        if d.role == "driver" {
                            self.filter.append(d)
                        }
                    }
                    self.filter = self.filter.filter { $0.lastScan?.reason! == "pick_up_pax" }
                }
            case 3:
                if selectedSegmentIndex == 0 {
                    filter.removeAll()
                    for shift in self.shifts {
                        for driver in shift.drivers {
                            if driver.role == "driver" {
                                self.filter.append(driver)
                            }
                        }
                    }
                    self.filter = self.filter.filter { $0.lastScan?.reason! == "drop_unload" }
                } else {
                    filter.removeAll()
                    for d in self.shifts[index].drivers {
                        if d.role == "driver" {
                            self.filter.append(d)
                        }
                    }
                    self.filter = self.filter.filter { $0.lastScan?.reason! == "drop_unload"}
                }
        case 4:
            if selectedSegmentIndex == 0 {
                filter.removeAll()
                for shift in self.shifts {
                    for driver in shift.drivers {
                        if driver.role == "driver" {
                            self.filter.append(driver)
                        }
                    }
                }
                self.filter = self.filter.filter { $0.lastScan?.reason! == "break_in" }
            } else {
                filter.removeAll()
                for d in self.shifts[index].drivers {
                    if d.role == "driver" {
                        self.filter.append(d)
                    }
                }
                self.filter = self.filter.filter { $0.lastScan?.reason! == "break_in"}
            }

            case 5:
                if selectedSegmentIndex == 0 {
                    filter.removeAll()
                    for shift in self.shifts {
                        for driver in shift.drivers {
                            if driver.role == "driver" {
                                self.filter.append(driver)
                            }
                        }
                    }
                    self.filter = self.filter.filter { $0.lastScan?.reason! == "out_of_service_mechanical" || $0.lastScan?.reason! == "out_of_service_emergency"}
                } else {
                    filter.removeAll()
                    for d in self.shifts[index].drivers {
                        if d.role == "driver" {
                            self.filter.append(d)
                        }
                    }
                    self.filter = self.filter.filter { $0.lastScan?.reason! == "out_of_service_mechanical" || $0.lastScan?.reason! == "out_of_service_emergency"}
                }
            
            case 6:
                if selectedSegmentIndex == 0 {
                    filter.removeAll()
                    for shift in self.shifts {
                        for driver in shift.drivers {
                            if driver.role == "driver" {
                                self.filter.append(driver)
                            }
                        }
                    }
                    self.filter = self.filter.filter { $0.lastScan?.reason! == nil || $0.lastScan?.reason! == ""}

                } else {
                    filter.removeAll()
                    for d in self.shifts[index].drivers {
                        if d.role == "driver" {
                            self.filter.append(d)
                        }
                    }
                    self.filter = self.filter.filter { $0.lastScan?.reason! == nil || $0.lastScan?.reason! == ""}
                }
            
            default:
                break
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //timer?.invalidate()
        menuView.hide()
    }
    
    func getShifts(route: RealmRoute) {
        
        let progressView = ACProgressHUD.shared
        progressView.progressText = "Updating Waves..."
        progressView.showHUD()
        
        APIManager.shared.getRouteShifts(eventId: (currentUser?.event_id)!, routeId: route.id) { (shifts, error) in
            //self.shifts.removeAll()
            if error != nil {
                progressView.hideHUD()
                let alertController = UIAlertController(title: "Unable to update", message: "Unable to update waves please verify network connection", preferredStyle: UIAlertControllerStyle.alert)
                let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil)
                alertController.addAction(action)
                self.present(alertController, animated: true, completion: nil)
            } else {
                
                self.shifts = shifts
                
                switch self.shifts.count {
                case 0:
                    self.titles = ["All"]
                case 1:
                    self.titles = ["All", "1"]
                    self.segmentedControl.setSegmentItems(self.titles)
                case 2:
                    self.titles = ["All", "1", "2"]
                    self.segmentedControl.setSegmentItems(self.titles)
                case 3:
                    self.titles = ["All", "1", "2", "3"]
                    self.segmentedControl.setSegmentItems(self.titles)
                case 4:
                    self.titles = ["All", "1", "2", "3", "4"]
                    self.segmentedControl.setSegmentItems(self.titles)
                case 5:
                    self.titles = ["All", "1", "2", "3", "4", "5"]
                    self.segmentedControl.setSegmentItems(self.titles)
                case 6:
                    self.titles = ["1", "2", "3", "4", "5", "6"]
                    self.segmentedControl.setSegmentItems(self.titles)
                default:
                    self.titles = ["All"]
                    self.segmentedControl.setSegmentItems(self.titles)
                }
                
                DispatchQueue.main.async {
                    //if self.shifts[0].name != nil {
                    self.waveNameLabel.text = "Start Time"//self.shifts[0].name
                    //self.checkRoute(time: (self.shifts[0].times.first?.time)!)
                    //}
                    
                    UIView.animate(withDuration: 0.5, animations: {
                        self.segmentedControl.alpha = 1
                    })
                    
                    self.filter.removeAll()
                    for shift in shifts {
                        for driver in shift.drivers {
                            if driver.role == "driver" {
                                self.filter.append(driver)
                            }
                        }
                    }
        
                    self.tableView.reloadData()
                }
                progressView.hideHUD()
            }
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        if currentUser?.role == "admin" {
            getShifts(route: (currentUser?.event?.routes.first)!)
        } else {
            getShifts(route: (currentUser?.route)!)
        }
        
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    func checkRoute(time: String) {
        
        let date = DateInRegion(string: time, format: DateFormat.iso8601Auto)?.string()
        
        if self.shifts.count > 0 {
            switch self.shifts[0].routeId {
            case 1:
                self.waveTimesLabel.text = date
            case 2:
                self.waveTimesLabel.text = date
            case 3:
                self.waveTimesLabel.text = date
            case 4:
                self.waveTimesLabel.text = date
            default:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "driverDetail" {
            let driver = sender as! RealmDriver
            let dvc = segue.destination as! DriverDetailViewController
            dvc.driver = driver
            dvc.shift = driver.shifts.first
        }
    }

    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return 1//shifts.count
        case 1:
            return 1
        case 2:
            return 1
        case 3:
            return 1
        case 4:
            return 1
        case 5:
            return 1
        case 6:
            return 1
        default:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return filter.count//shifts[section].drivers.count
        case 1:
            return filter.count
        case 2:
            return filter.count
        case 3:
            return filter.count
        case 4:
            return filter.count
        case 5:
            return filter.count
        case 6:
            return filter.count
        default:
            return shifts[section].drivers.count
        }

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "waveCell", for: indexPath) as! WaveTableViewCell
        var driver: RealmDriver!
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            driver = filter[indexPath.row]//shifts[indexPath.section].drivers[indexPath.row]
        case 1:
            driver = filter[indexPath.row]
        case 2:
            driver = filter[indexPath.row]
        case 3:
            driver = filter[indexPath.row]
        case 4:
            driver = filter[indexPath.row]
        case 5:
            driver = filter[indexPath.row]
        case 6:
            driver = filter[indexPath.row]
        default:
            driver = shifts[indexPath.section].drivers[indexPath.row]
        }
        cell.driver = driver
        return cell
    }
    
    /*
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        /*
        if let d = DateInRegion(string: (shifts[section].times.first?.time)!, format: DateFormat.iso8601Auto) {
            return "Wave: \(shifts[section].name) Time: \(d.components.hour!):\(d.components.minute!)"
        } else {
            return "FIX ME"//"Wave: \(shifts[section].name) Start time: \(convertTime(dt: (shifts[section].times.first?.time)!))"
        }
        */
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return "1"
        case 1:
            return "2"
        case 2:
            return "3"
        case 3:
            return "4"
        case 4:
            return "5"
        case 5:
            return "6"
        case 6:
            return "7"
        default:
            return "FIX ME"
        }

    }
    */
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let driver = filter[indexPath.row]//shifts[indexPath.section].drivers[indexPath.row]
        performSegue(withIdentifier: "driverDetail", sender: driver)
    }
    
    func setupSettingsView() {
        count = 1
        tbHeight = 48 * count
        
        let originalFrame = settingsView.tableView.frame
        let newHeight = count * tbHeight
        settingsView.tableView.frame = CGRect(x: originalFrame.origin.x, y: originalFrame.origin.y, width: originalFrame.size.width, height:CGFloat(Int(newHeight)))
        
        viewItems.append("Change Route")
        imageName.append("sync")
        settingsView.items = viewItems
        settingsView.imageNames = imageName
    }
    
    func didSelectRow(indexPath: Int) {
        loadingIndicator(event: (currentUser?.event)!)
    }
    
    func hideSettingsView(status: Bool) {
        if status == true {
            settingsView.removeFromSuperview()
        }
    }
    
    @IBAction func moreAction(_ sender: Any) {
        loadingIndicator(event: (currentUser?.event)!)
        /*
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.settingsView)
            settingsView.animate()
        }
        */
    }
    
    func loadingIndicator(event: Event){
        let dialog = AZDialogViewController(title: "Loading Routes...", message: "Loading routes, please wait")
        
        let container = dialog.container
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        dialog.container.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        indicator.startAnimating()
        
        
        dialog.buttonStyle = { (button,height,position) in
            //button.setBackgroundImage(UIImage.imageWithColor(self.primaryColorDark), for: .highlighted)
            button.setTitleColor(UIColor.white, for: .highlighted)
            button.setTitleColor(UIColor.flatSkyBlue, for: .normal)
            button.layer.masksToBounds = true
            button.layer.borderColor = UIColor.flatSkyBlue.cgColor//self.primaryColor.cgColor
        }
        
        //dialog.animationDuration = 5.0
        dialog.customViewSizeRatio = 0.2
        dialog.dismissDirection = .none
        dialog.allowDragGesture = false
        dialog.dismissWithOutsideTouch = true
        dialog.show(in: self)
        
        let when = DispatchTime.now() + 1  // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            dialog.message = "Checking number of routes..."
        }
        
        /*
         DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4) {
         dialog.message = "Loading event..."
         }
         */
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            dialog.title = "\((currentUser?.event?.routes.count)!) Routes found"
            dialog.message = "Select route"
            ///dialog.image = #imageLiteral(resourceName: "image")
            dialog.customViewSizeRatio = 0
            
            for route in event.routes {
                dialog.addAction(AZDialogAction(title: route.name!, handler: { (dialog) -> (Void) in
                    self.delayDismiss(dialog: dialog, route: route)
                    self.getShifts(route: route)
                    self.items.remove(at: 0)
                    self.items.insert("All Scans \(route.name!)", at: 0)
                    self.menuView.updateItems(self.items as [AnyObject])
                }))
            }
            
            dialog.cancelEnabled = !dialog.cancelEnabled
            dialog.dismissDirection = .bottom
            dialog.allowDragGesture = true
        }
        
        dialog.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor.flatSkyBlue
            button.setTitle("CANCEL", for: [])
            return false
        }
    }
    
    func delayDismiss(dialog: AZDialogViewController, route: RealmRoute) {
        try! self.realm.write {
            currentUser?.route = route
        }
        
        dialog.dismiss()
        
        /*
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.dismiss(animated: true, completion: nil)
        }
        */
    
    }


}

extension WavesTableViewController: TwicketSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
        updateAppSetting(segmentIndex: segmentIndex, menuIndex: nil)
        switch segmentIndex {
        case 0:
            filter.removeAll()
            for shift in shifts {
                for driver in shift.drivers {
                    if driver.role == "driver" {
                        self.filter.append(driver)
                    }
                }
            }

            DispatchQueue.main.async {
                self.waveNameLabel.text = "Start Time"
                //self.checkRoute(time: (self.shifts[0].times.first?.time)!)
            }
        case 1:
            if shifts.count > 0 {
                filter.removeAll()
                for d in shifts[0].drivers {
                    if d.role == "driver" {
                        self.filter.append(d)
                    }
                }
                
                DispatchQueue.main.async {
                    //self.tableView.reloadData()
                    self.waveNameLabel.text = self.shifts[0].name
                    //self.checkRoute(time: (self.shifts[0].times.first?.time)!)
                }
            }
        case 2:
            filter.removeAll()
            if shifts.count > 1 {
                for d in shifts[1].drivers {
                    if d.role == "driver" {
                        self.filter.append(d)
                    }
                }
            
            
                DispatchQueue.main.async {
                    //self.tableView.reloadData()
                    self.waveNameLabel.text = self.shifts[1].name
                    //self.checkRoute(time: (self.shifts[1].times.first?.time)!)
                }
            }
        case 3:
            filter.removeAll()
            for d in shifts[2].drivers {
                if d.role == "driver" {
                    self.filter.append(d)
                }
            }
            
            DispatchQueue.main.async {
                //self.tableView.reloadData()
                self.waveNameLabel.text = self.shifts[2].name
                //self.checkRoute(time: (self.shifts[3].times.first?.time)!)
            }
        case 4:
            filter.removeAll()
            for d in shifts[3].drivers {
                if d.role == "driver" {
                    self.filter.append(d)
                }
            }
            
            DispatchQueue.main.async {
                //self.tableView.reloadData()
                self.waveNameLabel.text = self.shifts[2].name
                //self.checkRoute(time: (self.shifts[2].times.first?.time)!)
            }
        case 5:
            filter.removeAll()
            for d in shifts[4].drivers {
                if d.role == "driver" {
                    self.filter.append(d)
                }
            }
            DispatchQueue.main.async {
                //self.tableView.reloadData()
                self.waveNameLabel.text = self.shifts[4].name
                //self.checkRoute(time: (self.shifts[4].times.first?.time)!)
            }
            
        case 6:
            filter.removeAll()
            for d in shifts[6].drivers {
                if d.role == "driver" {
                    self.filter.append(d)
                }
            }
            
        default:
            tableView.reloadData()
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.menuView = BTNavigationDropdownMenu(title: self.items[0], items: self.items as [AnyObject])
            self.navigationItem.titleView = self.menuView
            self.menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
                self.filterScans(indexPath: indexPath, selectedSegmentIndex: self.segmentedControl.selectedSegmentIndex)
            }
        }
    }
}
