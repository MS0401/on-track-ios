//
//  LoopsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 10/9/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class LoopsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var loops = [[String: JSON]]()
    var counts = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        loopRequest()
    }
    
    func loopRequest() {
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event!.eventId)/drivers_loop.json?day=\(currentUser!.day!.calendarDay)"

        let headers = [
            "Content-Type": "application/json"
        ]
        
        print(path)
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(json)
                let dict = json["data"].dictionaryValue
                for (key, value) in dict {
                    let dictionary = [key: value]
                    self.loops.append(dictionary)
                    let cnt: Int = value.intValue
                    self.counts.append(cnt)
                }
                
                self.loops.reverse()
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.title = "Loops \(self.counts.count)"
                }

            case .failure:
                break
            }
        }
    }
}

extension LoopsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loops.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "loopsCell", for: indexPath)
        let loop = loops[indexPath.row]
        switch loop.keys.first {
        case "1_loop"?:
            cell.textLabel?.text = "1 Loop"
        case "2_loop"?:
            cell.textLabel?.text = "2 Loops"
        case "3_loop"?:
            cell.textLabel?.text = "3 Loops"
        case "4_loop"?:
            cell.textLabel?.text = "4 Loops"
        case "5_loop"?:
            cell.textLabel?.text = "5 Loops"
        default:
            cell.textLabel?.text = loop.keys.first
        }
        
        cell.detailTextLabel?.text = "\(loop.values.first!.intValue)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
