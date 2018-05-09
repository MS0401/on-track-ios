//
//  BarcodeScannerViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 9/1/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import AVFoundation
import CoreNFC
import RealmSwift
import SwiftyJSON
import SwiftDate
import TwicketSegmentedControl
import Alamofire
import ACProgressHUD_Swift

@available(iOS 11.0, *)
class BarcodeScannerViewController: UIViewController {
    
    lazy var realm = try! Realm()
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var didFindBarcode = false
    var didFindStaff = false
    var barcodeInfo: String?
    private var nfcSession: NFCNDEFReaderSession!
    private var nfcMessages: [[NFCNDEFMessage]] = []
    var payload = ""
    var isFromInventory = false
    var isFromStaff = false
    var isFromItem = false
    var staff: RealmDriver?
    var item: Equipment?
    var segmentedControl: TwicketSegmentedControl!
    var qrCodeFrameView: UIView?

    @IBOutlet weak var toggleSegmentedControl: UISegmentedControl!
    
    @IBAction func toggle(_ sender: UISegmentedControl) {
        toggleFlash()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titles = ["Fuel", "Look Up QR Code", "Read QR Code"]//["Assign", "Lookup", "Fuel"]
        let frame = CGRect(x: 0, y: 0, width: Int(view.frame.width), height: 50)
        
        segmentedControl = TwicketSegmentedControl(frame: frame)
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        
        if isFromInventory == false && isFromStaff == false && isFromItem == false {
            view.addSubview(segmentedControl)
            view.bringSubview(toFront: segmentedControl)
            //view.bringSubview(toFront: toggleSegmentedControl)
        }
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice!)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed();
            return;
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.ean8, AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.pdf417, AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.code93, AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.aztec]
            
        } else {
            failed()
            return
        }
        
        let previewFrame = CGRect(x: 0, y: 50, width: Int(view.frame.width), height: (Int(view.frame.height - 50)))
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if isFromInventory == false && isFromStaff == false && isFromItem == false {
            previewLayer.frame = previewFrame
        } else {
            previewLayer.frame = view.layer.bounds
        }
    
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    @IBAction func nfcScan(_ sender: UIBarButtonItem) {
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: true)
        nfcSession.alertMessage = "Scan tag by holding it behind the top of your iPhone."
        nfcSession.begin()
        print("tapped")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scanStaffSegue" {
            let dvc = segue.destination as! ItemStaffViewController
            //dvc.staff = self.staff
        } else if segue.identifier == "scanItemSegue" {
            let dvc = segue.destination as! RadioDetailViewController
            dvc.radio = self.item
        } else if segue.identifier == "foundItemSegue" {
            let dvc = segue.destination as! GeneratorDetailViewController
            let s = sender as! Inventory
            dvc.inventoryItem = sender as! Inventory
            dvc.id = s.id
        }
    }
}

@available(iOS 11.0, *)
extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            
            //print("qr code object: \(metadataObject)")
            
            var readableObject = metadataObject as! AVMetadataMachineReadableCodeObject
            var mo = readableObject.stringValue as! String
            /*
            //print("readable object: \(readableObject.stringValue)")
            var mo = readableObject.stringValue as String
            print(mo)
            //mo.remove(at: mo.startIndex)
            //mo.remove(at: mo.endIndex)
            //var lastChar = mo.remove(at: mo.endIndex)
            var splitComma: [String] = mo.components(separatedBy: ",")
            var splitString: [String] = String(describing: splitComma[3]).components(separatedBy: ":")
        
            var id = splitString[1]
            var newId: Int = Int(String(id.characters.dropLast()))!
            print(newId)
            */
            

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            /*
            if segmentedControl.selectedSegmentIndex == 0 {
                print("selected index = 0")
                if isFromInventory == false && isFromStaff == false && isFromItem == false {
                    let text = readableObject.stringValue
                    //print(isFromStaff)
                    //print(readableObject.stringValue)
                   
                    
                    //if text?.first == "@" {
                        //Scan drivers license
                        let ar = text?.components(separatedBy: .newlines)
                        var split = [String: Any]()
                        for a in ar! {
                            if a.count > 2 {
                                var b = a
                                b.insert(":", at: b.index(b.startIndex, offsetBy: 3))
                                var array = b.components(separatedBy: ":")
                                //var dict = [array[0]: array[1]]
                                
                                switch array[0] {
                                case "DAC":
                                    split["DAC"] = array[1]
                                case "DAD":
                                    split["DAD"] = array[1]
                                case "DCS":
                                    split["DCS"] = array[1]
                                default:
                                    break
                                }
                            }
                        }
                        
                        print("\(String(describing: split["DAC"])) \(String(describing: split["DAD"])) \(String(describing: split["DCS"]))")
                    //}
 
                    
                    if barcodeInfo == nil {
                        if didFindBarcode == false {
                            var splitComma: [String] = readableObject.stringValue.components(separatedBy: ",")
                            var splitString: [String] = String(describing: splitComma[0]).components(separatedBy: ":")
                            
                            let id = splitString[1]
                            if let convertString = Int(id.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) {
                                let equipment = realm.objects(Equipment.self).filter("id = %@", convertString).first
                                
                                if equipment != nil {
                                    foundBarcode(item: equipment!)
                                    didFindBarcode = true
                                } else {
                                    let ac = UIAlertController(title: "Not Found", message: "Item was not found in inventory", preferredStyle: .alert)
                                    let addAction = UIAlertAction(title: "Add to Inventory", style: .default, handler: { (action) in
                                        //self.captureSession.startRunning()
                                        self.addRadioToInventory(radioInfo: "\(convertString)")
                                    })
                                    
                                    let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                                        self.captureSession.startRunning()
                                    })
                                    
                                    ac.addAction(addAction)
                                    ac.addAction(cancelAction)
                                    self.present(ac, animated: true, completion: nil)
                                }
                            }
                            
                        }
                    } else {
                        if didFindBarcode == true && didFindStaff == false {
                            var splitComma: [String] = readableObject.stringValue.components(separatedBy: ",")
                            var splitString: [String] = String(describing: splitComma[0]).components(separatedBy: ":")
        
                            let id = splitString[1]
                            if let convertString = Int(id.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) {
                                let stf = realm.objects(RealmDriver.self).filter("id = %@", convertString).first
                                
                                if stf != nil {
                                    foundStaff(staff: stf!)
                                    didFindStaff = true
                                } else {
                                    let ac = UIAlertController(title: "Not Found", message: "Staff person not found in database", preferredStyle: .alert)
                                    let addAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                        self.captureSession.startRunning()
                                        //self.addRadioToInventory(radioInfo: "\(convertString)")
                                    })
                                    
                                    let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                                        self.captureSession.startRunning()
                                    })
                                    
                                    ac.addAction(addAction)
                                    ac.addAction(cancelAction)
                                    self.present(ac, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                } else if isFromStaff == true {
                    if let text = readableObject.stringValue {
                        
                        var splitComma: [String] = text.components(separatedBy: ",")
                        var splitString: [String] = String(describing: splitComma[0]).components(separatedBy: ":")
  
                        //let splitId = splitString[0]
                        let id = splitString[1]
                        
                        if let convertString = Int(id.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) {
                            let equipment = realm.objects(Equipment.self).filter("id = %@", convertString).first
                            if equipment != nil {
                                let ac = UIAlertController(title: "Assign", message: "Assign \(equipment!.type) ID: \(equipment!.id) to \(staff!.name)?", preferredStyle: .alert)
                                let assignAction = UIAlertAction(title: "Assign", style: .default, handler: { (action) in
                                    
                                    let now = DateInRegion()
                                    let scan = Scan()
                                    scan.reason = "checkout"
                                    scan.driverName = self.staff!.name
                                    scan.driver_id = self.staff!.id
                                    scan.created_at = now.string()
                                    scan.equipmentStatus = "\(equipment!.type) ID: \(equipment!.id)"
                                    
                                    try! self.realm.write {
                                        equipment!.type = "Radio"
                                        equipment!.status = 2
                                        equipment!.assignedTo = self.staff!.name
                                        equipment!.assignedId = self.staff!.id
                                        equipment!.scans.append(scan)
                                        self.staff!.scans.append(scan)
                                        self.staff!.equipment.append(equipment!)
                                    }
                                    
                                    let when = DispatchTime.now() + 1
                                    DispatchQueue.main.asyncAfter(deadline: when) {
                                        self.completionAlert(title: "Item Assigned", subtitle: "Radio successfully assigned to \(self.staff!.name)")
                                    }
                                })
                                
                                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                                    self.captureSession.startRunning()
                                })
                                
                                ac.addAction(assignAction)
                                ac.addAction(cancelAction)
                                present(ac, animated: true, completion: nil)
                            } else {
                                print("nil")
                            }
                        }
                        //payload = text
                        //addRadioToInventory(radioInfo: payload)
                    }
                } else if isFromItem == true {
                    if let text = readableObject.stringValue {
                        
                        var splitComma: [String] = text.components(separatedBy: ",")
                        var splitString: [String] = String(describing: splitComma[0]).components(separatedBy: ":")
                        let id = splitString[1]
                        
                        if let convertString = Int(id.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) {
                            let stf = realm.objects(RealmDriver.self).filter("id = %@", convertString).first
                            if stf != nil {
                                let ac = UIAlertController(title: "Assign", message: "Assign \(self.item!.type) ID: \(self.item!.id) to \(stf!.name)?", preferredStyle: .alert)
                                let assignAction = UIAlertAction(title: "Assign", style: .default, handler: { (action) in
                                    
                                    
                                    let now = DateInRegion()
                                    let scan = Scan()
                                    scan.reason = "checkout"
                                    scan.driverName = stf!.name
                                    scan.driver_id = stf!.id
                                    scan.created_at = now.string()
                                    scan.equipmentStatus = "\(self.item!.type) ID: \(self.item!.id)"
                                    
                                    
                                    try! self.realm.write {
                                
                                        self.item!.type = "Radio"
                                        self.item!.status = 2
                                        self.item!.assignedTo = stf!.name
                                        self.item!.assignedId = stf!.id
                                        self.item!.scans.append(scan)
                                        stf!.scans.append(scan)
                                        stf!.equipment.append(self.item!)
                                    }
                                    
                                    let when = DispatchTime.now() + 1
                                    DispatchQueue.main.asyncAfter(deadline: when) {
                                        self.completionAlert(title: "Item Assigned", subtitle: "Radio successfully assigned to \(stf!.name)")
                                    }
                                })
                                
                                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                                    self.captureSession.startRunning()
                                })
                                
                                ac.addAction(assignAction)
                                ac.addAction(cancelAction)
                                present(ac, animated: true, completion: nil)
                            } else {
                                print("nil")
                            }
                        }
                        //payload = text
                        //addRadioToInventory(radioInfo: payload)
                    }
                } else {
                    if let text = readableObject.stringValue {
                        payload = text
                        addRadioToInventory(radioInfo: payload)
                    }
                }
            }
            */
            /*else*/
            if segmentedControl.selectedSegmentIndex == 0 {
                
                var splitComma: [String] = readableObject.stringValue!.components(separatedBy: ",")
                var splitId: [String] = String(describing: splitComma[0]).components(separatedBy: ":")
                var splitType: [String] = String(describing: splitComma[1]).components(separatedBy: ":")
                
                let id = splitId[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                print("split comma: \(splitComma), splitid: \(splitId), splittype: \(splitType), id: \(id)")
                
                let type = "not staff"
                
                if type == "not staff" {
                    var splitComma: [String] = mo.components(separatedBy: ",")
                    var splitString: [String] = String(describing: splitComma[3]).components(separatedBy: ":")
                    
                    let id = splitString[1]
                    if id != nil {
                        if let newId: Int = Int(String(id.characters.dropLast())) {
                            
                            //let progressView = ACProgressHUD.shared
                            //progressView.progressText = "Looking up QR..."
                            //progressView.showHUD()
                            
                            self.lookupQrCode(id: newId, captureSession: self.captureSession, completion: { (inventory) in
                                
                                
                                
                                //progressView.hideHUD()
                                    //if error == nil {
                                        //if let inventory = inventory {
                                            
                                           //progressView.hideHUD()
                                            
                                    let ac = UIAlertController(title: "\(inventory.name)", message: "Add fuel to Light Tower \(inventory.uid)", preferredStyle: .alert)
                                    ac.addTextField { (textfield) in
                                        textfield.keyboardType = .decimalPad
                                        //textfield.text = "\(50)"
                                    }
                                    let aAction = UIAlertAction(title: "Add Fuel", style: .default, handler: { (action) in
                                        
                                        if (ac.textFields![0].text?.isEmpty)! {
                                            
                                            let alertController = UIAlertController(title: "Incorrect Value", message: "Please scan again and add valid number", preferredStyle: .alert)
                                            let alertAction = UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                                                
                                            })
                                            
                                        } else {
                                            //progressView.progressText = "Sending Scan..."
                                            //progressView.showHUD()
                                            self.postScan(scanType: "fuel", inventoryId: inventory.id, fuel: ac.textFields![0].text, parentId: nil, fuelType: 1, completion: {
                                                /*
                                                progressView.progressText = "Success!"
                                                progressView.showHUD()
                                                */
                                                //progressView.hideHUD()
                                            self.captureSession.startRunning()
                                            })
                                        }
                                    })
                                    //progressView.hideHUD()
                                    let eAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                                         //progressView.hideHUD()
                                        self.captureSession.startRunning()
                                    })
                                    
                                    ac.addAction(aAction)
                                    ac.addAction(eAction)
                                    
                                    self.present(ac, animated: true, completion: nil)
                                        //} else if inventory == nil && error == nil {
                                            //progressView.hideHUD()
                                        //}
                           // }
                                 //progressView.hideHUD()
                            
                            })
                            
                        } else {
                            
                            let ac = UIAlertController(title: "Not Encoded OnTrack QR", message: "\(readableObject.stringValue)", preferredStyle: .alert)
                            let addAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                self.captureSession.startRunning()
                            })
                            
                            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                                self.captureSession.startRunning()
                            })
                            
                            ac.addAction(addAction)
                            ac.addAction(cancelAction)
                            self.present(ac, animated: true, completion: nil)
                        }
                    }
                }
                
            } else if segmentedControl.selectedSegmentIndex == 1 {
                //print(isFromInventory)
                //print(isFromStaff)
                //print(isFromItem)
                if isFromInventory == false && isFromStaff == false && isFromItem == false {
                    
                    //print("selected index = 1")
                    var splitComma: [String] = readableObject.stringValue!.components(separatedBy: ",")
                    var splitId: [String] = String(describing: splitComma[0]).components(separatedBy: ":")
                    var splitType: [String] = String(describing: splitComma[1]).components(separatedBy: ":")
                    
                    print(splitComma)
                    
                    //print(splitComma)
                    //print(splitId)
                    //print(splitType)
 
                    let id = splitId[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
 
                    let type = "not staff"
                    
                    if type == "staff" {
                        if let convertString = Int(id.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) {
                            
                            print("convert string \(convertString)")
                            let stf = realm.objects(RealmDriver.self).filter("id = %@", convertString).first
                            
                            if stf != nil {
                                self.staff = stf
                                self.performSegue(withIdentifier: "scanStaffSegue", sender: self)
                            } else {
                                let ac = UIAlertController(title: "Not Found", message: "Staff person not found in database", preferredStyle: .alert)
                                let addAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                    self.captureSession.startRunning()
                                    //self.addRadioToInventory(radioInfo: "\(convertString)")
                                })
                                
                                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                                    self.captureSession.startRunning()
                                })
                                
                                ac.addAction(addAction)
                                ac.addAction(cancelAction)
                                self.present(ac, animated: true, completion: nil)
                            }
                        }
                    } else {
                        var splitComma: [String] = mo.components(separatedBy: ",")
                        var splitString: [String] = String(describing: splitComma[3]).components(separatedBy: ":")
                        
                        let id = splitString[1]
                        if id != nil {
                            if let newId: Int = Int(String(id.characters.dropLast())) {
                            
                                self.lookupQrCode(id: newId, captureSession: self.captureSession, completion: { (inventory) in
                                    self.performSegue(withIdentifier: "foundItemSegue", sender: inventory)
                                })
                            
                            /*
                            if let convertString = Int(id.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) {
                                let equip = realm.objects(Equipment.self).filter("id = %@", convertString).first
                             
                                if equip != nil {
                                    self.item = equip
                                    self.performSegue(withIdentifier: "scanItemSegue", sender: self)
                                } else {
                                    let ac = UIAlertController(title: "Not Found", message: "Item not found in database", preferredStyle: .alert)
                                    let addAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                        self.captureSession.startRunning()
                                    })
                             
                                    let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                                        self.captureSession.startRunning()
                                    })
                             
                                    ac.addAction(addAction)
                                    ac.addAction(cancelAction)
                                    self.present(ac, animated: true, completion: nil)
                                }
                            }
                            */
                            } else {
                                let ac = UIAlertController(title: "Not Encoded OnTrack QR", message: "\(readableObject.stringValue)", preferredStyle: .alert)
                                let addAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                    self.captureSession.startRunning()
                                })
                                
                                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                                    self.captureSession.startRunning()
                                })
                                
                                ac.addAction(addAction)
                                ac.addAction(cancelAction)
                                self.present(ac, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
            
            else {
                self.captureSession.startRunning()
            
                let text = readableObject.stringValue
                if text != nil {
                    
                    let ac = UIAlertController(title: "QR Code", message: "\(text!)", preferredStyle: .alert)
                    /*
                    ac.addTextField { (textfield) in
                        textfield.keyboardType = .numberPad
                        textfield.text = "\(50)"
                    }
                    */
                    
                    let addAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        self.captureSession.startRunning()
                    })
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                        self.captureSession.startRunning()
                    })
                    
                    ac.addAction(addAction)
                    ac.addAction(cancelAction)
                    
                    present(ac, animated: true, completion: nil)
                }
 
            }
        
        }
    }
    
    func postScan(scanType: String, inventoryId: Int, fuel: String?, parentId: Int?, fuelType: Int?, completion: @escaping () -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/scans"
        let lat = String(describing: user!.lastLocation!.latitude)
        let long = String(describing: user!.lastLocation!.longitude)
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let params = [
            "event_id": 1,
            "scan_type": scanType,
            "latitude": lat,
            "longitude": long,
            "inventory_id": inventoryId,
            "quantity": fuel,
            "parent_id": parentId,
            "fuel_type_id": fuelType
            ] as [String : Any]
        
        print(params)
        
        Alamofire.request(path, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            print(response.request?.httpBody)
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let code = json["meta"]["code"].intValue
                let meta = json["meta"]
                
                if code == 200 {
                    //self.loadingIndicator(title: "Scan...", message: "Sending Scan, please wait", dialogTitle: "Success!", dialogMessage: "Scan Created", dialogButtonTitle: "Add Scan")
                    completion()
                } else {
                    //Not received
                    print(meta)
                    
                    let ac = UIAlertController(title: "Error", message: meta["message"].stringValue, preferredStyle: UIAlertControllerStyle.alert)
                    let aa = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        
                    })
                    
                    ac.addAction(aa)
                    self.present(ac, animated: true, completion: nil)
                }
                
            case .failure:
                break
            }
        }
    }

    func foundBarcode(item: Equipment) {
        barcodeInfo = "\(item.id)"
        self.item = item
        
        let alertController = UIAlertController(title: "\(item.type) ID: \(item.id)",
                                                message: "Please scan or search for staff member to assign radio",
                                                preferredStyle: UIAlertControllerStyle.alert)
        
        let submitAction = UIAlertAction(title: "Scan", style: UIAlertActionStyle.default) { (action) in
            self.captureSession.startRunning()
        }
        
        let searchAction = UIAlertAction(title: "Search Staff", style: .default) { (action) in
            self.performSegue(withIdentifier: "staffSearch", sender: self)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.barcodeInfo = nil
            self.didFindBarcode = false
            self.captureSession.startRunning()
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(searchAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion:nil)
    }
    
    func foundStaff(staff: RealmDriver) {
        self.staff = staff
        
        let alertController = UIAlertController(title: "Staff",
            message: "Assign \(self.item!.type) \(self.item!.id) to \(staff.name)",
            preferredStyle: UIAlertControllerStyle.alert)
        
        let submitAction = UIAlertAction(title: "Assign", style: UIAlertActionStyle.default) { (action) in
            
            let now = DateInRegion()
            let scan = Scan()
            scan.reason = "checkout"
            scan.driverName = self.staff!.name
            scan.driver_id = self.staff!.id
            scan.created_at = now.string()
            scan.equipmentStatus = "\(self.item!.type) ID: \(self.item!.id)"
            
            try! self.realm.write {
                self.item!.type = "Radio"
                self.item!.status = 2
                self.item!.assignedTo = self.staff!.name
                self.item!.assignedId = self.staff!.id
                self.item!.scans.append(scan)
                self.staff!.scans.append(scan)
                self.staff!.equipment.append(self.item!)
            }

             var when = DispatchTime.now() + 1
             DispatchQueue.main.asyncAfter(deadline: when) {
                self.completionAlert(title: "Radio Assigned", subtitle: "Radio successfully assigned to Peter Hitchcock")
             }

        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.didFindStaff = false
            self.captureSession.startRunning()
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion:nil)
    }
    
    func addRadioToInventory(radioInfo: String) {
        let alertController = UIAlertController(title: "Add Radio",
                                                message: "Add Radio to Inventory",
                                                preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addTextField { (textfield) in
            textfield.placeholder = "Radio ID"
            textfield.text = radioInfo
        }
        /*
        alertController.addTextField { (textfield) in
            textfield.placeholder = "Name"
        }
        alertController.addTextField { (textfield) in
            textfield.placeholder = "Status"
        }
        */
        
        let submitAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (action) in
            
            let one: Int = Int(alertController.textFields![0].text!)!
            //let two = alertController.textFields![1].text!
            //let three: Int = Int(alertController.textFields![2].text!)!
            
            let s1: JSON = ["id": one, "created_at": "Sept 1", "status": 1, "uid": "\(one)", "type": "Radio"]
            let equip1 = Equipment(json: s1)
            
            try! self.realm.write {
                self.realm.add(equip1)
            }
        
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.completionAlert(title: "Radio Added", subtitle: "Radio successfully added to inventory")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.captureSession.startRunning()
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion:nil)
    }
    
    func completionAlert(title: String, subtitle: String) {
        _ = SweetAlert().showAlert(title, subTitle: subtitle, style: AlertStyle.success, buttonTitle:  "Ok", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
            
            if self.isFromStaff == false {
                self.didFindBarcode = false
                self.didFindStaff = false
                self.barcodeInfo = nil
                //self.captureSession.startRunning()
                self.navigationController?.popViewController(animated: true)
            } else {
                self.captureSession.startRunning()
            }
        }
    }
    
    func lookupQrCode(id: Int, captureSession: AVCaptureSession, completion: @escaping (Inventory) -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/\(id)"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let uid = json["uid"].stringValue
                //print("UID \(json["uid"])")
                //print(json)
                if json["data"]["uid"] != JSON.null {
                    
                    let item = Inventory(json: json["data"])
                    
                    completion(item)
                    
                } else {
                    
                    //completion(nil, nil)
                    
                    let alertController = UIAlertController(title: "QR Code Not Assigned",
                        message: "Please Receive Inventory",
                        preferredStyle: UIAlertControllerStyle.alert)
                    
                    alertController.addTextField { (textfield) in
                        textfield.placeholder = "Unique Identifier"
                    }
                    
                    let submitAction = UIAlertAction(title: "Assign Inventory", style: UIAlertActionStyle.default) { (action) in
                        //self.captureSession.startRunning()
                        print(alertController.textFields![0].text! as String)
                        self.updateInventoryItem(id: id, uid: alertController.textFields![0].text! as String, eventId: 1, departmentId: nil, captureSession: self.captureSession, completion: { (inventory) in
                            
                            self.postScan(scanType: "received", inventoryId: id, captureSession: self.captureSession, completion: { (scan) in
                                print("scan \(scan)")
                                inventory.scans.append(scan)
                                inventory.lastScan = scan
                                /*
                                inventory.lastScan?.latitude = Double(scan.latitude)
                                inventory.lastScan?.longitude = Double(scan.longitude)
                                inventory.lastScan?.scanType = scan.scanType
                                */
                                self.performSegue(withIdentifier: "foundItemSegue", sender: inventory)
                            })
                            
                        })
                    }
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
                        //self.barcodeInfo = nil
                        //self.didFindBarcode = false
                        self.captureSession.startRunning()
                    }
                    
                    alertController.addAction(submitAction)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion:nil)
                }
                print(json)

            case .failure:
                //completion(nil, error)
                break
            }
        }
    }
    
    func postScan(scanType: String, inventoryId: Int, captureSession: AVCaptureSession, completion: @escaping (InventoryScan) -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/scans"
        let lat = String(describing: user!.lastLocation!.latitude)
        let long = String(describing: user!.lastLocation!.longitude)
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let params = [
            "event_id": 1,
            "scan_type": scanType,
            "latitude": lat,
            "longitude": long,
            "scanner_id": 1,
            "user_id": 1,
            "inventory_id": inventoryId
            ] as [String : Any]
        
        Alamofire.request(path, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let code = json["meta"]["code"].intValue
                let meta = json["meta"]
                print(json)
                
                if code == 200 {
                    //print("json data \(json["data"])")
                    let scan = InventoryScan(json: json["data"]["scan"])  //Scan(inventoryJson: json["data"])
                    completion(scan)
                } else if code == 400 {
                    //Not received
                    print("from scan: \(meta)")
                    
                    /*
                    let ac1 = UIAlertController(title: "Error", message: "\(json)", preferredStyle: .alert)
                    //let ac = UIAlertController(title: "Error", message: "\(json)", preferredStyle: UIAlertControllerStyle.alert)
                    let aa = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        captureSession.startRunning()
                    })
                    
                    ac1.addAction(aa)
                    self.present(ac1, animated: true, completion: nil)
                    */
                }
                
            case .failure:
                break
            }
        }
    }
    
    func updateInventoryItem(id: Int, uid: String?, eventId: Int, departmentId: Int?, captureSession: AVCaptureSession, completion: @escaping (Inventory) -> ()) {
        let user = self.realm.objects(User.self).first
        let path = "\(BASE_URL_INVENTORY)/api/inventories/\(id)"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "\(user!.token)"
        ]
        
        let params = [
            "event_id": eventId,
            "uid": uid,
            "department_id": departmentId
            ] as [String : Any]
        
        Alamofire.request(path, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            //print(response)
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let code = json["meta"]["code"].intValue
                let meta = json["meta"]["message"].arrayValue
                
                //print(json)
                let item = Inventory(json: json["data"])
                
                if code == 200 {
                    completion(item)
                } else if code == 400 {
                    let ac = UIAlertController(title: "Error", message: "\(meta[0])", preferredStyle: UIAlertControllerStyle.alert)
                    let aa = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        captureSession.startRunning()
                    })
                    
                    ac.addAction(aa)
                    self.present(ac, animated: true, completion: nil)
                    
                } else {
                    let ac = UIAlertController(title: "Error", message: "\(meta[0])", preferredStyle: UIAlertControllerStyle.alert)
                    let aa = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        captureSession.startRunning()
                    })
                    
                    ac.addAction(aa)
                    self.present(ac, animated: true, completion: nil)
                }
                
            case .failure:
                break
            }
        }
    }
    
    @IBAction
    
    func toggleFlash() {
        if let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch {
            do {
                try device.lockForConfiguration()
                let torchOn = !device.isTorchActive
                try device.setTorchModeOn(level: 1.0)
                device.torchMode = torchOn ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("error")
            }
        }
    }
}

@available(iOS 11.0, *)
extension BarcodeScannerViewController: NFCNDEFReaderSessionDelegate {
    
    // Called when the reader-session expired, you invalidated the dialog or accessed an invalidated session
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC-Session invalidated: \(error.localizedDescription)")
        
    }
    
    // Called when a new set of NDEF messages is found
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("New NFC Messages (\(messages.count)) detected:")
        
        for message in messages {
            print(" - \(message.records.count) Records:")
            print(message)
            
            for record in message.records {
                print(record.identifier)
                print("\t- Payload: \(String(data: record.payload, encoding: .utf8)!)")
                print("\t- Type: \(record.type)")
                print("\t- Identifier: \(record.identifier)\n")
                //self.payload = String(data: record.payload, encoding: .utf8)!
                
                let first = String(data: record.payload, encoding: .utf8)!.dropFirst()
                var second = first.dropFirst()
                var third = second.dropFirst()
                
                self.payload = String(third)
                
                print("----------------\(third)")
                print("----------------\(self.payload)")
                
            }
        }
    }
}

@available(iOS 11.0, *)
extension BarcodeScannerViewController: TwicketSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
    }
}
