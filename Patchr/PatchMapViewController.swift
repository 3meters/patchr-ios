//
//  PatchMapViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-11.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import MapKit

@objc protocol MapViewDelegate: NSObjectProtocol {
    optional var locationTitle: String? { get }
    optional var locationSubtitle: String? { get }
    optional var locationPhoto: AnyObject? { get }
    func locationForMap() -> CLLocation?
    func locationChangedTo(location: CLLocation) -> Void
    func locationEditable() -> Bool
}

class PatchMapViewController: UIViewController {
    
    weak var locationDelegate: MapViewDelegate!
    var annotation: EntityAnnotation!
    
    @IBOutlet weak var mapView: MKMapView!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        var currentRegion = MKCoordinateRegionMakeWithDistance(self.locationDelegate.locationForMap()!.coordinate, 2000, 2000)
        mapView.setRegion(currentRegion, animated: false)
        
        self.annotation = EntityAnnotation(
            coordinate: self.locationDelegate.locationForMap()!.coordinate,
            title: self.locationDelegate.locationTitle!,
            subtitle: self.locationDelegate.locationSubtitle ?? "PATCH")
        
        mapView.addAnnotation(self.annotation)
        setScreenName("PatchMap")        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mapView.removeAnnotation(self.annotation)
    }
    
    deinit {
        Log.d("-- deinit PatchMapVC")
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    @IBAction func longPress(gr: UILongPressGestureRecognizer) {
        if self.locationDelegate.locationEditable() {
            if gr.state == .Began {
                let coordinate = mapView.convertPoint(gr.locationInView(mapView), toCoordinateFromView: mapView)
                mapView.removeAnnotation(self.annotation)
                self.locationDelegate?.locationChangedTo(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) // Passes to calling controller via delegate
                self.annotation.coordinate = self.locationDelegate.locationForMap()!.coordinate
                mapView.addAnnotation(self.annotation)
            }
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
        annotationView.canShowCallout = true
        if self.locationDelegate.locationPhoto != nil {
            var imageView = AirImageView(frame: CGRectMake(0, 0, 40, 40))
            annotationView.leftCalloutAccessoryView = imageView
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
        }

        return annotationView
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        mapView.selectAnnotation(self.annotation, animated: true)
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if let imageView = view.leftCalloutAccessoryView as? AirImageView {
            if let locationPhoto = self.locationDelegate.locationPhoto as? Photo {
                imageView.setImageWithPhoto(locationPhoto, animate: true)
            }
            else if let locationPhoto = self.locationDelegate.locationPhoto as? UIImage {
                imageView.image = locationPhoto
            }
        }
    }
}