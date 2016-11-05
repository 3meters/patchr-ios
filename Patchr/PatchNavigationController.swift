//
//  PatchNavigationController.swift
//  Patchr
//
//  Created by Jay Massena on 8/1/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit


class PatchNavigationController: AirNavigationController {
    
    var segmentsController	: SegmentsController!
    var segmentedControl	: UISegmentedControl!

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
				
		NotificationCenter.default.addObserver(self, selector: #selector(PatchNavigationController.userDidLogin(sender:)), name: NSNotification.Name(rawValue: Events.UserDidLogin), object: nil)
		
		let segItems = ["Nearby", "Member", "Own", "Explore"]
			
        self.segmentsController = SegmentsController(navigationController: self, viewControllers: segmentViewControllers())
        
        self.segmentedControl = UISegmentedControl(items: segItems)
        self.segmentedControl.sizeToFit()
		self.segmentedControl.addTarget(self.segmentsController, action:  #selector(self.segmentsController.indexDidChangeForSegmentedControl(segmentedControl:)), for: .valueChanged)
        self.segmentedControl.selectedSegmentIndex = 0
		self.segmentedControl.tintAdjustmentMode = .normal
        self.segmentsController.indexDidChangeForSegmentedControl(segmentedControl: self.segmentedControl)
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)		
	}

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}
	
	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/
	
	func userDidLogin(sender: NSNotification) {
		
		/* Can be called from a background thread */
		OperationQueue.main.addOperation {
			
			self.segmentedControl.insertSegment(withTitle: "Own", at: 1, animated: true)
			self.segmentedControl.insertSegment(withTitle: "Member", at: 1, animated: true)
			
			let owns = PatchTableViewController()
			let watching = PatchTableViewController()

			owns.filter = PatchListFilter.Owns
			owns.user = ZUserController.instance.currentUser
			watching.filter = PatchListFilter.Watching
			watching.user = ZUserController.instance.currentUser
			
			self.segmentsController.viewControllers.insert(owns, at: 1)
			self.segmentsController.viewControllers.insert(watching, at: 1)
		}
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
    func segmentViewControllers() -> [UIViewController] {
		
		if !ZUserController.instance.authenticated {
			
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
        owns.user = ZUserController.instance.currentUser
        watching.filter = PatchListFilter.Watching
        watching.user = ZUserController.instance.currentUser
        explore.filter = PatchListFilter.Explore
        
        let controllers = [nearby, watching, owns, explore]
        return controllers
    }
}
