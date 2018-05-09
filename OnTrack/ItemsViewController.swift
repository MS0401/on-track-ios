//
//  ItemsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/19/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import TwicketSegmentedControl

class ItemsViewController: UIViewController, TwicketSegmentedControlDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: TwicketSegmentedControl!
    
    var items = [
        ["image": "suburban", "title": "Chevy Suburban 7 Passenger", "location": "Green Lot", "license": "License #S558347"],
        ["image": "suburban", "title": "Chevy Suburban 7 Passenger", "location": "Green Lot", "license": "License #S558347"],
        ["image": "suburban", "title": "Chevy Suburban 7 Passenger", "location": "Green Lot", "license": "License #S558347"],
        ["image": "pv", "title": "12 Passengers Fullsize Van", "location": "Blue Lot", "license": "License #V213456"],
        ["image": "pv", "title": "12 Passengers Fullsize Van", "location": "Blue Lot", "license": "License #V213456"],
        ["image": "pv", "title": "12 Passengers Fullsize Van", "location": "Blue Lot", "license": "License #V213456"],
        ["image": "cart", "title": "4x4 Vector 500cc UTV", "location": "Green Lot", "license": "License #U55834"],
        ["image": "cart", "title": "4x4 Vector 500cc UTV", "location": "Green Lot", "license": "License #U55834"],
        ["image": "cart", "title": "4x4 Vector 500cc UTV", "location": "Green Lot", "license": "License #U55834"]]
    
    var titles = ["Available", "Checked Out", "Out of Service"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Vehicles"
        tableView.tableFooterView = UIView()
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.sliderBackgroundColor = UIColor.flatSkyBlue
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func didSelect(_ segmentIndex: Int) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "itemDetailSegue" {
            let ip = sender as! IndexPath
            print(ip.row)
            let dict = items[ip.row]
            var dvc = segue.destination as! ItemDetailViewController
            dvc.dict = dict
        }
    }
}

extension ItemsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ItemsTableViewCell
        let item = items[indexPath.row]
        cell.setupCell(item: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "itemDetailSegue", sender: indexPath)
    }
}
