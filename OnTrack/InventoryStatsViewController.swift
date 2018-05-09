//
//  InventoryStatsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/5/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import UICircularProgressRing
import SwiftDate
import DateToolsSwift

class InventoryStatsViewController: UIViewController {
    
    @IBOutlet weak var progressRing: UICircularProgressRingView!
    
    @IBOutlet weak var lastFuelScanLabel: UILabel!
    
    var inventoryItem: Inventory!
    var fuelCount = Float()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(InventoryStatsViewController.updateLabel), name: NSNotification.Name(rawValue: "inventory"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateLabel()
    }
    
    @objc func updateLabel() {
        
        var scans = [InventoryScan]()
        scans.removeAll()
        var i = Double()
        for scan in inventoryItem.scans {
            if scan.scanType == "fuel" {
                let f = Double(scan.fuelCount)
                if let d = f {
                    i = i + d
                }
                //i = i + f!
                print(i)
                fuelCount = Float(i)
                scans.append(scan)
            }
        }
        
        if scans.count > 0 {
            if let date = DateInRegion(string: (scans.last?.createdAt)!, format: DateFormat.iso8601Auto)?.string() {
                
                let d = DateInRegion(string: (scans.last?.createdAt)!, format: DateFormat.iso8601Auto)
                
                let b = Date()
                var gallons = ""
                
                if let g = scans.last?.fuelCount {
                    gallons = g
                }
                
                lastFuelScanLabel.text = "\(gallons) gal \(b.timeAgo(since: (d?.absoluteDate)!))"
            }
        }
        
    
        //fuelCount = i
        if self.fuelCount > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                self.progressRing.maxValue = CGFloat(self.fuelCount)
                self.progressRing.setProgress(value: CGFloat(self.fuelCount), animationDuration: 1.0)
                self.progressRing.innerRingColor = UIColor.flatOrange
                self.progressRing.fontColor = UIColor.flatOrange
            }
            
        } else {
            /*
            DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                self.progressRing.maxValue = CGFloat(100)
                self.progressRing.setProgress(value: CGFloat(100), animationDuration: 1.0)
                self.progressRing.innerRingColor = UIColor.flatOrange
                self.progressRing.fontColor = UIColor.clear
                self.progressRing.fullCircle = true
            }
            */
        }
    }
}
