//
//  Message.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 2/9/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import SwiftyJSON

class Message {
    var driver_id: Int?
    var body: String
    var from_number: String?
    var date: Date?
    var phone_number: String?
    var isSender: Bool?
    var eventId: Int!
    var id: Int!
    
    init(body: String) {
        self.body = body
    }
    
    init(json: JSON) {
        self.body = json["body"].stringValue
        
        if json["from_number"] != nil {
            self.isSender = false
        }
    }
}
