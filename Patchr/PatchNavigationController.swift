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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.segmentsController = SegmentsController(navigationController: self, viewControllers: segmentViewControllers())
        self.segmentedControl = UISegmentedControl(items: ["NEARBY","FAVORITES","EXPLORE"])
        self.segmentedControl.sizeToFit()
        self.segmentedControl.addTarget(self.segmentsController, action: Selector("indexDidChangeForSegmentedControl:"), forControlEvents: .ValueChanged)
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentsController.indexDidChangeForSegmentedControl(self.segmentedControl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func segmentViewControllers() -> [UIViewController] {
        let nearby = NearbyTableViewController()
        let favorites = PatchTableViewController()
        let explore = PatchTableViewController()
        
        favorites.filter = PatchListFilter.Favorite
        favorites.user = UserController.instance.currentUser
        explore.filter = PatchListFilter.Explore
        
        let controllers = [nearby, favorites, explore]
        return controllers
    }
    
    func addAction(sender: AnyObject?) {
        if !UserController.instance.authenticated {
            Shared.Toast("Sign in to create a new patch")
            return
        }
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("PatchEditNavController") as? UINavigationController
        self.presentViewController(controller!, animated: true, completion: nil)
    }
}
