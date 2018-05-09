//
//  QRCodeViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/17/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import QRCode
import RealmSwift
import SwiftDate

class QRCodeViewController: UIViewController {
    
    @IBOutlet weak var qrcodeImageView: UIImageView!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var driverNameLabel: UILabel!
    @IBOutlet weak var routeNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var vendorLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    
    //TODO: All currentUser info
    var qrCode: QRCode!
    lazy var realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let id = currentUser?.id {
            qrCode = QRCode("driver: \(String(id))")
            qrcodeImageView.image = qrCode?.image
        }

        background.layer.cornerRadius = 10
        
        driverNameLabel.text = currentUser?.name
        routeNameLabel.text = currentUser?.route?.name
        vendorLabel.text = "OnTrack"
        
        switch currentUser!.event!.name {
        case "EDC 2017":
            logoImageView.image = UIImage(named: "edc2017logo")
        default:
            logoImageView.image = UIImage(named: "coachella-logo")
        }
        
        if currentUser?.role == "driver" {
            if let d = DateInRegion(string: (currentUser?.shifts.first?.times.first?.time)!, format: DateFormat.iso8601Auto)?.string() {
                //print(d.components)
                timeLabel.text = d
            }
        } else {
            let shift = realm.objects(Shift.self).first
            if let d = DateInRegion(string: (shift?.times.first?.time)!, format: DateFormat.iso8601Auto)?.string() {
                //print(d.components)
                timeLabel.text = d
            }
        }
        
    }
}
