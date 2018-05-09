//
//  StatsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/18/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftDate
import ScrollableGraphView
import UICircularProgressRing
import TwicketSegmentedControl
import BTNavigationDropdownMenu
import ActionCableClient

class StatsViewController: UIViewController {
    
    var count: Int?
    var scans: [[DateInRegion: Int]]?
    var counts = [Double]()
    var titles = [String]()
    var segmentTitles = ["Total", "Ingress", "Egress"]
    var graphView = ScrollableGraphView()
    var ingress: [[DateInRegion: Int]]?
    var egress: [[DateInRegion: Int]]?
    var ingressTitle = [String]()
    var egressTitle = [String]()
    var egressCount = [Double]()
    var ingressCount = [Double]()
    var hourly: [String: [DateInRegion: Int]]?
    var routes = [RealmRoute]()
    var items = ["All Routes"]
    var menuView: BTNavigationDropdownMenu!
    var client = ActionCableClient(url: URL(string: "wss://ontrackmanagement.herokuapp.com/cable")!)
    var channel: Channel?
    static var ChannelIdentifier = "RidershipsChannel"

    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var progressCircle: UICircularProgressRingView!
    @IBOutlet weak var segmentedControl: TwicketSegmentedControl!
    @IBOutlet weak var ridershipLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ridership"
        
        countLabel.text = ""
        countLabel.alpha = 0.0
        
        ridershipLabel.text = "TOTAL RIDERSHIP"
        
        segmentedControl.setSegmentItems(segmentTitles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        
        self.menuView = BTNavigationDropdownMenu(title: self.items[0], items: self.items as [AnyObject])
        
        //self.navigationItem.titleView = self.menuView
        
        setupGraph()
        
        self.menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.client.willConnect = {
            print("Will Connect")
        }
        
        self.client.onConnected = {
            print("Connected to \(self.client.url)")
        }
        
        self.client.onDisconnected = {(error: ConnectionError?) in
            print("Disconected with error: \(error)")
        }
        
        self.client.willReconnect = {
            print("Reconnecting to \(self.client.url)")
            return true
        }
        
        let day = currentUser!.day!.calendarDay
        let date = DateInRegion(string: day, format: DateFormat.iso8601Auto)
        let year = date?.year
        let month = date?.month
        let d = date?.day
        let calc = year! + month! + d!
        let id = ["event_id" : currentUser?.event?.eventId, "day": calc]
        
        self.channel = client.create(StatsViewController.ChannelIdentifier, identifier: (id as Any as! ChannelIdentifier), autoSubscribe: true, bufferActions: true)
        
        //self.channel = client.create(DriverDetailViewController.ChannelIdentifier)
        self.channel?.onSubscribed = {
            print("Subscribed to \(StatsViewController.ChannelIdentifier)")
        }
        
        self.channel?.onReceive = {(data: Any?, error: Error?) in
            if let _ = error {
                print(error)
                return
            }
            
            let JSONObject = JSON(data!)
            //print("JSONObject -----------> \(JSONObject)")
            let counts = JSONObject["data"]["ridership_counts"]
            print(counts)
            
            DispatchQueue.main.async {
                self.countLabel.text = "\(counts)"
            }
            /*
             let msg = ChatMessage(name: JSONObject["name"].string!, message: JSONObject["message"].string!)
             self.history.append(msg)
             self.chatView?.tableView.reloadData()
             
             
             // Scroll to our new message!
             if (msg.name == self.name) {
             let indexPath = IndexPath(row: self.history.count - 1, section: 0)
             self.chatView?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
             }
             */
        }
        
        self.client.connect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        progressCircle.setProgress(value: 100, animationDuration: 1.5, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuView.hide()
        client.disconnect()
    }
    
    func setupGraph() {
        APIManager.shared.getStats { (scans, cnt, ingress, egress, items, routes) in
            self.count = cnt
            self.scans = scans
            self.ingress = ingress
            self.egress = egress
            self.items = items
            //self.routes = routes
            self.routes = routes.sorted { $1.id > $0.id }
            self.items.removeAll()
            for r in self.routes {
                self.items.append(r.name!)
            }
            
            self.items.insert("All Routes", at: 0)
            
            for i in self.ingress! {
                
                self.ingressCount.append(Double(i.values.first!))
                self.ingress?.append(i)
                
                let t = "\(String(describing: i.keys.first!.hour)):\(String(describing: i.keys.first!.minute))"
                self.ingressTitle.append(String(describing: t))
            }
            
            for e in self.egress! {
                self.egressCount.append(Double(e.values.first!))
                self.egress?.append(e)
                
                let t = "\(String(describing: e.keys.first!.hour)):\(String(describing: e.keys.first!.minute))"
                self.egressTitle.append(String(describing: t))
            }
            
            for c in self.scans! {
                
                //Initial graph view
                if let cnt = c.values.first {
                    self.counts.append(Double(cnt))
                }
                
                if let cnt = c.keys.first {
                    let time = "\(cnt.hour):\(cnt.minute)"
                    self.titles.append(String(describing: time))
                }
            }
            
            DispatchQueue.main.async {
                if self.count != nil {
                    self.countLabel.text = "\(String(describing: self.count!))"
                    
                    UIView.animate(withDuration: 0.5, animations: {
                        self.countLabel.alpha = 1.0
                    })
                    
                    let frame = CGRect(x: 0, y: self.view.frame.height - 300, width: self.view.frame.width, height: 300)
                    self.graphView = ScrollableGraphView(frame: frame)
                    
                    self.graphView.backgroundFillColor = UIColor.init(red: 29/255, green: 35/255, blue: 45/255, alpha: 1.0)
                    self.graphView.lineWidth = 1
                    self.graphView.lineColor = UIColor.init(red: 30/255, green: 150/255, blue: 247/255, alpha: 1.0)//UIColor.init(hexString: "#777777")!
                    self.graphView.lineStyle = ScrollableGraphViewLineStyle.smooth
                    self.graphView.shouldFill = true
                    self.graphView.fillType = ScrollableGraphViewFillType.solid
                    self.graphView.fillColor = UIColor.init(red: 29/255, green: 35/255, blue: 45/255, alpha: 1.0)//UIColor.init(hexString: "#555555")!
                    self.graphView.fillGradientType = ScrollableGraphViewGradientType.linear
                    //graphView.fillGradientStartColor = UIColor.init(red: 29/255, green: 35/255, blue: 45/255, alpha: 1.0)
                    //graphView.fillGradientEndColor = UIColor.init(hexString: "#444444")!
                    self.graphView.dataPointSpacing = 35
                    self.graphView.dataPointSize = 3
                    self.graphView.dataPointFillColor = UIColor.white
                    self.graphView.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 12)
                    self.graphView.referenceLineColor = UIColor.white.withAlphaComponent(0.2)
                    self.graphView.referenceLineLabelColor = UIColor.white
                    self.graphView.dataPointLabelColor = UIColor.white.withAlphaComponent(0.5)
                    
                    self.graphView.shouldAdaptRange = true
                    self.graphView.shouldAnimateOnAdapt = true
                    
                    let data = self.counts
                    let labels = self.titles
                    self.graphView.set(data: data, withLabels: labels)
                    self.view.addSubview(self.graphView)
                }
                
                self.menuView.updateItems((self.items as [AnyObject]))
            }
        }
    }
}

extension StatsViewController: TwicketSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
        switch segmentIndex {
        case 0:
            self.ridershipLabel.alpha = 0.0
            self.countLabel.alpha = 0.0
            self.ridershipLabel.text = "TOTAL RIDERSHIP"
            self.countLabel.text = "\(String(describing: self.count!))"
            
            UIView.animate(withDuration: 0.5, animations: {
                self.ridershipLabel.alpha = 1.0
                self.countLabel.alpha = 1.0
            })
            
            let data = self.counts
            let labels = self.titles
            self.graphView.set(data: data, withLabels: labels)
        case 1:
            self.ridershipLabel.alpha = 0.0
            self.countLabel.alpha = 0.0
            self.ridershipLabel.text = "INGRESS"
            self.countLabel.text = "\(Int(self.ingressCount.reduce(0,+)))"
            
            UIView.animate(withDuration: 0.5, animations: {
                self.ridershipLabel.alpha = 1.0
                self.countLabel.alpha = 1.0
            })
            
            let data = self.ingressCount
            let labels = self.ingressTitle
            self.graphView.set(data: data, withLabels: labels)
        case 2:
            self.ridershipLabel.alpha = 0.0
            self.countLabel.alpha = 0.0
            self.ridershipLabel.text = "EGRESS"
            self.countLabel.text = "\(Int(self.egressCount.reduce(0,+)))"
            
            UIView.animate(withDuration: 0.5, animations: {
                self.ridershipLabel.alpha = 1.0
                self.countLabel.alpha = 1.0
            })
            
            let data = self.egressCount
            let labels = self.egressTitle
            self.graphView.set(data: data, withLabels: labels)
        default:
            print("default")
        }
    }
}
