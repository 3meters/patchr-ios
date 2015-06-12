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
        registerForAppNotifications()
    }
    
    /*
    * We only get these callbacks if nearby is the current view controller.
    */
    func applicationDidEnterBackground() {
        /* User either switched away from patchr or turned their screen off. */
        println("Application entered background")
    }
    
    func applicationWillEnterForeground(){
        /* User either switched to patchr or turned their screen back on. */
        println("Application will enter foreground")
        LocationController.instance.locationLocked = nil
    }
    
    func registerForAppNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground",
            name: Event.ApplicationDidEnterBackground.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground",
            name: Event.ApplicationWillEnterForeground.rawValue, object: nil)
    }
    
    func unregisterForAppNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: Event.ApplicationDidEnterBackground.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: Event.ApplicationWillEnterForeground.rawValue, object: nil)
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