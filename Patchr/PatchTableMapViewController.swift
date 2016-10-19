//
//  FetchedResultsMapViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MapKit


class PatchTableMapViewController: UIViewController {

	var mapView: MKMapView!
    
    /* If you modify the properties of the fetchRequest, you need to follow these instructions from
	 * the Apple docs:
     *
     *   Modifying the Fetch Request
     *
     *   You cannot simply change the fetch request to modify the results. If you want to change 
	 *   the fetch request, you must:
     *
     *   1. If you are using a cache, delete it (using deleteCacheWithName:). Typically you should 
	 *      not use a cache if you are changing the fetch request.
     *   2. Change the fetch request.
     *   3. Invoke performFetch:.
	 */
    var fetchRequest: NSFetchRequest<QueryItem>!
    var nearestAnnotation: MKAnnotation?
	var location: CLLocation?
    
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
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

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		Reporting.screen("PatchMapList")
		
		self.mapView = MKMapView()
		self.mapView.delegate = self
		self.mapView.showsUserLocation = true
		self.mapView.mapType = .standard
		
		do {
			try self.fetchedResultsController.performFetch()
		}
		catch { print("Fetch error: \(error)") }
		
		self.loadAnnotations()
		/*
		* Does some fancy map math to fit the annotations into the view.
		* Only does it on the initial view appearance.
		*/
		self.mapView.showAnnotations(self.mapView.annotations, animated: true)
		self.view.addSubview(self.mapView)
	}
	
    func loadAnnotations() -> Void {
		
        self.mapView.removeAnnotations(self.mapView!.annotations)
		self.location = LocationController.instance.mostRecentAvailableLocation()
		
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            var nearestDistance: Float = 1000000
			var annotations: [MKAnnotation] = []
			
            for object in fetchedObjects {
                if let entity = object.object as? Entity , entity.location != nil {
					
					let annotation = EntityAnnotation(entity: entity)
					annotations.append(annotation)
					
					if let lastLocation = self.location {
						if let entityLocation = entity.location {
							let patchLocation = CLLocation(latitude: entityLocation.latValue, longitude: entityLocation.lngValue)
							let dist = Float(lastLocation.distance(from: patchLocation))  // in meters
							if dist < nearestDistance {
								nearestDistance = dist
								self.nearestAnnotation = annotation
							}
						}
					}
				}
            }
			self.mapView.addAnnotations(annotations)
        }
    }
	
	/*--------------------------------------------------------------------------------------------
	* Properties
	*--------------------------------------------------------------------------------------------*/
	
	internal lazy var fetchedResultsController: NSFetchedResultsController<QueryItem> = {
		
		let controller = NSFetchedResultsController(
			fetchRequest: self.fetchRequest,
			managedObjectContext: DataController.instance.mainContext,
			sectionNameKeyPath: nil,
			cacheName: nil)
		
		controller.delegate = self
		
		return controller
	}()
}

extension PatchTableMapViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		/*
		 * Only called if the entity is changed in the model and the map
		 * is active.
		 */
        let queryResult = anObject as? QueryItem
        if queryResult == nil { return }
        
        switch type {
			case .insert:
				if let entity = queryResult!.object as? Entity {
					self.mapView.addAnnotation(EntityAnnotation(entity: entity))
				}
			case .delete:
				self.loadAnnotations()
			case .update:
				self.loadAnnotations()
			case .move:
				self.loadAnnotations()
        }
    }
}

extension PatchTableMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil; // Keep default "blue dot" view for current location
        }
        
        let reuseIdentifier = "AnnotationViewIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView!.canShowCallout = true
            annotationView!.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure)
            if let annotation = annotation as? EntityAnnotation {
                if annotation.entity?.photo != nil {
                    let imageView = AirImageView(frame: CGRect(x:0, y:0, width:40, height:40))
                    annotationView!.leftCalloutAccessoryView = imageView
                    imageView.contentMode = UIViewContentMode.scaleAspectFill
                }
				else {
					let imageView = AirImageView(frame: CGRect(x:0, y:0, width:40, height:40))
					imageView.image = Utils.imagePatch
					imageView.tintColor = Theme.colorTint
					annotationView!.leftCalloutAccessoryView = imageView
					imageView.contentMode = UIViewContentMode.scaleAspectFill
				}
            }
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if self.nearestAnnotation == nil {
            mapView.selectAnnotation(mapView.annotations.last!, animated: true)
        }
        else {
            for annotation in mapView.annotations {
                if annotation.isEqual(self.nearestAnnotation) {
                    mapView.selectAnnotation(annotation , animated: true)
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let imageView = view.leftCalloutAccessoryView as? AirImageView {
            if let annotation = view.annotation as? EntityAnnotation {
                if let photo = annotation.entity?.photo {
                    imageView.setImageWithPhoto(photo: photo, animate: true)
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let entityAnnotation = view.annotation as? EntityAnnotation {
            if let patch = entityAnnotation.entity as? Patch {
				let controller = PatchDetailViewController()
				controller.entity = patch
				controller.entityId = patch.id_
				self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
}

class EntityAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var entity: Entity?
    
    init(entity: Entity) {
        self.entity = entity
        self.coordinate = entity.location.coordinate
        self.title = entity.name
        if let patch = entity as? Patch {
            self.subtitle = patch.type.uppercased() + " PATCH"
        }
    }
    
    init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}
