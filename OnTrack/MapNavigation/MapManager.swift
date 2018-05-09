//
//  MapManager.swift
//
//
//  Created by Andrei Opanasenko on 18/01/18.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import CoreLocation
import MapKit

typealias DirectionsCompletionHandler = ((_ currentRoute: MKRoute?, _ route:MKPolyline?, _ directionInformation:NSDictionary?, _ boundingRegion:MKMapRect?, _ error:String?)->())?

// TODO: Documentation
@available(iOS 10.0, *)
class MapManager: NSObject{
    
    private var directionsCompletionHandler:DirectionsCompletionHandler
    private let errorNoRoutesAvailable = "No routes available"// add more error handling
    
    private let errorDictionary = ["NOT_FOUND" : "At least one of the locations specified in the request's origin, destination, or waypoints could not be geocoded",
        "ZERO_RESULTS":"No route could be found between the origin and destination",
        "MAX_WAYPOINTS_EXCEEDED":"Too many waypointss were provided in the request The maximum allowed waypoints is 8, plus the origin, and destination",
        "INVALID_REQUEST":"The provided request was invalid. Common causes of this status include an invalid parameter or parameter value",
        "OVER_QUERY_LIMIT":"Service has received too many requests from your application within the allowed time period",
        "REQUEST_DENIED":"Service denied use of the directions service by your application",
        "UNKNOWN_ERROR":"Directions request could not be processed due to a server error. Please try again"]
    
    override init(){
        super.init()
    }
    
    func directions(from:CLLocationCoordinate2D,to:NSString,directionCompletionHandler:DirectionsCompletionHandler){
        self.directionsCompletionHandler = directionCompletionHandler
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(to as String, completionHandler: { (placemarksObject, error) -> Void in
            if let error = error {
                self.directionsCompletionHandler!(nil,nil, nil, nil, error.localizedDescription)
            }
            else {
                let placemark = placemarksObject!.last!
                
                let placemarkSource = MKPlacemark(coordinate: from, addressDictionary: nil)
                
                let source = MKMapItem(placemark: placemarkSource)
                let placemarkDestination = MKPlacemark(placemark: placemark)
                let destination = MKMapItem(placemark: placemarkDestination)
                
                self.directionsFor(source: source, destination: destination, directionCompletionHandler: directionCompletionHandler)
            }
        })
    }    
    
    func directionsFromCurrentLocation(to:CLLocationCoordinate2D,directionCompletionHandler:DirectionsCompletionHandler){
        let source = MKMapItem.forCurrentLocation()
        let placemarkDestination = MKPlacemark(coordinate: to, addressDictionary: nil)
        let destination = MKMapItem(placemark: placemarkDestination)
        directionsFor(source: source, destination: destination, directionCompletionHandler: directionCompletionHandler)
    }
    
    func directions(from:CLLocationCoordinate2D, to:CLLocationCoordinate2D,directionCompletionHandler:DirectionsCompletionHandler){
        let placemarkSource = MKPlacemark(coordinate: from, addressDictionary: nil)
        let source = MKMapItem(placemark: placemarkSource)
        let placemarkDestination = MKPlacemark(coordinate: to, addressDictionary: nil)
        let destination = MKMapItem(placemark: placemarkDestination)
        directionsFor(source: source, destination: destination, directionCompletionHandler: directionCompletionHandler)
    }
    
    private func directionsFor(source:MKMapItem, destination:MKMapItem, directionCompletionHandler:DirectionsCompletionHandler){
        self.directionsCompletionHandler = directionCompletionHandler
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = source
        directionRequest.destination = destination
        directionRequest.transportType = MKDirectionsTransportType.any
        directionRequest.requestsAlternateRoutes = true
        let directions = MKDirections(request: directionRequest)
        directions.calculate(completionHandler: { (response, error) -> Void in
            if let error = error {
                self.directionsCompletionHandler!(nil,nil, nil, nil, error.localizedDescription)
            }
            else if response!.routes.isEmpty {
                self.directionsCompletionHandler!(nil,nil, nil, nil, self.errorNoRoutesAvailable)
            }
            else{
                let route: MKRoute = response!.routes[0]
                let steps = route.steps as NSArray
                let end_address = route.name
                let distance = route.distance.description
                let duration = route.expectedTravelTime.description
                
                let source = response!.source.placemark.coordinate
                let destination = response!.destination.placemark.coordinate
                
                let start_location = ["lat":source.latitude,"lng":source.longitude]
                let end_location = ["lat":destination.latitude,"lng":destination.longitude]
                
                let stepsFinalArray = NSMutableArray()
                
                steps.enumerateObjects({ (obj, idx, stop) -> Void in
                    let step:MKRouteStep = obj as! MKRouteStep
                    let distance = step.distance.description
                    let instructions = step.instructions
                    
                    let stepsDictionary = NSMutableDictionary()
                    
                    stepsDictionary.setObject(distance, forKey: "distance" as NSCopying)
                    stepsDictionary.setObject("", forKey: "duration" as NSCopying)
                    stepsDictionary.setObject(instructions, forKey: "instructions" as NSCopying)
                    
                    stepsFinalArray.add(stepsDictionary)
                })
                
                let stepsDict = NSMutableDictionary()
                stepsDict.setObject(distance, forKey: "distance" as NSCopying)
                stepsDict.setObject(duration, forKey: "duration" as NSCopying)
                stepsDict.setObject(end_address, forKey: "end_address" as NSCopying)
                stepsDict.setObject(end_location, forKey: "end_location" as NSCopying)
                stepsDict.setObject("", forKey: "start_address" as NSCopying)
                stepsDict.setObject(start_location, forKey: "start_location" as NSCopying)
                stepsDict.setObject(stepsFinalArray, forKey: "steps" as NSCopying)
                
                self.directionsCompletionHandler!(route,route.polyline,stepsDict, route.polyline.boundingMapRect, nil)
            }
        })
    }
    
    private func decodePolyLine(encodedStr:NSString)->Array<CLLocation>{
        var array = Array<CLLocation>()
        let len = encodedStr.length
        let range = NSMakeRange(0, len)
        var strpolyline = encodedStr
        var index = 0
        var lat = 0 as Int
        var lng = 0 as Int
        
        strpolyline = encodedStr.replacingOccurrences(of: "\\\\", with: "\\", options: NSString.CompareOptions.literal, range: range) as NSString
        while(index<len){
            var b = 0
            var shift = 0
            var result = 0
            repeat {
                index = index + 1
                let numUnichar = strpolyline.character(at: index)
                let num =  NSNumber(value: numUnichar)
                let numInt = num.intValue
                b = numInt - 63
                result |= (b & 0x1f) << shift
                shift += 5
            } while(b >= 0x20)
            
            var dlat = 0
            
            if((result & 1) == 1){
                dlat = ~(result >> 1)
            }
            else{
                dlat = (result >> 1)
            }
            
            lat += dlat
            
            shift = 0
            result = 0
            
            repeat {
                index = index + 1
                let numUnichar = strpolyline.character(at: index)
                let num =  NSNumber(value: numUnichar)
                let numInt = num.intValue
                b = numInt - 63
                result |= (b & 0x1f) << shift
                shift += 5
            } while(b >= 0x20)
            
            var dlng = 0
            
            if((result & 1) == 1){
                dlng = ~(result >> 1)
            }
            else{
                dlng = (result >> 1)
            }
            lng += dlng
            
            let latitude = NSNumber(value:lat).doubleValue * 1e-5
            let longitude = NSNumber(value:lng).doubleValue * 1e-5
            let location = CLLocation(latitude: latitude, longitude: longitude)
            array.append(location)
        }
        return array
    }
    
    private func parser(data:NSDictionary)->NSDictionary{
        let distance = (data.object(forKey: "distance") as! NSDictionary).object(forKey: "text") as! NSString
        let duration = (data.object(forKey: "duration") as! NSDictionary).object(forKey: "text") as! NSString
        let end_address = data.object(forKey: "end_address") as! NSString
        let end_location = data.object(forKey: "end_location") as! NSDictionary
        let start_address = data.object(forKey: "start_address") as! NSString
        let start_location = data.object(forKey: "start_location") as! NSDictionary
        let stepsArray = data.object(forKey: "steps") as! NSArray
        let stepsDict = NSMutableDictionary()
        let stepsFinalArray = NSMutableArray()
        
        stepsArray.enumerateObjects({ (obj, idx, stop) -> Void in
            
            let stepDict = obj as! NSDictionary
            let distance = (stepDict.object(forKey: "distance") as! NSDictionary).object(forKey: "text") as! NSString
            let duration = (stepDict.object(forKey: "duration") as! NSDictionary).object(forKey: "text") as! NSString
            let html_instructions = stepDict.object(forKey: "html_instructions") as! NSString
            let end_location = stepDict.object(forKey: "end_location") as! NSDictionary
            let instructions = self.removeHTMLTags(source: (stepDict.object(forKey: "html_instructions") as! NSString))
            let start_location = stepDict.object(forKey: "start_location") as! NSDictionary
            let stepsDictionary = NSMutableDictionary()
            stepsDictionary.setObject(distance, forKey: "distance" as NSCopying)
            stepsDictionary.setObject(duration, forKey: "duration" as NSCopying)
            stepsDictionary.setObject(html_instructions, forKey: "html_instructions" as NSCopying)
            stepsDictionary.setObject(end_location, forKey: "end_location" as NSCopying)
            stepsDictionary.setObject(instructions, forKey: "instructions" as NSCopying)
            stepsDictionary.setObject(start_location, forKey: "start_location" as NSCopying)
            stepsFinalArray.add(stepsDictionary)
        })
        
        stepsDict.setObject(distance, forKey: "distance" as NSCopying)
        stepsDict.setObject(duration, forKey: "duration" as NSCopying)
        stepsDict.setObject(end_address, forKey: "end_address" as NSCopying)
        stepsDict.setObject(end_location, forKey: "end_location" as NSCopying)
        stepsDict.setObject(start_address, forKey: "start_address" as NSCopying)
        stepsDict.setObject(start_location, forKey: "start_location" as NSCopying)
        stepsDict.setObject(stepsFinalArray, forKey: "steps" as NSCopying)
        return stepsDict
    }
    
    private func removeHTMLTags(source:NSString)->NSString{
        var range = NSMakeRange(0, 0)
        let HTMLTags = "<[^>]*>"
        
        var sourceString = source
        while( sourceString.range(of: HTMLTags, options: NSString.CompareOptions.regularExpression).location != NSNotFound){
            range = sourceString.range(of: HTMLTags, options: NSString.CompareOptions.regularExpression)
            sourceString = sourceString.replacingCharacters(in: range, with: "") as NSString
        }
        return sourceString;
    }
}

