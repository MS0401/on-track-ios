//
//  ImagePinchViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 7/6/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class ImagePinchViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mapImageView: UIImageView!
    
    var stringImage: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        
        mapImageView.image = UIImage(named: stringImage)
    }

    @IBAction func dismissVC(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

extension ImagePinchViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mapImageView
    }
}
