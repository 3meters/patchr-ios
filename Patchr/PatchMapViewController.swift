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
	
    @objc optional var locationTitle: String? { get }
    @objc optional var locationSubtitle: String? { get }
    @objc optional var locationPhoto: AnyObject? { get }
	
    func locationForMap() -> CLLocation?
    func locationChangedTo(location: CLLocation) -> Void
    func locationEditable() -> Bool
}

class PatchMapViewController: UIViewController {
    
	weak var locationDelegate: MapViewDelegate!	// Set by calling controller
    var annotation: EntityAnnotation!
    
	var mapView: MKMapView!
	var messageBar = UILabel()
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
    override func viewWillDisappear(_ animated: Bool) {
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
		if self.locationDelegate.locationEditable() {			
            let messageSize = self.messageBar.sizeThatFits(CGSize(width:self.view.width(), height:CGFloat.greatestFiniteMagnitude))
			let navHeight = self.navigationController?.navigationBar.height() ?? 0
			let statusHeight = UIApplication.shared.statusBarFrame.size.height
			self.messageBar.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: (statusHeight + navHeight), height: max(messageSize.height + 16, 48))
		}
	}
    
    func longPress(gesture: UILongPressGestureRecognizer) {
        if self.locationDelegate.locationEditable() {
            if gesture.state == .began {
                let coordinate = self.mapView?.convert(gesture.location(in: mapView), toCoordinateFrom: self.mapView)
                self.mapView!.removeAnnotation(self.annotation)
                self.locationDelegate?.locationChangedTo(location: CLLocation(latitude: coordinate!.latitude, longitude: coordinate!.longitude)) // Passes to calling controller via delegate
                self.annotation.coordinate = self.locationDelegate.locationForMap()!.coordinate
                self.mapView!.addAnnotation(self.annotation)
            }
        }
    }
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		Reporting.screen("PatchMap")
		
		self.mapView = MKMapView()
		self.mapView.delegate = self
		self.mapView.showsUserLocation = true
		self.mapView.mapType = .standard
		
		let currentRegion = MKCoordinateRegionMakeWithDistance(self.locationDelegate.locationForMap()!.coordinate, 2000, 2000)
		self.mapView.setRegion(currentRegion, animated: false)
		
		self.annotation = EntityAnnotation(
			coordinate: self.locationDelegate.locationForMap()!.coordinate,
			title: self.locationDelegate.locationTitle ?? nil,
			subtitle: self.locationDelegate.locationSubtitle ?? nil)
		
		let press = UILongPressGestureRecognizer(target: self, action: #selector(PatchMapViewController.longPress(gesture:)));
		self.view.addGestureRecognizer(press)
		
		self.mapView.addAnnotation(self.annotation)
		self.view.addSubview(self.mapView)
		
		if self.locationDelegate.locationEditable() {
			
			/* Message bar */
			self.messageBar.font = Theme.fontTextDisplay
			self.messageBar.text = "Tap and hold to set the location for the patch."
			self.messageBar.numberOfLines = 0
			self.messageBar.textAlignment = NSTextAlignment.center
			self.messageBar.textColor = Colors.white
			self.messageBar.layer.backgroundColor = Colors.accentColorFill.cgColor
			self.messageBar.alpha = 0.90
			self.view.addSubview(self.messageBar)
		}
	}
}

extension PatchMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
		if annotation is MKUserLocation {
			return nil; // Keep default "blue dot" view for current location
		}
		
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.animatesDrop = true
        annotationView.canShowCallout = true
		
		let photo = self.locationDelegate.locationPhoto ?? nil
		
        if photo != nil {
            let imageView = AirImageView(frame: CGRect(x:0, y:0, width:40, height:40))
            annotationView.leftCalloutAccessoryView = imageView
            imageView.contentMode = UIViewContentMode.scaleAspectFill
        }
		else {
            let imageView = AirImageView(frame: CGRect(x:0, y:0, width:40, height:40))
			imageView.image = Utils.imagePatch
			imageView.tintColor = Theme.colorTint
			annotationView.leftCalloutAccessoryView = imageView
			imageView.contentMode = UIViewContentMode.scaleAspectFill
		}

        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        mapView.selectAnnotation(self.annotation, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let imageView = view.leftCalloutAccessoryView as? AirImageView {
            if let locationPhoto = self.locationDelegate.locationPhoto as? Photo {
                imageView.setImageWithPhoto(photo: locationPhoto, animate: true)
            }
            else if let locationPhoto = self.locationDelegate.locationPhoto as? UIImage {
                imageView.image = locationPhoto
            }
        }
    }
}
