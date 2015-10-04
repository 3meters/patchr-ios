//
//  FetchedResultsMapViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MapKit

class PatchTableMapViewController: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    // If you modify the properties of the fetchRequest, you need to follow these instructions from the Apple docs:
    //
    //    Modifying the Fetch Request
    //
    //    You cannot simply change the fetch request to modify the results. If you want to change the fetch request, you must:
    //
    //    1. If you are using a cache, delete it (using deleteCacheWithName:). Typically you should not use a cache if you are changing the fetch request.
    //    2. Change the fetch request.
    //    3. Invoke performFetch:.
    
    var fetchRequest: NSFetchRequest!
    var token: dispatch_once_t = 0
    var nearestAnnotation: MKAnnotation?
    
    internal lazy var fetchedResultsController: NSFetchedResultsController = {
        return NSFetchedResultsController(fetchRequest: self.fetchRequest, managedObjectContext: DataController.instance.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.fetchedResultsController.delegate = self;
        self.fetchedResultsController.performFetch(nil)
        self.reloadAnnotations()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("PatchMapList")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        dispatch_once(&token, { () -> Void in
            // Does some fancy map math to fit the annotations into the view.
            // Only do it on the initial view appearance
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        })
    }
        
    private func reloadAnnotations() -> Void {
        self.mapView.removeAnnotations(self.mapView.annotations)
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            var nearestDistance: Float = 1000000
            for object in fetchedObjects {
                if let queryResult = object as? QueryItem {
                    if let entity = queryResult.object as? Entity {
                        if entity.location != nil {
                            let annotation = EntityAnnotation(entity: entity)
                            self.mapView.addAnnotation(annotation)
                            
                            if let lastLocation = LocationController.instance.lastLocationFromManager() {
                                if let entityLocation = entity.location {
                                    var patchLocation = CLLocation(latitude: entityLocation.latValue, longitude: entityLocation.lngValue)
                                    let dist = Float(lastLocation.distanceFromLocation(patchLocation))  // in meters
                                    if dist < nearestDistance {
                                        nearestDistance = dist
                                        self.nearestAnnotation = annotation
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension PatchTableMapViewController: NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        let queryResult = anObject as? QueryItem
        if queryResult == nil { return }
        
        // TODO: we can do better than a full reload
        switch type {
        case .Insert:
            if let entity = queryResult!.object as? Entity {
                self.mapView.addAnnotation(EntityAnnotation(entity: entity))
            }
        case .Delete:
            self.reloadAnnotations()
        case .Update:
            self.reloadAnnotations()
        case .Move:
            self.reloadAnnotations()
        default:
            return
        }
    }
}

extension PatchTableMapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        if let currentUserLocationAnnotation = annotation as? MKUserLocation {
            return nil; // Keep default "blue dot" view for current location
        }
        
        let reuseIdentifier = "AnnotationViewIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
            if let annotation = annotation as? EntityAnnotation {
                if annotation.entity?.photo != nil {
                    var imageView = AirImageView(frame: CGRectMake(0, 0, 40, 40))
                    annotationView.leftCalloutAccessoryView = imageView
                    imageView.contentMode = UIViewContentMode.ScaleAspectFill
                }
            }
        }
        return annotationView
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        if self.nearestAnnotation == nil {
            mapView.selectAnnotation(mapView.annotations.last as! MKAnnotation, animated: true)
        }
        else {
            for annotation in mapView.annotations {
                if annotation.isEqual(self.nearestAnnotation) {
                    mapView.selectAnnotation(annotation as! MKAnnotation, animated: true)
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if let imageView = view.leftCalloutAccessoryView as? AirImageView {
            if let annotation = view.annotation as? EntityAnnotation {
                if let photo = annotation.entity?.photo {
                    imageView.setImageWithPhoto(photo, animate: true)
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if let entityAnnotation = view.annotation as? EntityAnnotation {
            if let patch = entityAnnotation.entity as? Patch {
                let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
                if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
                    controller.entity = patch
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            }
        }
    }
}

class EntityAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String
    var subtitle: String?
    var entity: Entity?
    
    init(entity: Entity) {
        self.entity = entity
        self.coordinate = entity.location.coordinate
        self.title = entity.name
        if let patch = entity as? Patch {
            self.subtitle = patch.type.uppercaseString + " PATCH"
        }
    }
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title!
        self.subtitle = subtitle
    }
}
