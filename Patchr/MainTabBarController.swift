//
//  MainTabBarViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-19.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
		delegate = self
//        let imageCache = SDImageCache.sharedImageCache()
//        imageCache.clearDisk()
//        imageCache.clearMemory()
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    
	func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        
        if let navigationController = viewController as? UINavigationController {
            if let controller = navigationController.topViewController as? PatchTableViewController {
                /*
                 * Hacky to key on the label but haven't found a better way.
                 */
                if navigationController.tabBarItem.title?.lowercaseString == "explore" {
                    controller.filter = PatchListFilter.Explore
                }
                else {
                    controller.filter  = PatchListFilter.Nearby
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