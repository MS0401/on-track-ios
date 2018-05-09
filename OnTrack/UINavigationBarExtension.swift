//
//  UINavigationBarExtension.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/4/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

extension UINavigationBar {
    func transparentNavigationBar() {
        self.setBackgroundImage(UIImage(), for: .default)
        self.shadowImage = UIImage()
        self.isTranslucent = true
    }
}

extension UIImagePickerController {
    private struct CustomTag {
        static var tag: Int? = nil
    }
    
    var tag: Int? {
        get {
            return CustomTag.tag
        }
        set {
            CustomTag.tag = newValue
        }
    }
}
