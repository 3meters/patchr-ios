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
    var fetchRequest: NSFetchRequest! // TODO override setter to force FRC performFetch
    
    internal lazy var fetchedResultsController: NSFetchedResultsController = {
        return NSFetchedResultsController(fetchRequest: self.fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchedResultsController.delegate = self;
        self.fetchedResultsController.performFetch(nil)
        self.reloadAnnotations()
        // Does some fancy map math to fit the annotations into the zoomed view
        self.mapView.showAnnotations(self.mapView.annotations, animated: true)
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseIdentifier = "AnnotationViewIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        }
        return annotationView
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        let queryResult = anObject as? QueryResult
        if queryResult == nil { return }
        
        // TODO we can do better than a full reload
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
    
    init(entity: Entity) {
        self.coordinate = entity.location.coordinate
        self.title = entity.name
    }
}
