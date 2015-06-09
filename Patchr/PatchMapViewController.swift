//
//  PatchMapViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-11.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import MapKit


class PatchMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    // Configured by presenting view
    weak var locationProvider: PatchEditViewController?
    
    var location: CLLocation? {
        get { return locationProvider!.location }
        set { locationProvider!.updateLocation(newValue!) }
    }
    
    deinit {
        println("-- deinit PatchMapVC")
    }
    
    override func viewWillAppear(animated: Bool) {
        mapView.delegate = self
        mapView.showsUserLocation = true
        var currentRegion = MKCoordinateRegionMakeWithDistance(self.coordinate, 2000, 2000)
        mapView.setRegion(currentRegion, animated: false)
        mapView.addAnnotation(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        mapView.removeAnnotation(self)
    }
    
    @IBAction func longPress(gr: UILongPressGestureRecognizer) {
    
        if gr.state == .Began {
            let coordinate = mapView.convertPoint(gr.locationInView(mapView), toCoordinateFromView: mapView)
            mapView.removeAnnotation(self)
            self.location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude) // Passes to calling controller via delegate
            mapView.addAnnotation(self)
        }
    }
}

extension PatchMapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        if let currentUserLocationAnnotation = annotation as? MKUserLocation {
            return nil; // Keep default "blue dot" view for current location
        }
        
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.animatesDrop = true
        return annotationView
    }
}

extension PatchMapViewController: MKAnnotation {
    /*
     * Lets us provide annotation information for map view
     */
    var coordinate: CLLocationCoordinate2D {
        get { return self.location?.coordinate ?? CLLocation().coordinate }
    }
}
