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

	private var sectionsBeingAdded:   [Int] = []
	private var sectionsBeingRemoved: [Int] = []
	private let tableView:            UITableView

	public var onUpdate:          ((cell:UITableViewCell, object:AnyObject) -> Void)?
	public var ignoreNextUpdates: Bool = false
    public var rowAnimation: UITableViewRowAnimation = .Fade

	init(tableView: UITableView, onUpdate: ((cell:UITableViewCell, object:AnyObject) -> Void)?) {
		self.tableView = tableView
		self.onUpdate = onUpdate
	}

	public func controllerWillChangeContent(controller: NSFetchedResultsController) {
		if ignoreNextUpdates {
			return
		}

		sectionsBeingAdded = []
		sectionsBeingRemoved = []
        tableView.beginUpdates()
	}

	public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
						   atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {

		if ignoreNextUpdates {
			return
		}

		switch type {
			case .Insert:
				sectionsBeingAdded.append(sectionIndex)
				tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
			case .Delete:
				sectionsBeingRemoved.append(sectionIndex)
				self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
			default:
				return
		}
	}

	public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject,
						   atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

		if ignoreNextUpdates {
			return
		}

		switch type {
			case .Insert:
				tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: self.rowAnimation)
			case .Delete:
				tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: self.rowAnimation)
			case .Update:
				if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
					onUpdate?(cell: cell, object: anObject)
				}
			case .Move:
				// Stupid and ugly, rdar://17684030
				if !contains(sectionsBeingAdded, newIndexPath!.section) && !contains(sectionsBeingRemoved, indexPath!.section) {
					tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
					if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
						onUpdate?(cell: cell, object: anObject)
					}
				}
				else {
					tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
					tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
				}
			default:
				return
		}
	}

	public func controllerDidChangeContent(controller: NSFetchedResultsController) {
		if ignoreNextUpdates {
			ignoreNextUpdates = false
		}
		else {
            tableView.endUpdates()
		}
	}
}