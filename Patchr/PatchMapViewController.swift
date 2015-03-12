//
//  PatchMapViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-11.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import MapKit

class PatchMapViewController: UIViewController,
    MKAnnotation, // lets us provide annotation information for map view
    MKMapViewDelegate

{
    @IBOutlet weak var mapView: MKMapView!
    
    var location: CLLocation?
    
    deinit {
        println("--deinit PatchMapVC")
    }
    
    override func viewWillAppear(animated: Bool) {

        mapView.delegate = self
        
        var currentRegion = MKCoordinateRegionMakeWithDistance(self.coordinate, 2000, 2000)
        mapView.setRegion(currentRegion, animated: false)
        mapView.addAnnotation(self)

    }

    // MARK: MKAnnotation
    
    lazy var coordinate: CLLocationCoordinate2D = {
        // Note: I have had this crash on me in the simulator (CLLocationManager().location returns nil), but
        // that seems like a bug because changing the location in the debug menu fixed it.
        // ...and now I saw it crash on the Phone too. So I'm going to see what happens with a default CLLocation
        return self.location?.coordinate ?? CLLocation().coordinate

    }()
    
    // MARK: MKMapViewDelegate
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
    {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.animatesDrop = true
        return annotationView
    }

}
