//
//  LostAndFoundTableViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/18/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import SwiftyJSON
import RealmSwift

//TODO: If staff member add endpoint for all lost and found on route
//can check if driver else hit all losts endpoint
class LostAndFoundTableViewController: UITableViewController {
    
    var losts = [Lost]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ScheduleTableViewController.refreshControlDidFire), for: .valueChanged)
        tableView?.refreshControl = refreshControl
        
        getLosts()
        
        tableView.tableFooterView = UIView()
    }
    
    func getLosts() {
        APIManager.shared.getEventLosts((currentUser?.event_id)!) { (losts) in
            self.losts.removeAll()
            self.losts = losts.reversed()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func refreshControlDidFire() {
        getLosts()
        tableView?.refreshControl?.endRefreshing()
    }

    @IBAction func newLostItem(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: "Lost and Found",
                                                message: "Please enter rider lost item, rider name and phone number",
                                                preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addTextField { (textfield) in
            textfield.placeholder = "Lost Item"
        }
        alertController.addTextField { (textfield) in
            textfield.placeholder = "Rider Name"
        }
        alertController.addTextField { (textfield) in
            textfield.keyboardType = .phonePad
            textfield.placeholder = "Rider Phone"
        }
        alertController.addTextField { (textfield) in
            textfield.placeholder = "Comments"
        }
        
        let submitAction = UIAlertAction(title: "Lost", style: UIAlertActionStyle.default) { (action) in
            APIManager.shared.postLost((currentUser?.id)!, (currentUser?.event_id)!, (alertController.textFields?[0].text)!,
                                                (alertController.textFields?[1].text)!,
                                                (alertController.textFields?[2].text)!,
                                                [["comment": (alertController.textFields?[3].text)!]], status: 0) { (response) in
                
                if response.response?.statusCode == 201 {
                    let alertController = UIAlertController(title: "Lost Item", message: "Item has been reported lost", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion:nil)
                    
                    self.getLosts()
                }
            }
        }
        
        let foundAction = UIAlertAction(title: "Found", style: UIAlertActionStyle.default) { (action) in
            APIManager.shared.postLost((currentUser?.id)!, (currentUser?.event_id)!, (alertController.textFields?[0].text)!,
                                       (alertController.textFields?[1].text)!,
                                       (alertController.textFields?[2].text)!,
                                       [["comment": (alertController.textFields?[3].text)!]], status: 1) { (response) in
                                        
                if response.response?.statusCode == 201 {
                    let alertController = UIAlertController(title: "Found Item", message: "Item has been reported found", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion:nil)
                    
                    self.getLosts()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(submitAction)
        alertController.addAction(foundAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion:nil)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return losts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "lostCell", for: indexPath) as! LostFoundTableViewCell
        let lost = losts[indexPath.row]
        cell.configueCell(lost: lost)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //performSegue(withIdentifier: "lostDetailSegue", sender: self)
    }
}
