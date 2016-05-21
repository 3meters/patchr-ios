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
			
			let button = UIButton(type: .Custom)
			button.frame = CGRectMake(0, 0, 48, 48)
			button.addTarget(incomingViewController, action: #selector(controller.mapAction(_:)), forControlEvents: .TouchUpInside)
			button.showsTouchWhenHighlighted = true
			button.setImage(UIImage(named: "imgMapLight")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: .Normal)
			button.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);

			let mapButton = UIBarButtonItem(customView: button)
			incomingViewController.navigationItem.rightBarButtonItem = mapButton
		}
    }
}

extension SegmentsController: UIToolbarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}