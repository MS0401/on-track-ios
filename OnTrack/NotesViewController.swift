//
//  NotesViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 6/28/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class NotesViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func dismissVC(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

extension NotesViewController: UITextViewDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView.endEditing(true)
    }
}
