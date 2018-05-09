//
//  TaskDetailViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON

class TaskDetailViewController: UIViewController {

    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var completedButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    let realm = try! Realm()
    var items = ["One", "Two", "Three", "Four"]
    var id: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let getId = id {
           getInventory(id: getId)
        }
        
        title = "Install Generator"
        
        itemImageView.layer.cornerRadius = 8
        
        startButton.layer.cornerRadius = 4
        startButton.layer.borderWidth = 1
        startButton.layer.borderColor = UIColor.white.cgColor
        startButton.setTitleColor(.white, for: .normal)
        
        completedButton.layer.cornerRadius = 4
        completedButton.layer.borderWidth = 1
        completedButton.layer.borderColor = UIColor.flatSkyBlue.cgColor
        completedButton.setTitleColor(UIColor.flatSkyBlue, for: .normal)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func getInventory(id: Int) {
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
                print(json)
            case .failure:
                break
            }
        }
    }
}

extension TaskDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCell", for: indexPath) as! TaskTimelineTableViewCell
        switch indexPath.row {
        case 0:
            cell.reasonView.backgroundColor = UIColor.flatGray
            cell.statusView.text = "Assigned"
        case 1:
            cell.reasonView.backgroundColor = UIColor.flatSkyBlue
            cell.statusView.text = "Task Started"
        case 2:
            cell.reasonView.backgroundColor = UIColor.flatBrown
            cell.statusView.text = "Completed"
        case 3:
            cell.reasonView.backgroundColor = UIColor.flatGreen
            cell.statusView.text = "Accepted"
            cell.ownerView.text = "OnTrack"
        default:
            cell.reasonView.backgroundColor = UIColor.flatGreen
            cell.statusView.text = "Assigned"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
