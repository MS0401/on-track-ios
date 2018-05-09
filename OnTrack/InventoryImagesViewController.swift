//
//  InventoryImagesViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/5/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Kingfisher

class InventoryImagesViewController: UIViewController {
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    
    var images = [String]()
    var originalImage: UIImage!
    var inventoryItem: Inventory!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 5
        imageView.layer.borderWidth = 2
        /*
        switch (inventoryItem.lastScan?.scanType)! {
        case "received":
            imageView.layer.borderColor = UIColor.flatSkyBlue.cgColor
        case "assigned":
            imageView.layer.borderColor = UIColor.flatGreen.cgColor
        case "out_of_service":
            imageView.layer.borderColor = UIColor.flatRed.cgColor
        default:
            imageView.layer.borderColor = UIColor.flatGray.cgColor
        }
        */
        imageView.layer.borderColor = UIColor.flatGray.cgColor
        
        images.removeAll()
        for image in inventoryItem.images {
            images.append(image.imageUrl)
            if images.first != nil {
                if let url = URL(string: images.first!) {
                    imageView.kf.setImage(with: url)
                }
            } else {
                imageView.image = UIImage(named: "empty")
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(InventoryImagesViewController.refresh), name: NSNotification.Name(rawValue: "inventory"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        //collectionView.reloadData()
    }
    
    @objc func refresh() {
        /*
        if let url = URL(string: (inventoryItem.images.last?.imageUrl)!) {
            imageView.kf.setImage(with: url)
        }
        */
        images.removeAll()
        for image in inventoryItem.images {
            images.append(image.imageUrl)
            if images.first != nil {
                if let url = URL(string: images.first!) {
                    imageView.kf.setImage(with: url)
                }
            } else {
                imageView.image = UIImage(named: "empty")
            }
        }
        collectionView.reloadData()
    }
}

extension InventoryImagesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        /*
        if inventoryItem.images.count > 0 {
            return inventoryItem.images.count
        } else {
            return 3
        }
        */
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCollectionCell", for: indexPath) as! ImageCollectionViewCell
        //cell.imageView.image = images[indexPath.row]
        /*
        if inventoryItem.images.count > 0 {
            if let url = URL(string: inventoryItem.images[indexPath.row].imageUrl) {
                cell.imageView.kf.setImage(with: url)
            }
        } else {
            cell.imageView.image = UIImage(named: "empty")
        }
        */
        if let url = URL(string: images[indexPath.row]) {
            cell.imageView.kf.setImage(with: url)
        }
        cell.imageView.layer.cornerRadius = 5
        cell.imageView.layer.borderWidth = 2
        /*
        switch (inventoryItem.lastScan?.scanType)! {
        case "received":
            cell.imageView.layer.borderColor = UIColor.flatSkyBlue.cgColor
        case "assigned":
            cell.imageView.layer.borderColor = UIColor.flatGreen.cgColor
        case "out_of_service":
            cell.imageView.layer.borderColor = UIColor.flatRed.cgColor
        default:
            cell.imageView.layer.borderColor = UIColor.flatGray.cgColor
        }
        */
        cell.imageView.layer.borderColor = UIColor.flatGray.cgColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //imageView.image = images[indexPath.item]
        if let url = URL(string: images[indexPath.row]) {
            imageView.kf.setImage(with: url)
        }
    }
}
