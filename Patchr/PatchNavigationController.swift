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
        
        let segItems = ["Nearby","Faves","Watch","Explore"]
        
        self.segmentsController = SegmentsController(navigationController: self, viewControllers: segmentViewControllers())
        
        self.segmentedControl = UISegmentedControl(items: segItems)
        self.segmentedControl.sizeToFit()
        self.segmentedControl.addTarget(self.segmentsController, action: Selector("indexDidChangeForSegmentedControl:"), forControlEvents: .ValueChanged)
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentsController.indexDidChangeForSegmentedControl(self.segmentedControl)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func addAction(sender: AnyObject?) {
        if !UserController.instance.authenticated {
            Shared.Toast("Sign in to create a new patch")
            return
        }
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("PatchEditNavController") as? UINavigationController
        self.presentViewController(controller!, animated: true, completion: nil)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func segmentViewControllers() -> [UIViewController] {
        let nearby = PatchTableViewController()
        let favorites = PatchTableViewController()
        let watching = PatchTableViewController()
        let explore = PatchTableViewController()
        
        nearby.filter = PatchListFilter.Nearby
        favorites.filter = PatchListFilter.Favorite
        favorites.user = UserController.instance.currentUser
        watching.filter = PatchListFilter.Watching
        watching.user = UserController.instance.currentUser
        explore.filter = PatchListFilter.Explore
        
        let controllers = [nearby, favorites, watching, explore]
        return controllers
    }
}
