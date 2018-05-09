//
//  VerifyViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/4/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift
import SwiftyJSON
import PinCodeTextField
import ACProgressHUD_Swift

class VerifyViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var pinCodeTextField: PinCodeTextField!
    
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.transparentNavigationBar()
        pinCodeTextField.delegate = self
        pinCodeTextField.keyboardType = .numberPad
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func verifyCode(_ sender: UIBarButtonItem) {
        verifySMS()
    }
    
    @IBAction func resendCode(_ sender: UIButton) {
        if let cell = currentUser?.cell {
            APIManager.shared.verifyUserCell(cell, completion: { (response, error) in
                
            })
            //APIManager.shared.verifyUserCell(cell) { (response),<#arg#>  in }
        }
    }
    
    func verfied() {
        if let role = currentUser?.role {
            switch role {
            case "driver":
                performSegue(withIdentifier: "driversSegue", sender: self)
            case "admin":
                performSegue(withIdentifier: "eventsSegue", sender: self)
            case "client":
                performSegue(withIdentifier: "clientSegue", sender: self)
            case "route_managers":
                performSegue(withIdentifier: "projectManagementSegue", sender: self)
            default:
                performSegue(withIdentifier: "staffSegue", sender: self)
            }
        } else if self.realm.objects(User.self).first != nil {
            performSegue(withIdentifier: "projectManagementSegue", sender: self)
        }
    }
    
    func verifySMS() {
        if let code = pinCodeTextField.text, let cell = self.realm.objects(Defaults.self).first?.cell {
            let progressView = ACProgressHUD.shared
            progressView.progressText = "Validating Code..."
            progressView.showHUD()
            
            APIManager.shared.verifyCode("\(cell)", code: code) { (response, error) in
                
                let when = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: when) {
                    if error != nil {
                        progressView.hideHUD()
                        self.setAlert(title: "Error", message: "Event has not been activated.")
                    } else {
                        
                        if response.response?.statusCode == 200 {
                            progressView.hideHUD()
                            self.verfied()
                        } else {
                            progressView.hideHUD()
                            self.setAlert(title: "Error", message: "Incorrect Pin please try again or tap 'Resend SMS Code' to request a new pin.")
                        }
                    }
                }
            }
        }
    }
    
    func verifyInventorySMS() {
        if let code = pinCodeTextField.text, let cell = self.realm.objects(Defaults.self).first?.cell {
            
            let path = "\(BASE_URL_INVENTORY)/api/sessions/verify_pin"
            print(path)
            let headers = [
                "Content-Type": "application/json"
            ]
            
            let parameters = [
                "cell": "1\(cell)",
                "pin": code
            ]
            
            
            /*
             let progressView = ACProgressHUD.shared
             progressView.progressText = "Verifing Phone Number..."
             progressView.showHUD()
             let when = DispatchTime.now() + 2
             */
            
            Alamofire.request(path, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                switch response.result {
                case .success(let jsonObject):
                    let json = JSON(jsonObject)
                    print(json)
                    try! self.realm.write {
                        
                        if self.realm.objects(User.self).first != nil {
                            self.realm.deleteAll()
                        }
                        
                        let user = User(json: json["data"])
                        self.realm.add(user, update: true)
                        self.performSegue(withIdentifier: "projectManagementSegue", sender: self)
                    }
                    
                case .failure:
                    break
                }
            }
        }
    }
    
    func setAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion:nil)
    }
}

extension VerifyViewController: PinCodeTextFieldDelegate {
    
    @nonobjc func textFieldShouldBeginEditing(_ textField: PinCodeTextField) -> Bool {
        return true
    }
    
    @nonobjc func textFieldDidBeginEditing(_ textField: PinCodeTextField) {
    }
    
    @nonobjc func textFieldDidEndEditing(_ textField: PinCodeTextField) {
    }
    
    func textFieldValueChanged(_ textField: PinCodeTextField) {
        let numbers = textField.text?.characters.count
        if numbers == 4 {
            let ac = UIAlertController(title: "Select", message: "Please make selection", preferredStyle: .alert)
            let aAction = UIAlertAction(title: "Asset Management", style: .default, handler: { (action) in
                self.verifyInventorySMS()
            })
            
            let bAction = UIAlertAction(title: "Transportation", style: .default, handler: { (action) in
                self.verifySMS()
            })
            
            ac.addAction(aAction)
            ac.addAction(bAction)
            self.present(ac, animated: true, completion: nil)
        }
    }
    
    @nonobjc func textFieldShouldEndEditing(_ textField: PinCodeTextField) -> Bool {
        return true
    }
    
    @nonobjc func textFieldShouldReturn(_ textField: PinCodeTextField) -> Bool {
        return true
    }
}
