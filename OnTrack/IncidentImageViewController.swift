//
//  IncidentImageViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/14/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Kingfisher

class IncidentImageViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    
    var incident: Incident!
    var images = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 5
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.flatSkyBlue.cgColor
        
        for image in incident.images {
            images.append(image.imageUrl)
            if incident.images.first != nil {
                if let url = URL(string: (incident.images.first?.imageUrl)!) {
                    imageView.kf.setImage(with: url)
                }
            } else {
                imageView.image = UIImage(named: "empty")
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(IncidentImageViewController.refresh), name: NSNotification.Name(rawValue: "incident"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    @objc func refresh() {
        print("refresh triggered")
        print("from refresh \(incident)")
        collectionView.reloadData()
    }

}

extension IncidentImageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return incident.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCollectionCell", for: indexPath) as! ImageCollectionViewCell

        if let url = URL(string: incident.images[indexPath.row].imageUrl) {
            cell.imageView.kf.setImage(with: url)
        }
        cell.imageView.layer.cornerRadius = 5
        cell.imageView.layer.borderWidth = 2
        cell.imageView.layer.borderColor = UIColor.flatSkyBlue.cgColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //imageView.image = images[indexPath.item]
        if let url = URL(string: incident.images[indexPath.row].imageUrl) {
            imageView.kf.setImage(with: url)
        }
    }
}
