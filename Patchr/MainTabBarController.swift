//
//  MainTabBarViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-19.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    var messageBar: UILabel!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
        
    override func awakeFromNib() {
        super.awakeFromNib()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground",
            name: Event.ApplicationWillEnterForeground.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground",
            name: Event.ApplicationDidEnterBackground.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged",
            name: kReachabilityChangedNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		delegate = self
        
        /* Message bar */
        self.messageBar = UILabel(frame: CGRectMake(0, UIScreen.mainScreen().bounds.size.height - 48, UIScreen.mainScreen().bounds.size.width, 0))
        self.messageBar.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        self.messageBar.text = "Connection is offline"
        self.messageBar.numberOfLines = 0
        self.messageBar.textAlignment = NSTextAlignment.Center
        self.messageBar.textColor = UIColor.whiteColor()
        self.messageBar.layer.backgroundColor = Colors.brandColorDark.CGColor
        self.view.addSubview(self.messageBar)
    }
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		reachabilityChanged()
	}
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func applicationWillEnterForeground() {
        /* User either switched to patchr or turned their screen back on. */
        Log.d("Application will enter foreground")
    }
    
    func applicationDidEnterBackground() {
        Log.d("Application did enter background")
        LocationController.instance.startSignificantChangeUpdates()
    }
    
    func reachabilityChanged() {
        if ReachabilityManager.instance.isReachable() {
            hideMessageBar()
        }
        else {
            showMessageBar()
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func showMessageBar() {
        UIView.animateWithDuration(0.10, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.messageBar.frame = CGRectMake(0, UIScreen.mainScreen().bounds.size.height - 88, UIScreen.mainScreen().bounds.size.width, 40)
            }, completion: nil)
    }
    
    func hideMessageBar() {
        UIView.animateWithDuration(0.10, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.messageBar.frame = CGRectMake(0, UIScreen.mainScreen().bounds.size.height - 48, UIScreen.mainScreen().bounds.size.width, 0)
            }, completion: nil)
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
			else if let controller = navigationController.topViewController as? UserDetailViewController {
				controller.profileMode = true
				if UserController.instance.authenticated {
					controller.entityId = UserController.instance.currentUser.id_
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