//
//  SelectEventViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/17/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import RealmSwift

class SelectEventViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topLayout: NSLayoutConstraint!
    
    let primaryColor = #colorLiteral(red: 0.6271930337, green: 0.3653797209, blue: 0.8019730449, alpha: 1)
    let primaryColorDark = #colorLiteral(red: 0.5373370051, green: 0.2116269171, blue: 0.7118118405, alpha: 1)
    
    var events = [Event]()
    var days = [Day]()
    let realm = try! Realm()
    var isFromDashboard = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Select Event"
        
        for event in (currentUser?.events)! {
            events.append(event)
        }
        
        tableView.tableFooterView = UIView()
        
        if isFromDashboard == true {
            let frame = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: 64)
            let header = UIView()
            header.backgroundColor = navBarColor
            header.frame = frame
            view.addSubview(header)
            
            let label = UILabel()
            label.frame = CGRect(x: 0, y: 0, width: 200, height: 21)
            label.center = CGPoint(x: header.frame.width / 2, y: 42)
            label.textAlignment = .center
            label.text = "Select Event"
            label.textColor = .white
            header.addSubview(label)
            
            topLayout.constant = 64
        }
    }
    
    func loadingIndicator(event: Event){
        let dialog = AZDialogViewController(title: "Loading Event...", message: "Loading \(event.name), please wait")
        
        //self.getEvent(eventId: event.eventId)
        APIManager.shared.getEvent(eventId: event.eventId)

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
        
        var when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            dialog.message = "Loading Drivers..."
            
            when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when) {
                dialog.message = "Loading Staff..."
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    dialog.message = "Checking number of days..."
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                        dialog.title = "Ready"
                        dialog.message = "Event \(event.name) Loaded"
                        ///dialog.image = #imageLiteral(resourceName: "image")
                        dialog.customViewSizeRatio = 0
                        
                        dialog.addAction(AZDialogAction(title: "Get Started", handler: { (dialog) -> (Void) in

                            dialog.dismiss()
                            
                            try! self.realm.write {
                                currentUser?.event = event
                                currentUser?.event_id = event.eventId
                                currentUser?.day = event.days[0]
                            }
                            
                            if self.isFromDashboard == true {
                                let when = DispatchTime.now() + 1  // change 2 to desired number of seconds
                                DispatchQueue.main.asyncAfter(deadline: when) {
                                    self.dismiss(animated: true, completion: nil)
                                }
                            } else {
                                let when = DispatchTime.now() + 1  // change 2 to desired number of seconds
                                DispatchQueue.main.asyncAfter(deadline: when) {
                                    if currentUser?.role == "admin" {
                                        self.performSegue(withIdentifier: "adminSegue", sender: self)
                                    } else if currentUser?.role == "route_managers" {
                                        self.performSegue(withIdentifier: "projectManagementSegue", sender: self)
                                    } else {
                                        self.performSegue(withIdentifier: "staffSegue", sender: self)
                                    }
                                }
                            }
                        }))
                        
                        //dialog.cancelEnabled = !dialog.cancelEnabled
                        dialog.dismissDirection = .bottom
                        dialog.allowDragGesture = true
                    }
                }
            }
        }
        
        dialog.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor.flatSkyBlue
            button.setTitle("CANCEL", for: [])
            return false
        }
    }
    
    func delayDismiss(dialog: AZDialogViewController, event: Event, day: Day) {
        try! self.realm.write {
            currentUser?.event = event
            currentUser?.event_id = event.eventId
            currentUser?.day = day
        }
        
        dialog.dismiss()
        
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.dismiss(animated: true, completion: nil)
            
            if self.isFromDashboard == true {
                //NotificationCenter.default.post(name: Notification.Name(rawValue: "menuUpdate"), object: nil, userInfo: nil)
            } else {
                
                if currentUser?.role == "admin" {
                    self.performSegue(withIdentifier: "adminSegue", sender: self)
                } else if currentUser?.role == "route_managers" {
                    self.performSegue(withIdentifier: "projectManagementSegue", sender: self)
                } else {
                    self.performSegue(withIdentifier: "staffSegue", sender: self)
                }
            }
        }
    }
}

extension SelectEventViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventsCell", for: indexPath)
        cell.textLabel?.text = events[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let event = currentUser?.events[indexPath.row]
        loadingIndicator(event: event!)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView == tableView {
            //Top Left Right Corners
            let maskPathTop = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 5.0, height: 5.0))
            let shapeLayerTop = CAShapeLayer()
            shapeLayerTop.frame = cell.bounds
            shapeLayerTop.path = maskPathTop.cgPath
            
            //Bottom Left Right Corners
            let maskPathBottom = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 5.0, height: 5.0))
            let shapeLayerBottom = CAShapeLayer()
            shapeLayerBottom.frame = cell.bounds
            shapeLayerBottom.path = maskPathBottom.cgPath
            
            //All Corners
            let maskPathAll = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.topLeft, .topRight, .bottomRight, .bottomLeft], cornerRadii: CGSize(width: 5.0, height: 5.0))
            let shapeLayerAll = CAShapeLayer()
            shapeLayerAll.frame = cell.bounds
            shapeLayerAll.path = maskPathAll.cgPath
            
            if (indexPath.row == 0 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1) {
                cell.layer.mask = shapeLayerAll
            }
            else if (indexPath.row == 0) {
                cell.layer.mask = shapeLayerTop
            }
            else if (indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1) {
                cell.layer.mask = shapeLayerBottom
            }
        }
    }
}

extension UIImage {
    class func imageWithColor(_ color: UIColor) -> UIImage {
        let rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
