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
			self.messageBar.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 0)
		}
		else {
			self.messageBar.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: self.tabBar.height(), height: 40)
		}
	}
    
	func applicationWillEnterForeground(sender: NSNotification) {
        /* User either switched to patchr or turned their screen back on. */
		reachabilityChanged()
        Log.d("Application will enter foreground")
    }
    
    func applicationDidEnterBackground(sender: NSNotification) {
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
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged", name: kReachabilityChangedNotification, object: nil)
		
		delegate = self
		
		self.view.accessibilityIdentifier = View.Main
		
		UITabBar.appearance().tintColor = Theme.colorTabBarTint
		
		let patches = PatchNavigationController()
		patches.tabBarItem.title = "Patches"
		patches.tabBarItem.accessibilityIdentifier = Tab.Patches
		patches.tabBarItem.image = UIImage(named: "tabBarPatches24")
		patches.tabBarItem.tag = 1
		
		let notifications = UINavigationController()
		notifications.tabBarItem.title = "Notifications"
		notifications.tabBarItem.accessibilityIdentifier = Tab.Notifications
		notifications.tabBarItem.image = UIImage(named: "tabBarNotifications24")
		notifications.tabBarItem.tag = 2
		
		let notificationsController = NotificationsTableViewController()
		notifications.viewControllers = [notificationsController]
		
		let search = UINavigationController()
		search.tabBarItem.title = "Search"
		search.tabBarItem.accessibilityIdentifier = Tab.Search
		search.tabBarItem.image = UIImage(named: "tabBarSearch24")
		search.tabBarItem.tag = 3
		
		let controller = SearchViewController()
		search.viewControllers = [controller]
		
		let user = UINavigationController()
		user.tabBarItem.title = "Me"
		user.tabBarItem.accessibilityIdentifier = Tab.Profile
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
		self.messageBar.layer.backgroundColor = Colors.accentColorFill.CGColor
		self.messageBar.alpha = 0.85
		self.messageBar.bounds.size = CGSizeMake(self.tabBar.width(), 40)
		self.view.addSubview(self.messageBar)
	}
	
    func showMessageBar() {
		let y = self.tabBar.frame.origin.y - 40

        UIView.animateWithDuration(0.10,
			delay: 0,
			options: UIViewAnimationOptions.CurveEaseOut,
			animations: {
				self.messageBar.alpha = 1
				self.messageBar.frame.origin.y = y
			}) {_ in
			Animation.bounce(self.messageBar)
		}
    }
		
    func hideMessageBar() {
        UIView.animateWithDuration(0.30,
			delay: 0,
			options: UIViewAnimationOptions.CurveEaseOut,
			animations: {
				self.messageBar.alpha = 0
			}) { _ in
			self.messageBar.frame.origin.y = self.tabBar.frame.origin.y
			self.messageBar.frame.size.height = 0
		}
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