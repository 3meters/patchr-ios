//
//  PatchNavigationController.swift
//  Patchr
//
//  Created by Jay Massena on 8/1/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchNavigationController: UINavigationController {
    
    var segmentsController: SegmentsController!
    var segmentedControl: UISegmentedControl!

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.view.accessibilityIdentifier = View.Patches
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PatchNavigationController.userDidLogin(_:)), name: Events.UserDidLogin, object: nil)
		
		let segItems = UserController.instance.authenticated
			? ["Nearby", "Member", "Own", "Explore"]
			: ["Nearby", "Explore"]
			
        self.segmentsController = SegmentsController(navigationController: self, viewControllers: segmentViewControllers())
        
        self.segmentedControl = UISegmentedControl(items: segItems)
        self.segmentedControl.sizeToFit()
		self.segmentedControl.addTarget(self.segmentsController, action:  #selector(self.segmentsController.indexDidChangeForSegmentedControl(_:)), forControlEvents: .ValueChanged)
        self.segmentedControl.selectedSegmentIndex = 0
		self.segmentedControl.tintAdjustmentMode = .Normal
        self.segmentsController.indexDidChangeForSegmentedControl(self.segmentedControl)
    }
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)		
	}

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/
	
	func userDidLogin(sender: NSNotification) {
		
		/* Can be called from a background thread */
		NSOperationQueue.mainQueue().addOperationWithBlock {
			
			self.segmentedControl.insertSegmentWithTitle("Own", atIndex: 1, animated: true)
			self.segmentedControl.insertSegmentWithTitle("Member", atIndex: 1, animated: true)
			
			let owns = PatchTableViewController()
			let watching = PatchTableViewController()

			owns.filter = PatchListFilter.Owns
			owns.user = UserController.instance.currentUser
			watching.filter = PatchListFilter.Watching
			watching.user = UserController.instance.currentUser
			
			self.segmentsController.viewControllers.insert(owns, atIndex: 1)
			self.segmentsController.viewControllers.insert(watching, atIndex: 1)
		}
	}
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func segmentViewControllers() -> [UIViewController] {
		
		if !UserController.instance.authenticated {
			
			let nearby = PatchTableViewController()
			let explore = PatchTableViewController()
			
			nearby.filter = PatchListFilter.Nearby
			explore.filter = PatchListFilter.Explore
			
			let controllers = [nearby, explore]
			return controllers
		}
		
        let nearby = PatchTableViewController()
		let explore = PatchTableViewController()
        let owns = PatchTableViewController()
        let watching = PatchTableViewController()
		
        nearby.filter = PatchListFilter.Nearby
        owns.filter = PatchListFilter.Owns
        owns.user = UserController.instance.currentUser
        watching.filter = PatchListFilter.Watching
        watching.user = UserController.instance.currentUser
        explore.filter = PatchListFilter.Explore
        
        let controllers = [nearby, watching, owns, explore]
        return controllers
    }
}
