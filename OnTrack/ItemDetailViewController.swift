//
//  ItemDetailViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class ItemDetailViewController: UIViewController {

    @IBOutlet weak var itemTitle: UILabel!
    @IBOutlet weak var itemIdentifier: UILabel!
    @IBOutlet weak var checkoutButton: UIButton!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    var items = ["One", "Two"]
    var dict: [String: String]!
    var id: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //print(id)
        title = dict["title"]
        itemTitle.text = dict["title"]
        itemIdentifier.text = dict["license"]
        imageView.image = UIImage(named: dict["image"]!)
        
        imageView.layer.cornerRadius = 8
        
        checkoutButton.layer.cornerRadius = 4
        checkoutButton.layer.borderWidth = 1
        checkoutButton.layer.borderColor = UIColor.white.cgColor
        checkoutButton.setTitleColor(.white, for: .normal)
        
        returnButton.layer.cornerRadius = 4
        returnButton.layer.borderWidth = 1
        returnButton.layer.borderColor = UIColor.flatSkyBlue.cgColor
        returnButton.setTitleColor(UIColor.flatSkyBlue, for: .normal)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    @IBAction func checkoutItem(_ sender: UIButton) {
        loadingIndicator()
    }
    
    @IBAction func returnItem(_ sender: UIButton) {
        performSegue(withIdentifier: "scanItemSegue", sender: self)
    }
    
    func loadingIndicator(){
        let dialog = AZDialogViewController(title: "Checking out item name...", message: "please wait...")
        
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
            dialog.message = "Verifiying..."
            
            when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when) {
                dialog.message = "Removing from inventory..."
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                    dialog.title = "Approved"
                    dialog.message = "Thank You"
                    ///dialog.image = #imageLiteral(resourceName: "image")
                    dialog.customViewSizeRatio = 0
                    
                        dialog.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                            
                            dialog.dismiss()
                            
                        }))
                    
                    //dialog.cancelEnabled = !dialog.cancelEnabled
                    dialog.dismissDirection = .bottom
                    dialog.allowDragGesture = true
                }
            }
        }
        
        dialog.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor.flatSkyBlue
            button.setTitle("CANCEL", for: [])
            return false
        }
    }

}

extension ItemDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "checkoutCell", for: indexPath) as! ItemTableViewCell
        switch indexPath.row {
        case 0:
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
            cell.checkOutLabel.text = "Checked Out by: Sonia Coleman"
            cell.timeLabel.text = "Time: July 22, 10:30 AM"
        case 1:
            cell.reasonView.backgroundColor = UIColor.flatGreen
            cell.checkOutLabel.text = "Returned by: Sonia Coleman"
            cell.timeLabel.text = "Time: July 22, 12:00 PM"
        case 2:
            cell.reasonView.backgroundColor = UIColor.flatRed
            cell.checkOutLabel.text = "Out of Service"
        default:
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
