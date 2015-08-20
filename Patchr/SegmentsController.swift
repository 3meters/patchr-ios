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
        let viewControllers = [incomingViewController]
        self.navigationController.setViewControllers(viewControllers, animated: false)
        incomingViewController.navigationItem.titleView = segmentedControl
        
        var addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self.navigationController, action: Selector("addAction:"))
        var mapButton = UIBarButtonItem(title: "Map", style: UIBarButtonItemStyle.Plain, target: incomingViewController, action: Selector("mapAction:"))
        incomingViewController.navigationItem.leftBarButtonItem = mapButton
        incomingViewController.navigationItem.rightBarButtonItem = addButton
    }
}