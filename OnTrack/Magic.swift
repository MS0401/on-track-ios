//
//  Magic.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 1/25/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

//Realm Magic
//Find exception at crash
//put in RLMUtil.mm at static NSException *RLMException(NSString *reason, NSDictionary *additionalUserInfo) {}
//a int = 0
//if (reason == nil) {
//    a = 1;
//}
//NSLog(@"calculating 1 / %d = %f", a, 1 / a);
//Activate event
/*
1) Day is created for that day.
2) routes are assigned to day
3) that route has the shift you want to activate
3) current time is between the shift_times (if you want to activate instantly)
*/

/*

 messages reverse array
 
 kings OnTrack - Jimmy and Lauren
 
 loops from statistics

*/


