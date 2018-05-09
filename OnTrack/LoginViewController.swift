//
//  LoginViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 11/11/16.
//  Copyright © 2016 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift
import SwiftyJSON
import RevealingSplashView
import PinCodeTextField
import ACProgressHUD_Swift
import BWWalkthrough

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var pinCodeTextField: PinCodeTextField!
    
    lazy var realm = try! Realm()
    var isInventory = false
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.transparentNavigationBar()
        setNeedsStatusBarAppearanceUpdate()
        
        if let role = realm.objects(RealmDriver.self).first?.role {
            switch role {
            case "driver":
                launchViewController(name: "Main", withIdentifier: "DriverMenu")
            case "admin":
                launchViewController(name: "Main", withIdentifier: "AdminMenu")
            case "route_managers":
                launchViewController(name: "Inventory", withIdentifier: "NavigationPM")
            default:
                launchViewController(name: "Main", withIdentifier: "StaffMenu")
            }
        } else if self.realm.objects(User.self).first != nil {
            launchViewController(name: "Inventory", withIdentifier: "NavigationPM")
        }
        
        print(realm.configuration.fileURL!)
        
        pinCodeTextField.delegate = self
        pinCodeTextField.keyboardType = .numberPad
        
        if let defaults = realm.objects(Defaults.self).first {
            if defaults.didWalkthrough == true {
                let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "logo")!,iconInitialSize: CGSize(width: 206, height: 151), backgroundColor: UIColor(red: 22/255, green: 26/255, blue: 33/255, alpha: 1.0))
                
                view.addSubview(revealingSplashView)
                
                revealingSplashView.startAnimation(){
                    
                }
            } else {
                showWalkthrough()
            }
        } else {
            let d = Defaults(walk: false)
            try! realm.write {
                realm.add(d)
            }
            showWalkthrough()
        }
    }
    
    @IBAction func login(_ sender: UIBarButtonItem) {
        loginDriver()
    }
    
    func launchViewController(name: String, withIdentifier: String) {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: withIdentifier)
        self.present(controller, animated: true, completion: nil)
    }
    
    func loginDriver() {
        if let code = pinCodeTextField.text {
            
            APIManager.shared.verifyUserCell("\(code)") { (response, error) in
                
                let progressView = ACProgressHUD.shared
                progressView.progressText = "Verifing Phone Number..."
                progressView.showHUD()
                let when = DispatchTime.now() + 2
                
                DispatchQueue.main.asyncAfter(deadline: when) {
                    
                    if error != nil {
                        progressView.hideHUD()
                        let alertController = UIAlertController(title: "Error", message: "Incorrect phone number, please try again", preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                        }
                        
                        alertController.addAction(OKAction)
                        self.present(alertController, animated: true, completion:nil)
                        
                    } else {
                        
                        if response.response?.statusCode == 200 {
                            progressView.hideHUD()
                            
                            try! self.realm.write {
                                let defaults = self.realm.objects(Defaults.self).first
                                defaults?.cell = code
                            }
                            
                            self.performSegue(withIdentifier: "verifySegue", sender: self)
                        } else {
                            progressView.hideHUD()
                            let alertController = UIAlertController(title: "Error", message: "Incorrect phone number, please try again", preferredStyle: .alert)
                            let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                            }
                            
                            alertController.addAction(OKAction)
                            self.present(alertController, animated: true, completion:nil)
                        }
                    }
                }
            }
        }
    }
    
    func loginInventory() {
        if let code = pinCodeTextField.text {
            
            let path = "\(BASE_URL_INVENTORY)/api/sessions/create_pin"
            print(path)
            let headers = [
                "Content-Type": "application/json"
            ]
        
            let parameters = [
                "cell": "1\(code)"
            ]
            
            print("1\(code)")
            
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
                    if json["data"]["success"] == true {
                        try! self.realm.write {
                            let defaults = self.realm.objects(Defaults.self).first
                            defaults?.cell = code
                        }
                        self.performSegue(withIdentifier: "verifySegue", sender: self)
                    }
                case .failure:
                    break
                }
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}

extension LoginViewController: BWWalkthroughViewControllerDelegate {
    
    func showWalkthrough() {
        let stb = UIStoryboard(name: "Walkthrough", bundle: nil)
        let walkthrough = stb.instantiateViewController(withIdentifier: "walk") as! BWWalkthroughViewController
        let page_one = stb.instantiateViewController(withIdentifier: "walk1")
        let page_two = stb.instantiateViewController(withIdentifier: "walk2")
        let page_three = stb.instantiateViewController(withIdentifier: "walk3")
        let page_four = stb.instantiateViewController(withIdentifier: "walk4")
        
        walkthrough.delegate = self
        walkthrough.add(viewController:page_one)
        walkthrough.add(viewController:page_two)
        walkthrough.add(viewController:page_three)
        walkthrough.add(viewController:page_four)
        
        self.present(walkthrough, animated: true, completion: nil)
    }

    func walkthroughPageDidChange(_ pageNumber: Int) {
        //print("Current Page \(pageNumber)")
    }
    
    func walkthroughCloseButtonPressed() {
        self.dismiss(animated: true, completion: nil)
        try! realm.write {
            let defaults = realm.objects(Defaults.self).first
            defaults?.didWalkthrough = true
        }
    }
}

extension LoginViewController: PinCodeTextFieldDelegate {
    
    @nonobjc func textFieldShouldBeginEditing(_ textField: PinCodeTextField) -> Bool {
        return true
    }
    
    @nonobjc func textFieldDidBeginEditing(_ textField: PinCodeTextField) {
    }
    
    @nonobjc func textFieldDidEndEditing(_ textField: PinCodeTextField) {
    }
    
    func textFieldValueChanged(_ textField: PinCodeTextField) {
        let numbers = textField.text?.characters.count
        if numbers == 10 {
            
            let ac = UIAlertController(title: "Select", message: "Please make selection", preferredStyle: .alert)
            let aAction = UIAlertAction(title: "Asset Management", style: .default, handler: { (action) in
                print("inventory")
                self.loginInventory()
            })
            
            let bAction = UIAlertAction(title: "Transportation", style: .default, handler: { (action) in
                self.loginDriver()
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
