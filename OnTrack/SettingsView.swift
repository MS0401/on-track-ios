//
//  SettingsView.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/24/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

protocol SettingsViewDelegate {
    func hideSettingsView(status: Bool)
    func didSelectRow(indexPath: Int)
    var count: Int { get set }
    var tbHeight: Int { get set }
}

class SettingsView: UIView, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: Properties
    var items = [String]()
    var imageNames = [String]()
    var delegate: SettingsViewDelegate?
    
    lazy var tableView: UITableView = {
        let tb = UITableView.init(frame: CGRect.init(x: 0, y: Int(self.bounds.height), width: Int(self.bounds.width), height: 0))
        tb.isScrollEnabled = false
        return tb
    }()
    
    lazy var backgroundView: UIView = {
        let bv = UIView.init(frame: self.frame)
        bv.backgroundColor = UIColor.black
        bv.alpha = 0
        return bv
    }()
    
    //MARK: View Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(SettingsView.dismiss)))
        addSubview(self.backgroundView)
        addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.backgroundColor = UIColor(red: 31/255, green: 37/255, blue: 51/255, alpha: 1.0)
        tableView.separatorColor = UIColor(red: 14/255, green: 16/255, blue: 20/255, alpha: 1.0)
    }

    //MARK: Methods
    func animate()  {
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.frame.origin.y -= CGFloat(48 * (self.delegate?.count)!)
            self.backgroundView.alpha = 0.5
        })
    }
    
    @objc func  dismiss()  {
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView.alpha = 0
            self.tableView.frame.origin.y += CGFloat(48 * (self.delegate?.count)!)//336
        }, completion: {(Bool) in
            self.delegate?.hideSettingsView(status: true)
        })
    }
    
    //MARK: TableView Delegate, DataSource methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(delegate?.count)
        return (delegate?.count)!//items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        cell.imageView?.image = UIImage(named: imageNames[indexPath.row])
        cell.selectionStyle = .none
        cell.textLabel?.textColor = UIColor(red: 240/255, green: 242/255, blue: 245/255, alpha: 1.0)
        cell.imageView?.backgroundColor = UIColor(red: 22/255, green: 26/255, blue: 33/255, alpha: 0.88)
        cell.backgroundColor = UIColor(red: 22/255, green: 26/255, blue: 33/255, alpha: 0.88)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectRow(indexPath: indexPath.row)
        dismiss()
    }
}
