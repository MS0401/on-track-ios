//
//  ManualScanViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/27/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import ACProgressHUD_Swift

class ManualScanViewController: UIViewController {
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    var scans = ["yard_arrival", "driver_check_in", "orientation", "dry_run", "driver_briefing",
                 "hotel_desk", "yard_in", "yard_out", "pick_up_arrival", "pick_up_pax",
                 "drop_unload", "venue_load_out", "venue_staging", "break_in", "break_out",
                 "out_of_service_mechanical", "out_of_service_emergency", "end_shift", "passenger", "other",
                 "geo_enter", "geo_exit", "no_show"]
    
    var scan = ["reason": "yard_arrival", "index": 0] as [String : Any]
    var driver: RealmDriver!
    var shift: Shift!
    var driverId: Int!
    var lat: Float!
    var long: Float!
    var id: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Scan"
        
        if let driver = driver, let shift = shift {
            self.driver = driver
            self.shift = shift
        }
        
        if let lat = currentUser?.lastLocation?.latitude, let long = currentUser?.lastLocation?.longitude {
            self.lat = lat
            self.long = long
        }
        
        if let id = currentUser?.id {
            self.id = id
        }
    }
    
    @IBAction func scanDriver(_ sender: UIButton) {

        let index = scan["index"] as! Int
        let progressView = ACProgressHUD.shared
        progressView.progressText = "Sending Scan..."
        
        switch index {
        case 9:
            let alert = UIAlertController(title: "Number of Passengers", message: "Please add number of passengers", preferredStyle: UIAlertControllerStyle.alert)
            alert.addTextField { (textfield) in
                textfield.keyboardType = .numberPad
                textfield.text = "\(50)"
            }
            let alertAction = UIAlertAction(title: "Ingress", style: UIAlertActionStyle.default, handler: { (action) in
                
                if let int = Int((alert.textFields?[0].text)!) {
                    progressView.showHUD()
                    
                    APIManager.shared.postDriverScan(self.driverId, comment: "manual scan", reason: index, lat: self.lat, long: self.long, eventId: self.shift.eventId, routeId: self.shift.routeId, passengerCount: int, scannerId: self.id, scanType: "staff", ingress: true, shiftId: self.shift.id) { (error) in
                        
                        if error != nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                                progressView.hideHUD()
                                self.errorAlert()
                            })
                            
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                                progressView.hideHUD()
                                self.completionAlert()
                            })
                        }
                    }
                    
                } else {
                    let a = UIAlertController(title: "Must be a number", message: "Please try again and enter a number", preferredStyle: UIAlertControllerStyle.alert)
                    let aa = UIAlertAction(title: "OK", style: .default, handler: nil)
                    a.addAction(aa)
                    self.present(a, animated: true, completion: nil)
                }
            })
            
            let egressAction = UIAlertAction(title: "Egress", style: .default, handler: { (action) in
                if let int = Int((alert.textFields?[0].text)!) {
                    progressView.showHUD()
                    
                    APIManager.shared.postDriverScan(self.driverId, comment: "manual scan", reason: index, lat: self.lat, long: self.long, eventId: self.shift.eventId, routeId: self.shift.routeId, passengerCount: int, scannerId: self.id, scanType: "staff", ingress: false, shiftId: self.shift.id) { (error) in
                        
                        if error != nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                                progressView.hideHUD()
                                self.errorAlert()
                            })
                            
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                                progressView.hideHUD()
                                self.completionAlert()
                            })
                        }
                    }
                    
                } else {
                    let a = UIAlertController(title: "Must be a number", message: "Please try again and enter a number", preferredStyle: UIAlertControllerStyle.alert)
                    let aa = UIAlertAction(title: "OK", style: .default, handler: nil)
                    a.addAction(aa)
                    self.present(a, animated: true, completion: nil)
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in

            })
            alert.addAction(alertAction)
            alert.addAction(egressAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: {

            })
        case 16:
            let alert = UIAlertController(title: "Emergency Type", message: "What kind of emergency", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "Medical", style: .default, handler: { (action) in
                self.postScan(progressView: progressView, reason: index, comment: "comment", driverId: self.driverId, lat: self.lat, long: self.long, eventId: self.shift.eventId, routeId: self.shift.routeId, scannerId: self.id, scanType: "staff")
            })
            let alertActionTwo = UIAlertAction(title: "Fire", style: .default, handler: { (action) in
                self.postScan(progressView: progressView, reason: index, comment: "comment", driverId: self.driverId, lat: self.lat, long: self.long, eventId: self.shift.eventId, routeId: self.shift.routeId, scannerId: self.id, scanType: "staff")
            })
            let alertActionThree = UIAlertAction(title: "Police", style: .default, handler: { (action) in
                self.postScan(progressView: progressView, reason: index, comment: "comment", driverId: self.driverId, lat: self.lat, long: self.long, eventId: self.shift.eventId, routeId: self.shift.routeId, scannerId: self.id, scanType: "staff")
            })
            let alertActionFour = UIAlertAction(title: "Accident", style: .default, handler: { (action) in
                self.postScan(progressView: progressView, reason: index, comment: "comment", driverId: self.driverId, lat: self.lat, long: self.long, eventId: self.shift.eventId, routeId: self.shift.routeId, scannerId: self.id, scanType: "staff")
            })
            let alertActionFive = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                
            })
            alert.addAction(alertAction)
            alert.addAction(alertActionTwo)
            alert.addAction(alertActionThree)
            alert.addAction(alertActionFour)
            alert.addAction(alertActionFive)
            present(alert, animated: true, completion: nil)
            
        default:
            postScan(progressView: progressView, reason: index, comment: "comment", driverId: driverId, lat: self.lat, long: self.long, eventId: shift.eventId, routeId: shift.routeId, scannerId: id, scanType: "staff")
        }
    }
    
    @IBAction func dismissSelector(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func completionAlert() {
        _ = SweetAlert().showAlert("Scan Received", subTitle: "Successful Scan", style: AlertStyle.success, buttonTitle:  "OK", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func errorAlert() {
        _ = SweetAlert().showAlert("Scan not received", subTitle: "Please verify connection to network and try again", style: AlertStyle.error, buttonTitle:  "Try Again", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
            
        }
    }
    
    func postScan(progressView: ACProgressHUD, reason: Int, comment: String, driverId: Int,
                  lat: Float, long: Float, eventId: Int, routeId: Int, scannerId: Int, scanType: String) {
        
        progressView.showHUD()
        APIManager.shared.postDriverScan(driverId, comment: comment, reason: reason, lat: lat, long: long, eventId: eventId, routeId: routeId, passengerCount: nil, scannerId: scannerId, scanType: scanType, ingress: nil, shiftId: self.shift.id) { (error) in
            
            if error != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                    progressView.hideHUD()
                    self.errorAlert()
                })
                
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                    progressView.hideHUD()
                    self.completionAlert()
                })
            }
        }
    }
}

extension ManualScanViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return scans.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return scans[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let scan = scans[row]
        self.scan = ["reason": scan, "index": row]
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let str = scans[row]
        switch row {
        case 1:
            return NSAttributedString(string: str, attributes: [NSAttributedStringKey.foregroundColor:UIColor.flatGreen])
        case 9:
            return NSAttributedString(string: str, attributes: [NSAttributedStringKey.foregroundColor:UIColor.flatSkyBlue])
        case 10:
            return NSAttributedString(string: str, attributes: [NSAttributedStringKey.foregroundColor:UIColor.flatGreen])
        case 13:
            return NSAttributedString(string: str, attributes: [NSAttributedStringKey.foregroundColor:UIColor.flatYellow])
        case 15,16,22:
            return NSAttributedString(string: str, attributes: [NSAttributedStringKey.foregroundColor:UIColor.flatRed])
        default:
            return NSAttributedString(string: str, attributes: [NSAttributedStringKey.foregroundColor:UIColor.white])
        }
    }
}
