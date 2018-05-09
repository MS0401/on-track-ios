//
//  TermsViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/26/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class TermsViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.loadRequest(URLRequest(url: URL(string: "https://www.ontrackeventmanagement.com/")!))
    }
}
