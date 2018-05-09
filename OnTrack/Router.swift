//
//  Router.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 4/20/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import Foundation
import Alamofire

enum Router: URLRequestConvertible {
    static let baseURLString = "https://ontrackmanagement.herokuapp.com"
    //static let baseURLString = "https://ontrackdevelopment.herokuapp.com"
    //static let baseURLString = "http://localhost:3000"
    
    case getSettings
    case createPin(phoneNumber: String)
    case verifyCode(driverCell: String, code: String)
    case getUser(phoneNumber: String)
    case getDriver(driverId: Int)
    case getStaff
    case getStaffMember(eventId: Int, shiftId: Int, driverId: Int)
    case getLastLocation(driverId: Int)
    case postText(parameters: Parameters)
    case postNotification(parameters: Parameters)
    case postLocation(parameters: Parameters)
    case getLocations
    case getRoutes
    //case getZones(eventId: Int)
    case getMessages(driverId: Int)
    case getRouteInfo(routeId: Int)
    case getRouteDrivers(routeId: Int)
    case getRouteShifts(routeId: Int)
    case getPassenger(phoneNumber: String)
    case getLosts(eventId: Int)
    case postLosts(eventId: Int)
    case getCheckedIn(parameters: Parameters)
    
    var method: HTTPMethod {
        switch self {
        case .getSettings:
            return .get
        case .createPin:
            return .get
        case .verifyCode:
            return .get
        case .getUser:
            return .get
        case .getDriver:
            return .get
        case .getStaff:
            return .get
        case .getStaffMember:
            return .get
        case .getLastLocation:
            return .get
        case .postText:
            return .post
        case .postNotification:
            return .post
        case .postLocation:
            return .post
        case .getLocations:
            return .get
        case .getRoutes:
            return .get
        //case .getZones:
            //return .get
        case .getMessages:
            return .get
        case .getRouteInfo:
            return .get
        case .getRouteDrivers:
            return .get
        case .getRouteShifts:
            return .get
        case .getPassenger:
            return .get
        case .getLosts:
            return .get
        case .postLosts:
            return .post
        case .getCheckedIn:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .getSettings:
            return "api/v1/app_setting"
        case .createPin(let phoneNumber):
            return "api/v1/drivers/\(phoneNumber)/create_pin"
        case .verifyCode(let driverCell, let code):
            return "api/v1/drivers/\(driverCell)/verify?pin=\(code)"
        case .getUser(let phoneNumber):
            return "api/v1/drivers/\(phoneNumber)/create_pin"
        case .getDriver(let driverId):
            return "api/v1/drivers/\(driverId)"
        case .getLastLocation(let driverId):
            return "api/v1/drivers/\(driverId)/last_location"
        case .getStaff:
            return "api/v1/drivers/staff.json"
        case .getStaffMember(let eventId, let shiftId, let driverId):
            return "api/v1/events/\(eventId)/shifts/\(shiftId)/drivers/\(driverId)/staff_member.json?day=\(currentUser!.day!.calendarDay)"//"api/v1/drivers/\(driverId)/staff_member.json"
        case .postText:
            return "api/v1/messages/message_received"
        case .postNotification:
            return "api/v1/notifications"
        case .postLocation:
            return "api/v1/locations.json"
        case .getLocations:
            return "api/v1/locations.json"
        case .getRoutes:
            return "api/v1/routes"
        //case .getZones(let eventId):
            //return "api/v1/zones.json?event_id=\(eventId)"
        case .getMessages(let driverId):
            return "api/v1/events/1/messages/\(driverId).json"
        case .getRouteInfo(let routeId):
            return "api/v1/routes/\(routeId)"
        case .getRouteDrivers(let routeId):
            return "api/v1/routes/\(routeId).json"
        case .getRouteShifts(let routeId):
            return "/api/v1/shifts.json?route_id=\(routeId)"
        case .getPassenger(let phoneNumber):
            return "api/v1/passengers/\(phoneNumber)/check_passenger.json"
        case .getLosts(let eventId):
            return "api/v1/events/\(eventId)/lost_and_founds.json"
        case .postLosts(let eventId):
            return "api/v1/events/\(eventId)/lost_and_founds.json"
        case .getCheckedIn:
            return "api/v1/events/1/drivers.json"
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try Router.baseURLString.asURL()
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        
        switch self {
        case .postText(let parameters):
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        //case .postLosts(_, let parameters):
            //urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        case .postNotification(let parameters):
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        case .postLocation(let parameters):
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        case .getCheckedIn(let parameters):
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        default:
            break
        }
        
        return urlRequest
    }
}
