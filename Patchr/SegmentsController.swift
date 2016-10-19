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
			
			let button = UIButton(type: .custom)
            button.frame = CGRect(x:0, y:0, width:48, height:48)
			button.addTarget(incomingViewController, action: #selector(controller.mapAction(sender:)), for: .touchUpInside)
			button.showsTouchWhenHighlighted = true
			button.setImage(UIImage(named: "imgMapLight")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate), for: .normal)
			button.imageEdgeInsets = UIEdgeInsetsMake(11, 11, 11, 11);

			let mapButton = UIBarButtonItem(customView: button)
			incomingViewController.navigationItem.rightBarButtonItem = mapButton
		}
    }
}

extension SegmentsController: UIToolbarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
}
