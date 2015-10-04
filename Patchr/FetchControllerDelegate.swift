//
//  FetchControllerDelegate.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-22.
//  Copyright (c) 2015 3meters. All rights reserved.
//
//  Taken from http://www.iosnomad.com/blog/2014/8/6/swift-nsfetchedresultscontroller-trickery

import CoreData
import UIKit

public class FetchControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {

	private var sectionsBeingAdded: [Int] = []
	private var sectionsBeingRemoved: [Int] = []
	private let tableView: UITableView

	public var onUpdate: ((cell: UITableViewCell, object: AnyObject) -> Void)?
	public var ignoreNextUpdates: Bool = false
    public var rowAnimation: UITableViewRowAnimation = .Fade

	init(tableView: UITableView, onUpdate: ((cell: UITableViewCell, object: AnyObject) -> Void)?) {
		self.tableView = tableView
		self.onUpdate = onUpdate
	}

	public func controllerWillChangeContent(controller: NSFetchedResultsController) {
		if !self.ignoreNextUpdates {
            self.sectionsBeingAdded = []
            self.sectionsBeingRemoved = []
            self.tableView.beginUpdates()
		}
	}
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if self.ignoreNextUpdates {
            self.ignoreNextUpdates = false
        }
        else {
            self.tableView.endUpdates()
        }
    }
    
    /* 
     * DidChangeSection
     */
	public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
		if !self.ignoreNextUpdates {
            switch type {
                case .Insert:
                    self.sectionsBeingAdded.append(sectionIndex)
                    self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                    
                case .Delete:
                    self.sectionsBeingRemoved.append(sectionIndex)
                    self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                    
                default:
                    return
            }
		}
	}

    /*
     * DidChangeObject
     */
	public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

		if !self.ignoreNextUpdates {
            switch type {
                case .Insert:
                    self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: self.rowAnimation)
                    
                case .Delete:
                    self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: self.rowAnimation)
                    
                case .Update:
                    if let cell = self.tableView.cellForRowAtIndexPath(indexPath!) {
                        self.onUpdate?(cell: cell, object: anObject)
                    }
                    
                case .Move:
                    // Stupid and ugly, rdar://17684030
                    if !contains(sectionsBeingAdded, newIndexPath!.section) && !contains(sectionsBeingRemoved, indexPath!.section) {
                        self.tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                        if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
                            self.onUpdate?(cell: cell, object: anObject)
                        }
                    }
                    else {
                        self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                        self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
                    }
                    
                default:
                    return
            }
		}
	}
}