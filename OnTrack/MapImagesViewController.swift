//
//  MapImagesViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/6/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class MapImagesViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var images = ["inbound", "outbound", "outbound2"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "imageSegue" {
            let dvc = segue.destination as! ImagePinchViewController
            dvc.stringImage = sender as! String
        }
    }
}

extension MapImagesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageMapCollectionViewCell
        cell.imageView.image = UIImage(named: images[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let image = images[indexPath.item]
        performSegue(withIdentifier: "imageSegue", sender: image)
    }
}
