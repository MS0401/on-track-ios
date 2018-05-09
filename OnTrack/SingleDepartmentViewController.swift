//
//  SingleDepartmentViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/28/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import UICircularProgressRing

class SingleDepartmentController: UIViewController {
    
    @IBOutlet weak var progressRing: UICircularProgressRingView!
    @IBOutlet weak var tableView: UITableView!
    
    var departmentNumber: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ///DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            switch self.departmentNumber {
            case 0:
                // "$15,000"
                self.title = "Merchandise"
                self.progressRing.maxValue = CGFloat(15000.0)
                self.progressRing.setProgress(value: CGFloat(15000.0), animationDuration: 2.0)
            case 1:
                // "$22,000"
                self.title = "Food & Beverage"
                self.progressRing.maxValue = CGFloat(22000.0)
                self.progressRing.setProgress(value: CGFloat(22000.0), animationDuration: 2.0)
            case 2:
                //"$20,000"
                self.title = "Operations"
                self.progressRing.maxValue = CGFloat(20000.0)
                self.progressRing.setProgress(value: CGFloat(20000.0), animationDuration: 2.0)
            case 3:
                // "$15,000"
                self.title = "Site Ops"
                self.progressRing.maxValue = CGFloat(15000.0)
                self.progressRing.setProgress(value: CGFloat(15000.0), animationDuration: 2.0)
            case 4:
                // "$28,000"
                self.title = "Transportation"
                self.progressRing.maxValue = CGFloat(28000.0)
                self.progressRing.setProgress(value: CGFloat(28000.0), animationDuration: 2.0)
            default:
                break
            }
        //}
    }
    
}

extension SingleDepartmentController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "singleDepartmentCell", for: indexPath)
        
            switch indexPath.row {
            case 0:
                switch departmentNumber {
                case 0:
                    cell.textLabel?.text = "Tents"
                    cell.detailTextLabel?.text = "$5,000"
                case 1:
                    cell.textLabel?.text = "Tents"
                    cell.detailTextLabel?.text = "$10,000"
                case 2:
                    cell.textLabel?.text = "Tents"
                    cell.detailTextLabel?.text = "$8,000"
                case 3:
                    cell.textLabel?.text = "Tents"
                    cell.detailTextLabel?.text = "$6,000"
                case 4:
                    cell.textLabel?.text = "Tents"
                    cell.detailTextLabel?.text = "$10,000"
                default:
                    break
                }
                
            case 1:
            
                switch departmentNumber {
                case 0:
                    cell.textLabel?.text = "Radios"
                    cell.detailTextLabel?.text = "$2,000"
                case 1:
                    cell.textLabel?.text = "Radios"
                    cell.detailTextLabel?.text = "$3,000"
                case 2:
                    cell.textLabel?.text = "Radios"
                    cell.detailTextLabel?.text = "$2,000"
                case 3:
                    cell.textLabel?.text = "Radios"
                    cell.detailTextLabel?.text = "$2,000"
                case 4:
                    cell.textLabel?.text = "Radios"
                    cell.detailTextLabel?.text = "$3,000"
                default:
                    break
                }
            case 2:
                
                switch departmentNumber {
                case 0:
                    cell.textLabel?.text = "Meals"
                    cell.detailTextLabel?.text = "$1,000"
                case 1:
                    cell.textLabel?.text = "Meals"
                    cell.detailTextLabel?.text = "$2,000"
                case 2:
                    cell.textLabel?.text = "Meals"
                    cell.detailTextLabel?.text = "$2,000"
                case 3:
                    cell.textLabel?.text = "Meals"
                    cell.detailTextLabel?.text = "$2,000"
                case 4:
                    cell.textLabel?.text = "Meals"
                    cell.detailTextLabel?.text = "$4,000"
                default:
                    break
                }
            case 3:
                
                switch departmentNumber {
                case 0:
                    cell.textLabel?.text = "Fuel"
                    cell.detailTextLabel?.text = "$5,000"
                case 1:
                    cell.textLabel?.text = "Fuel"
                    cell.detailTextLabel?.text = "$5,000"
                case 2:
                    cell.textLabel?.text = "Fuel"
                    cell.detailTextLabel?.text = "$6,000"
                case 3:
                    cell.textLabel?.text = "Fuel"
                    cell.detailTextLabel?.text = "$4,000"
                case 4:
                    cell.textLabel?.text = "Fuel"
                    cell.detailTextLabel?.text = "$10,000"
                default:
                    break
                }
            case 4:
    
                switch departmentNumber {
                case 0:
                    cell.textLabel?.text = "Power"
                    cell.detailTextLabel?.text = "$2,000"
                case 1:
                    cell.textLabel?.text = "Power"
                    cell.detailTextLabel?.text = "$2,000"
                case 2:
                    cell.textLabel?.text = "Power"
                    cell.detailTextLabel?.text = "$2,000"
                case 3:
                    cell.textLabel?.text = "Power"
                    cell.detailTextLabel?.text = "$1,000"
                case 4:
                    cell.textLabel?.text = "Power"
                    cell.detailTextLabel?.text = "$1,000"
                default:
                    break
                }
            default:
                break
            }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}



