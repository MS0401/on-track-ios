//
//  PortalViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/2/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class PortalViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.loadRequest(URLRequest(url: URL(string: "https://ontrackmanagement.herokuapp.com/users/sign_in")!))
    }
}
