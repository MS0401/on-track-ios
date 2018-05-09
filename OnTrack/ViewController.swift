//
//  QRCodeReaderViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 11/10/16.
//  Copyright © 2016 Peter Hitchcock. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON
import RealmSwift
//import BPStatusBarAlert
import TwicketSegmentedControl
import ACProgressHUD_Swift

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
   
   @IBOutlet weak var messageLabel:UILabel!
   @IBOutlet weak var captureButton: UIButton!
   @IBOutlet weak var bottomView: UIView!
   
   let realm = try! Realm()
   var isDriver = false
   var captureSession:AVCaptureSession?
   var videoPreviewLayer:AVCaptureVideoPreviewLayer?
   var qrCodeFrameView:UIView?
   var codeResult: String?
   var isActive = false
   let supportedBarCodes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.code93, AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.pdf417, AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.aztec]
   var scans = [[String: Any]]()
   var segmentedControl: TwicketSegmentedControl!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      let titles = ["Regular", "Passenger"]
      let frame = CGRect(x: 0, y: 0, width: Int(view.frame.width), height: 50)
      
      segmentedControl = TwicketSegmentedControl(frame: frame)
      segmentedControl.setSegmentItems(titles)
      segmentedControl.delegate = self
      segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
      segmentedControl.isHidden = true
      view.addSubview(segmentedControl)
      
      if currentUser?.role == "driver" {
         isDriver = true
      }
      
      // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
      // as the media type parameter.
      let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
      
      do {
         // Get an instance of the AVCaptureDeviceInput class using the previous device object.
         let input = try AVCaptureDeviceInput(device: captureDevice!)
         
         // Initialize the captureSession object.
         captureSession = AVCaptureSession()
         // Set the input device on the capture session.
         captureSession?.addInput(input)
         
         // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
         let captureMetadataOutput = AVCaptureMetadataOutput()
         captureSession?.addOutput(captureMetadataOutput)
         
         // Set delegate and use the default dispatch queue to execute the call back
         captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
         
         // Detect all the supported bar code
         captureMetadataOutput.metadataObjectTypes = supportedBarCodes
         
         // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
         videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
         videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
         videoPreviewLayer?.frame = view.layer.bounds
         view.layer.addSublayer(videoPreviewLayer!)
         
         // Start video capture
         captureSession?.startRunning()
         
         // Move the message label to the top view
         view.bringSubview(toFront: messageLabel)
         view.bringSubview(toFront: bottomView)
         view.bringSubview(toFront: segmentedControl)
         
         // Initialize QR Code Frame to highlight the QR code
         qrCodeFrameView = UIView()
         
         if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 10
            view.addSubview(qrCodeFrameView)
            view.bringSubview(toFront: qrCodeFrameView)
         }
         
      } catch {
         // If any error occurs, simply print it out and don't continue any more.
         print(error)
         return
      }
   }
   
   @IBAction func captureData(_ sender: UIButton) {
      if let captureResult = codeResult {
         print(captureResult)
      }
   }
   
   func metadataOutput(_ captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
      
      // Check if the metadataObjects array is not nil and it contains at least one object.
      if metadataObjects == nil || metadataObjects.count == 0 {
         qrCodeFrameView?.frame = CGRect.zero
         messageLabel.text = "No barcode/QR code is detected"
         return
      }
      
      // Get the metadata object.
      let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
      
      // Here we use filter method to check if the type of metadataObj is supported
      // Instead of hardcoding the AVMetadataObjectTypeQRCode, we check if the type
      // can be found in the array of supported bar codes.
      if supportedBarCodes.contains(metadataObj.type) {
         //        if metadataObj.type == AVMetadataObjectTypeQRCode {
         // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
         let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
         qrCodeFrameView?.frame = barCodeObject!.bounds
         
         if metadataObj.stringValue != nil {
            messageLabel.text = metadataObj.stringValue
            codeResult = metadataObj.stringValue
            scan()
         }
      }
   }
   
   //TODO: Pass success with alert code
   func completionAlert() {
      //TODO: Add error
      //BPStatusBarAlert().message(message: "Received Scan").show()
      /*
      let alert = UIAlertController(title: "Scan Received", message: "Successful Scan", preferredStyle: UIAlertControllerStyle.alert)
      let alertAction = UIAlertAction(title: "Next Scan", style: .default) { (action) in
         self.captureSession?.startRunning()
         if let qrCodeFrameView = self.qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 10
            self.view.addSubview(qrCodeFrameView)
            self.view.bringSubview(toFront: qrCodeFrameView)
         }
      }
      alert.addAction(alertAction)
      present(alert, animated: true, completion: nil)
      */
      
      
      _ = SweetAlert().showAlert("Scan Received", subTitle: "Successful Scan", style: AlertStyle.success, buttonTitle:  "Next Scan", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
      
            self.captureSession?.startRunning()
            if let qrCodeFrameView = self.qrCodeFrameView {
               qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
               qrCodeFrameView.layer.borderWidth = 10
               self.view.addSubview(qrCodeFrameView)
               self.view.bringSubview(toFront: qrCodeFrameView)
            }
         }
   }
   
   func errorAlert() {
      /*
      let alert = UIAlertController(title: "Scan not received", message: "Please verify connection to network and try again", preferredStyle: UIAlertControllerStyle.alert)
      let alertAction = UIAlertAction(title: "OK", style: .default) { (action) in
         self.captureSession?.startRunning()
         if let qrCodeFrameView = self.qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 10
            self.view.addSubview(qrCodeFrameView)
            self.view.bringSubview(toFront: qrCodeFrameView)
         }
      }
      alert.addAction(alertAction)
      present(alert, animated: true, completion: nil)
      */
      _ = SweetAlert().showAlert("Scan not received", subTitle: "Please verify connection to network and try again", style: AlertStyle.error, buttonTitle:  "Try Again", buttonColor: UIColor.lightGray) { (isOtherButton) -> Void in
         
         self.captureSession?.startRunning()
         if let qrCodeFrameView = self.qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 10
            self.view.addSubview(qrCodeFrameView)
            self.view.bringSubview(toFront: qrCodeFrameView)
         }
      }
   }
   
   @IBAction func scan(_ sender: UIButton) {
      scan()
   }
   
   func alerts(progressView: ACProgressHUD, reason: Int, comment: String, convertString: Int) {
      progressView.showHUD()
      APIManager.shared.postDriverScan(convertString, comment: comment, reason: reason, lat: (currentUser?.lastLocation?.latitude)!, long: (currentUser?.lastLocation?.longitude)!, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, passengerCount: nil, scannerId: (currentUser?.id)!, scanType: "staff", ingress: nil, shiftId: currentUser?.event?.waves.first?.id) { (error) in
         
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
      /*
      APIManager.shared.postDriverScan(convertString, comment: comment, reason: reason, lat: (currentUser?.lastLocation?.latitude)!, long: (currentUser?.lastLocation?.longitude)!, eventId: (currentUser?.route?.event_id)!, routeId: (currentUser?.route?.id)!, passengerCount: nil, scannerId: (currentUser?.id)!, completion: {
         
         DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
            progressView.hideHUD()
            self.completionAlert()
         })
      })
      */
   }
   
   func scan() {
      
      let progressView = ACProgressHUD.shared
      progressView.progressText = "Sending Scan..."
      
      if let qrResult = codeResult {
         
         var splitString: [String] = qrResult.components(separatedBy: ":")
         let vehicleIdKey = splitString[0]
         let vehicleIdValue = splitString[1]
      
         if let convertString = Int(vehicleIdValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) {
            
            if segmentedControl.selectedSegmentIndex == 0 {
            
                let alertController = UIAlertController(title: "Scan", message: codeResult, preferredStyle: UIAlertControllerStyle.actionSheet)
                
                //TODO: Set enum for reason code, refactor this
                let yardArrival = UIAlertAction(title: "Yard Arrival", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in

                   self.alerts(progressView: progressView, reason: 0, comment: qrResult, convertString: convertString)
                }
                
                let driverCheckin = UIAlertAction(title: "Check In", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                  
                  self.alerts(progressView: progressView, reason: 1, comment: qrResult, convertString: convertString)
                  /*
                  APIManager.shared.postDriverScan(convertString, comment: qrResult, reason: 1, lat: (currentUser?.lastLocation?.latitude)!, long: (currentUser?.lastLocation?.longitude)!, eventId: (currentUser?.route?.event_id)!, routeId: (currentUser?.route?.id)!, passengerCount: nil, scannerId: (currentUser?.id)!, completion: {
                     
                     DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                        progressView.hideHUD()
                        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
                           self.completionAlert()
                        //})
                     })
                   })
                  */
                }
                
                let orientation = UIAlertAction(title: "Orientation Class", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 2, comment: qrResult, convertString: convertString)
                }
                
                let dryRun = UIAlertAction(title: "Dry Run", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 3, comment: qrResult, convertString: convertString)
                }
                
                let driverBriefing = UIAlertAction(title: "Driver Briefing", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 4, comment: qrResult, convertString: convertString)
                }
                
                let hotelDesk = UIAlertAction(title: "Hotel Desk", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 5, comment: qrResult, convertString: convertString)
                }
                
                let yardCheckin = UIAlertAction(title: "Yard Check In", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 6, comment: qrResult, convertString: convertString)
                }
                
                let yardDeparture = UIAlertAction(title: "Departure", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 7, comment: qrResult, convertString: convertString)
                }
                
                let hubArrival = UIAlertAction(title: "Pick-up Hub Arrival", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 8, comment: qrResult, convertString: convertString)
                }
                
                let hubPaxLoad = UIAlertAction(title: "Pick-up Hub Pax Load", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                  
                  let alert = UIAlertController(title: "Number of Passengers", message: "Please add number of passengers", preferredStyle: UIAlertControllerStyle.alert)
               
                  alert.addTextField { (textfield) in
                     textfield.keyboardType = .numberPad
                     textfield.text = "\(50)"
                  }
                  let alertAction = UIAlertAction(title: "Ingress", style: UIAlertActionStyle.default, handler: { (action) in
                     //print(alert.textFields?[0].text!)
                     if let int = Int((alert.textFields?[0].text)!) {
                        progressView.showHUD()
                        APIManager.shared.postDriverScan(convertString, comment: qrResult, reason: 9, lat: (currentUser?.lastLocation?.latitude)!, long: (currentUser?.lastLocation?.longitude)!, eventId: (currentUser?.event_id)!, routeId: (currentUser?.route?.id)!, passengerCount: int, scannerId: (currentUser?.id)!, scanType: "staff", ingress: true, shiftId: currentUser?.event?.waves.first?.id) { (error) in
                           
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
                        APIManager.shared.postDriverScan(convertString, comment: qrResult, reason: 9, lat: (currentUser?.lastLocation?.latitude)!, long: (currentUser?.lastLocation?.longitude)!, eventId: (currentUser?.route?.event_id)!, routeId: (currentUser?.route?.id)!, passengerCount: int, scannerId: (currentUser?.id)!, scanType: "staff", ingress: false, shiftId: currentUser?.event?.waves.first?.id) { (error) in
                           
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
                     self.captureSession?.startRunning()
                     if let qrCodeFrameView = self.qrCodeFrameView {
                        qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                        qrCodeFrameView.layer.borderWidth = 10
                        self.view.addSubview(qrCodeFrameView)
                        self.view.bringSubview(toFront: qrCodeFrameView)
                     }
                  })
                  alert.addAction(alertAction)
                  alert.addAction(egressAction)
                  alert.addAction(cancelAction)
                  self.present(alert, animated: true, completion: {
                     self.captureSession?.stopRunning()
                  })
                }
                
                let dropUnload = UIAlertAction(title: "Drop Zone Unload", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 10, comment: qrResult, convertString: convertString)
                }
                
                let venueLoadOut = UIAlertAction(title: "Venue Load Out", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 11, comment: qrResult, convertString: convertString)
                }
                
                let venueStagingArea = UIAlertAction(title: "Venue Staging Area", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 12, comment: qrResult, convertString: convertString)
                }
                
                let breakIn = UIAlertAction(title: "Break Time In", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 13, comment: qrResult, convertString: convertString)
                }
                
                let breakOut = UIAlertAction(title: "Break Time Out", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 14, comment: qrResult, convertString: convertString)
                }
                
                let outOfServiceMechanical = UIAlertAction(title: "Out of Service", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 15, comment: qrResult, convertString: convertString)
               }
               
               let outOfServiceEmergency = UIAlertAction(title: "Out of Service Emergency", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                  self.alerts(progressView: progressView, reason: 16, comment: qrResult, convertString: convertString)
               }
               
                let shiftOver = UIAlertAction(title: "Shift Over", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   self.alerts(progressView: progressView, reason: 17, comment: qrResult, convertString: convertString)
                }
               
               let noShow = UIAlertAction(title: "No Show", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                  self.alerts(progressView: progressView, reason: 22, comment: qrResult, convertString: convertString)
               }
               
                let passenger = UIAlertAction(title: "Passenger", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                   /*
                    APIManager.shared.postDriverScan(convertString, comment: qrResult, reason: 14, lat: self.lat, long: self.long, eventId: (driver?.route?.event_id)!, routeId: (driver?.route?.id)!, completion: {
                    self.completionAlert()
                    })
                    */
                }
               
               let passengers = UIAlertAction(title: "Passengers", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                  APIManager.shared.postDriverScan(convertString, comment: qrResult, reason: 17, lat: (currentUser?.lastLocation?.latitude)!, long: (currentUser?.lastLocation?.longitude)!, eventId: (currentUser?.route?.event_id)!, routeId: (currentUser?.route?.id)!, passengerCount: nil, scannerId: (currentUser?.id)!, scanType: "staff", ingress: nil, shiftId: currentUser?.event?.waves.first?.id) { (error) in
                     self.completionAlert()
                  }
               }
               
               let infoAction = UIAlertAction(title: "Info", style: .default, handler: { (action) in
                  
               })
               
                //TODO: Refactor
                switch (currentUser?.role)! {
                case "driver":
                   print("driver")
                case "manager":
                  alertController.addAction(yardArrival)
                   alertController.addAction(driverCheckin)
                   alertController.addAction(hubPaxLoad)
                   alertController.addAction(dropUnload)
                   //alertController.addAction(orientation)
                   //alertController.addAction(dryRun)
                   //alertController.addAction(driverBriefing)
                   //alertController.addAction(hotelDesk)
                   alertController.addAction(yardCheckin)
                   alertController.addAction(breakIn)
                   alertController.addAction(breakOut)
                   alertController.addAction(outOfServiceMechanical)
                   alertController.addAction(shiftOver)
               //Ready
                case "staff_yard":
                   alertController.addAction(yardArrival)
                   alertController.addAction(yardDeparture)
                   alertController.addAction(driverCheckin)
                   alertController.addAction(shiftOver)
                   alertController.addAction(outOfServiceMechanical)
               //Ready
               case "craigs_staging":
                  alertController.addAction(driverCheckin)
                  alertController.addAction(yardDeparture)
                  alertController.addAction(shiftOver)
                  alertController.addAction(outOfServiceMechanical)
                //Ready
                case "staff_load":
                  alertController.addAction(driverCheckin)
                  //alertController.addAction(hubArrival)
                  alertController.addAction(hubPaxLoad)
                  alertController.addAction(dropUnload)
                  alertController.addAction(outOfServiceMechanical)
               //Ready
               case "speedway_staging":
                  alertController.addAction(driverCheckin)
                  alertController.addAction(yardDeparture)
                  alertController.addAction(breakIn)
                  alertController.addAction(breakOut)
                  alertController.addAction(outOfServiceMechanical)
                case "route_managers":
                  alertController.addAction(driverBriefing)
                  alertController.addAction(yardArrival)
                  alertController.addAction(driverCheckin)
                  alertController.addAction(hotelDesk)
                  alertController.addAction(shiftOver)
                  alertController.addAction(outOfServiceMechanical)
                case "staff_dispatch":
                   alertController.addAction(driverCheckin)
                   alertController.addAction(orientation)
                   alertController.addAction(dryRun)
                   alertController.addAction(driverBriefing)
                   alertController.addAction(hotelDesk)
                   alertController.addAction(yardCheckin)
                   alertController.addAction(outOfServiceMechanical)
                   alertController.addAction(shiftOver)
               //Ready
                case "staff_break":
                   alertController.addAction(breakIn)
                   alertController.addAction(breakOut)
                   alertController.addAction(outOfServiceMechanical)
               case "route_manager":
                  alertController.addAction(orientation)
                  alertController.addAction(dryRun)
                  alertController.addAction(driverBriefing)
                  alertController.addAction(driverCheckin)
                  alertController.addAction(breakIn)
                  alertController.addAction(breakOut)
                  alertController.addAction(shiftOver)
                  alertController.addAction(outOfServiceMechanical)
                case "staff_drop":
                   alertController.addAction(dropUnload)
                   alertController.addAction(venueStagingArea)
                   alertController.addAction(venueLoadOut)
                   alertController.addAction(outOfServiceMechanical)
                case "mechanical":
                   alertController.addAction(outOfServiceMechanical)
                case "admin":
                  //alertController.addAction(orientation)
                  //alertController.addAction(dryRun)
                  //alertController.addAction(driverBriefing)
                  //alertController.addAction(hotelDesk)
                  //alertController.addAction(yardArrival)
                  
                  //let backView = alertController.view.subviews.last?.subviews.last
                  //backView?.layer.cornerRadius = 10.0
                  //backView?.backgroundColor = UIColor.black
                  
                  //alertController.view.backgroundColor = UIColor.black
                  
                  driverCheckin.setValue(UIColor.flatGreenDark, forKey: "titleTextColor")
                  
                  hubPaxLoad.setValue(UIColor.flatSkyBlue, forKey: "titleTextColor")
                  dropUnload.setValue(UIColor.flatGreenDark, forKey: "titleTextColor")
                  breakIn.setValue(UIColor.flatYellowDark, forKey: "titleTextColor")
                  breakOut.setValue(UIColor.flatGreenDark, forKey: "titleTextColor")
                  shiftOver.setValue(UIColor.flatSkyBlue, forKey: "titleTextColor")
                  outOfServiceMechanical.setValue(UIColor.flatRedDark, forKey: "titleTextColor")
                  outOfServiceEmergency.setValue(UIColor.flatRedDark, forKey: "titleTextColor")
                  noShow.setValue(UIColor.flatRedDark, forKey: "titleTextColor")
                  
                  alertController.addAction(driverCheckin)
                  alertController.addAction(hubPaxLoad)
                  alertController.addAction(dropUnload)
                  //alertController.addAction(yardCheckin)
                  alertController.addAction(breakIn)
                  alertController.addAction(breakOut)
                  alertController.addAction(outOfServiceMechanical)
                  alertController.addAction(outOfServiceEmergency)
                  alertController.addAction(noShow)
                  alertController.addAction(shiftOver)
                default:
                   print("nil")
                }
                
                let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
                  self.captureSession?.startRunning()
                  if let qrCodeFrameView = self.qrCodeFrameView {
                     qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                     qrCodeFrameView.layer.borderWidth = 10
                     self.view.addSubview(qrCodeFrameView)
                     self.view.bringSubview(toFront: qrCodeFrameView)
                  }
                }
               
               //alertController.addAction(infoAction)
               alertController.addAction(cancel)
               
               //if alertController.presentedViewController == nil {
               //present(alertController, animated: true, completion: nil)
               present(alertController, animated: true, completion: { 
                  self.captureSession?.stopRunning()
                  //self.view.addSubview(qrCodeFrameView)
                  self.qrCodeFrameView?.removeFromSuperview()
               })
               //} else {
                  //dismiss(animated: false, completion: {
                     //self.present(alertController, animated: true, completion: nil)
                  //})
               //}
            
            //TODO: When we add passenger service
            } else {
             //var passengers = [String]()
             //var count = 0
             
                 if currentUser?.appSetting?.setTour == false {
                 
                  let alertController = UIAlertController(title: "Scan count \(self.scans.count)", message: codeResult, preferredStyle: UIAlertControllerStyle.alert)
                  let passenger = UIAlertAction(title: "Add Passenger", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                  //driver: Int, comment: String, reason: Int, lat: Float, long: Float, eventId: Int, routeId: Int
                  let scan = ["driver_id": 1, "reason": 14, "event_id": 1, "route_id": (currentUser?.route?.id)!, "vehicle_id": 1, "latitude": currentUser?.lastLocation?.latitude, "longitude": currentUser?.lastLocation?.longitude] as [String : Any]
                  self.scans.append(scan)
                  }
                 
                  alertController.addAction(passenger)
                 
                  let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                     APIManager.shared.bulkScan(self.scans)
                     //If success clear out scans
                     self.scans.removeAll()
                  }
                 
                  alertController.addAction(cancel)
                  present(alertController, animated: true, completion: nil)
                  
                 } else {
                  
                  print(vehicleIdValue)
                  APIManager.shared.getPassenger(phoneNumber: vehicleIdValue, completion: { (response) in
                  if response.response?.statusCode == 200 {
                  let alertController = UIAlertController(title: "Passenger Found", message: "Passenger \(vehicleIdValue) found for event", preferredStyle: UIAlertControllerStyle.alert)
                  let passenger = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                  }
                 
                 alertController.addAction(passenger)
                 self.present(alertController, animated: true, completion: nil)
                 
                  } else {
                 let alertController = UIAlertController(title: "Passenger \(vehicleIdValue) not Found", message: "Please contact.....", preferredStyle: UIAlertControllerStyle.alert)
                 let passenger = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                 }
                 
                 alertController.addAction(passenger)
                 self.present(alertController, animated: true, completion: nil)
                 }
                 })
             
                }
             }
         }
      }
   }
}

extension ViewController: TwicketSegmentedControlDelegate {
   func didSelect(_ segmentIndex: Int) {
   }
}
