//
//  SegmentsController.swift
//  Patchr
//
//  Created by Jay Massena on 8/1/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

class SegmentsController: NSObject {
    
    var viewControllers: [UIViewController] = []
    var navigationController: UINavigationController!
    
    init(navigationController: UINavigationController!, viewControllers: [UIViewController]) {
        super.init()
        self.viewControllers = viewControllers
        self.navigationController = navigationController
    }
    
    func indexDidChangeForSegmentedControl(segmentedControl: UISegmentedControl) {
		
        let index = segmentedControl.selectedSegmentIndex
        let incomingViewController = self.viewControllers[index]
        self.navigationController.setViewControllers([incomingViewController], animated: false)
        
        incomingViewController.navigationItem.titleView = segmentedControl
		
		if let controller = incomingViewController as? PatchTableViewController {
			let mapButton = UIBarButtonItem(title: "Map", style: UIBarButtonItemStyle.Plain, target: incomingViewController, action: #selector(controller.mapAction(_:)))
			incomingViewController.navigationItem.leftBarButtonItem = mapButton
		}
		
		if let navController = self.navigationController as? PatchNavigationController {
			let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self.navigationController, action: #selector(navController.addAction(_:)))
			incomingViewController.navigationItem.rightBarButtonItem = addButton
		}
    }
}

extension SegmentsController: UIToolbarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}