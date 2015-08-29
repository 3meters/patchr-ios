//
//  MainTabBarViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-19.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground",
            name: Event.ApplicationWillEnterForeground.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground",
            name: Event.ApplicationDidEnterBackground.rawValue, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		delegate = self        
    }
    
    func applicationWillEnterForeground() {
        /* User either switched to patchr or turned their screen back on. */
        Log.d("Application will enter foreground")
    }
    
    func applicationDidEnterBackground() {
        Log.d("Application did enter background")
        LocationController.instance.startSignificantChangeUpdates()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
        
	func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        
        if let navigationController = viewController as? UINavigationController {
            if let controller = navigationController.topViewController as? PatchTableViewController {
                /*
                 * Super hackish to key on the label but haven't found a better way.
                 */
                if navigationController.tabBarItem.title?.lowercaseString == "explore" {
                    controller.filter = PatchListFilter.Explore
                }
            }
        }
                
        /* A little animation sugar */
        
        if (self.selectedViewController == nil || viewController == self.selectedViewController) {
            return true;
        }
        
        let fromView = self.selectedViewController?.view
        let toView = viewController.view
        
        UIView.transitionFromView(fromView!, toView: toView, duration: 0.4,
            options: UIViewAnimationOptions.TransitionCrossDissolve, completion: nil);
        
        return true
	}
}