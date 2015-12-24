//
//  PatchMapViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-11.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import MapKit

@objc protocol MapViewDelegate: NSObjectProtocol, UIGestureRecognizerDelegate {
	
    optional var locationTitle: String? { get }
    optional var locationSubtitle: String? { get }
    optional var locationPhoto: AnyObject? { get }
    func locationForMap() -> CLLocation?
    func locationChangedTo(location: CLLocation) -> Void
    func locationEditable() -> Bool
}

class PatchMapViewController: UIViewController {
    
	weak var locationDelegate: MapViewDelegate!	// Set by calling controller
    var annotation: EntityAnnotation!
    
	var mapView: MKMapView!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.mapView.removeAnnotation(self.annotation)
    }
    
    deinit {
		self.mapView.showsUserLocation = false
		self.mapView.delegate = nil
		self.mapView.removeFromSuperview()
		self.mapView = nil
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.mapView.fillSuperview()
	}
    
    func longPress(gesture: UILongPressGestureRecognizer) {
        if self.locationDelegate.locationEditable() {
            if gesture.state == .Began {
                let coordinate = self.mapView?.convertPoint(gesture.locationInView(mapView), toCoordinateFromView: self.mapView)
                self.mapView!.removeAnnotation(self.annotation)
                self.locationDelegate?.locationChangedTo(CLLocation(latitude: coordinate!.latitude, longitude: coordinate!.longitude)) // Passes to calling controller via delegate
                self.annotation.coordinate = self.locationDelegate.locationForMap()!.coordinate
                self.mapView!.addAnnotation(self.annotation)
            }
        }
    }
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		setScreenName("PatchMap")
		
		self.mapView = MKMapView()
		self.mapView.delegate = self
		self.mapView.showsUserLocation = true
		self.mapView.mapType = .Standard
		
		let currentRegion = MKCoordinateRegionMakeWithDistance(self.locationDelegate.locationForMap()!.coordinate, 2000, 2000)
		self.mapView.setRegion(currentRegion, animated: false)
		
		self.annotation = EntityAnnotation(
			coordinate: self.locationDelegate.locationForMap()!.coordinate,
			title: self.locationDelegate.locationTitle ?? nil,
			subtitle: self.locationDelegate.locationSubtitle ?? nil)
		
		let press = UILongPressGestureRecognizer(target: self, action: "longPress:");
		self.view.addGestureRecognizer(press)
		
		self.mapView.addAnnotation(self.annotation)
		self.view.addSubview(self.mapView)
	}
}

extension PatchMapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
		if annotation.isKindOfClass(MKUserLocation) {
			return nil; // Keep default "blue dot" view for current location
		}
		
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.animatesDrop = true
        annotationView.canShowCallout = true
		
		let photo = self.locationDelegate.locationPhoto ?? nil
		
        if photo != nil {
            let imageView = AirImageView(frame: CGRectMake(0, 0, 40, 40))
            annotationView.leftCalloutAccessoryView = imageView
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
        }
		else {
			let imageView = AirImageView(frame: CGRectMake(0, 0, 40, 40))
			imageView.image = Utils.imagePatch
			imageView.tintColor = Theme.colorTint
			annotationView.leftCalloutAccessoryView = imageView
			imageView.contentMode = UIViewContentMode.ScaleAspectFill
		}

        return annotationView
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        mapView.selectAnnotation(self.annotation, animated: true)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
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