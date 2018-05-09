//
//  IncidentMapViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/14/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import MapKit

class IncidentMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var incident: Incident!
    var regionRadius: CLLocationDistance = 100
    var i: MKPointAnnotation!
    var mapChanged = false
    var cad = Cad()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(incident)
        
        mapView.showsTraffic = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        centerMapOnLocation()
        addOverlay()
        NotificationCenter.default.addObserver(self, selector: #selector(IncidentMapViewController.refresh), name: NSNotification.Name(rawValue: "incident"), object: nil)
    }
    
    @objc func refresh() {
        mapView.removeAnnotation(i)
        centerMapOnLocation()
    }
    
    func centerMapOnLocation() {
        let coord = CLLocationCoordinate2DMake(incident.latitude, incident.longitude)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coord, regionRadius, regionRadius)
        i = MKPointAnnotation()
        i.coordinate = coord
        i.title = "Incident: \(incident.id)"
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.addAnnotation(i)
    }
    @IBAction func changeMapType(_ sender: UIButton) {
        if mapChanged == false {
            mapChanged = true
            mapView.mapType = .hybrid
        } else {
            mapChanged = false
            mapView.mapType = .standard
        }
    }
}

extension IncidentMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        // Better to make this class property
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            //annotationView.canShowCallout = true
            
            switch incident.status {
            case "open":
                annotationView.image = UIImage(named: "out_of_service")
            case "in_progress":
                annotationView.image = UIImage(named: "other")
            case "resolved":
                annotationView.image = UIImage(named: "drop")
            case "closed":
                annotationView.image = UIImage(named: "drop")
            default:
                break
            }
        }
        
        return annotationView
    }
    
    func addOverlay() {
        let overlay = CadMapOverlay(cad: cad)
        mapView.add(overlay)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is CadMapOverlay {
            return CadMapOverlayView(overlay: overlay, overlayImage: UIImage(named: "event")!)
        }
        
        return MKOverlayRenderer()
        
    }
}
