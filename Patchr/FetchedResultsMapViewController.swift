//
//  FetchedResultsMapViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MapKit

class FetchedResultsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var managedObjectContext: NSManagedObjectContext!
    var dataStore: DataStore!
    
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
    
    var selectedPatch: Patch?

    
    internal lazy var fetchedResultsController: NSFetchedResultsController = {
        return NSFetchedResultsController(fetchRequest: self.fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.fetchedResultsController.delegate = self;
        self.fetchedResultsController.performFetch(nil)
        self.reloadAnnotations()
    }
    
    var token: dispatch_once_t = 0
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        dispatch_once(&token, { () -> Void in
            // Does some fancy map math to fit the annotations into the view.
            // Only do it on the initial view appearance
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        })
        
    }
    
    // TODO: consolidate the duplicated segue logic
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == nil {
            return
        }
        
        switch segue.identifier! {
        case "PatchDetailSegue":
            if let patchDetailViewController = segue.destinationViewController as? PatchDetailViewController {
                patchDetailViewController.managedObjectContext = self.managedObjectContext
                patchDetailViewController.dataStore = self.dataStore
                patchDetailViewController.patch = self.selectedPatch
                self.selectedPatch = nil
            }
        default: ()
        }
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        if let currentUserLocationAnnotation = annotation as? MKUserLocation {
            return nil; // Keep default "blue dot" view for current location
        }
        
        let reuseIdentifier = "AnnotationViewIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as UIButton
        }
        return annotationView
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if let entityAnnotation = view.annotation as? EntityAnnotation {
            if let patch = entityAnnotation.entity as? Patch {
                self.selectedPatch = patch
                self.performSegueWithIdentifier("PatchDetailSegue", sender: view)
            }
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        let queryResult = anObject as? QueryResult
        if queryResult == nil { return }
        
        // TODO: we can do better than a full reload
        switch type {
        case .Insert:
            self.mapView.addAnnotation(EntityAnnotation(entity: queryResult!.entity_))
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
    
    // MARK: Private Internal
    
    func reloadAnnotations() -> Void {
        self.mapView.removeAnnotations(self.mapView.annotations)
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            for object in fetchedObjects {
                if let queryResult = object as? QueryResult {
                    if queryResult.entity_.location != nil {
                        self.mapView.addAnnotation(EntityAnnotation(entity: queryResult.entity_))
                    }
                }
            }
        }
    }
}

class EntityAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String
    var subtitle: String?
    var entity: Entity
    
    init(entity: Entity) {
        self.entity = entity
        self.coordinate = entity.location.coordinate
        self.title = entity.name
        if let patch = entity as? Patch {
            self.subtitle = patch.category?.name
        }
    }
}
