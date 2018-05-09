//
//  ScanType.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation

enum ScanType: String {
    case yardArrival = "yard_arrival"
    case driverCheckin = "driver_check_in"
    case orientation = "orientation"
    case dryRun = "dry_run"
    case driverBriefing = "driver_briefing"
    case hotelDesk = "hotel_desk"
    case yardIn = "yard_id"
    case yardOut = "yard_out"
    case pickupArrival = "pick_up_arrival"
    case pickupPax = "pick_up_pax"
    case dropUnload = "drop_unload"
    case venueLoadOut = "venue_load_out"
    case venueStaging = "venue_staging"
    case breakIn = "break_in"
    case breakOut = "break_out"
    case outOfServiceMechanical = "out_of_service_mechanical"
    case outOfServiceEmergency = "out_of_service_emergency"
    case endShift = "end_shift"
    case passenger = "passenger"
}
