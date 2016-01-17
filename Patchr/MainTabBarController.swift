//
//  MainTabBarViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-19.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    var messageBar = UILabel()
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
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
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		if ReachabilityManager.instance.isReachable() {
			self.messageBar.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 48, height: 0)
		}
		else {
			self.messageBar.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 88, height: 40)
		}
	}
    
    func applicationWillEnterForeground() {
        /* User either switched to patchr or turned their screen back on. */
        Log.d("Application will enter foreground")
    }
    
    func applicationDidEnterBackground() {
        Log.d("Application did enter background")
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
	
	func initialize() {
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground",
			name: Event.ApplicationWillEnterForeground.rawValue, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground",
			name: Event.ApplicationDidEnterBackground.rawValue, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged",
			name: kReachabilityChangedNotification, object: nil)
		
		delegate = self
		
		UITabBar.appearance().tintColor = Theme.colorTabBarTint
		
		let patches = PatchNavigationController()
		patches.tabBarItem.title = "Patches"
		patches.tabBarItem.accessibilityIdentifier = "patches_tab"
		patches.tabBarItem.image = UIImage(named: "tabBarPatches24")
		patches.tabBarItem.tag = 1
		
		let patchTableViewController = PatchTableViewController()
		patches.viewControllers = [patchTableViewController]
		
		let notifications = UINavigationController()
		notifications.tabBarItem.title = "Notifications"
		notifications.tabBarItem.accessibilityIdentifier = "notifications_tab"
		notifications.tabBarItem.image = UIImage(named: "tabBarNotifications24")
		notifications.tabBarItem.tag = 2
		
		let notificationsController = NotificationsTableViewController()
		notifications.viewControllers = [notificationsController]
		
		let search = UINavigationController()
		search.tabBarItem.title = "Search"
		search.tabBarItem.accessibilityIdentifier = "search_tab"
		search.tabBarItem.image = UIImage(named: "tabBarSearch24")
		search.tabBarItem.tag = 3
		
		let controller = SearchViewController()
		search.viewControllers = [controller]
		
		let user = UINavigationController()
		user.tabBarItem.title = "Me"
		user.tabBarItem.accessibilityIdentifier = "profile_tab"
		user.tabBarItem.image = UIImage(named: "tabBarUser24")
		user.tabBarItem.tag = 4
		
		let userController = UserDetailViewController()
		user.viewControllers = [userController]
		
		self.viewControllers = [patches, notifications, search, user]
		
		/* Message bar */
		self.messageBar.font = Theme.fontTextDisplay
		self.messageBar.text = "Connection is offline"
		self.messageBar.numberOfLines = 0
		self.messageBar.textAlignment = NSTextAlignment.Center
		self.messageBar.textColor = Colors.white
		self.messageBar.layer.backgroundColor = Theme.colorTint.CGColor
		self.messageBar.alpha = 0.85
		self.view.addSubview(self.messageBar)
	}
	
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
			if let controller = navigationController.topViewController as? UserDetailViewController {
				if UserController.instance.authenticated {
					controller.profileMode = true
					controller.entityId = UserController.instance.userId
				}
				else {
					UserController.instance.showGuestGuard(self, message: nil)
					return false
				}
			}
			else if let _ = navigationController.topViewController as? NotificationsTableViewController {
				if !UserController.instance.authenticated {
					UserController.instance.showGuestGuard(self, message: nil)
					return false
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