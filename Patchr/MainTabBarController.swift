//
//  MainTabBarViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-19.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage
import DynamicButton

class MainTabBarController: UITabBarController {
    
    var messageBar		= UILabel()
	var centerButton	: DynamicButton!
	var actionDelegate	: ActionDelegate?
	
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
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		Log.w("Patchr received memory warning: clearing memory image cache")
		SDImageCache.sharedImageCache().clearMemory()
	}
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let heightDifference = self.centerButton!.frame.size.height - self.tabBar.frame.size.height
		if (heightDifference < 0) {
			self.centerButton!.center = self.tabBar.center;
		}
		else {
			var center = self.tabBar.center;
			center.y = (center.y - heightDifference / 2.0) - 4
			self.centerButton!.center = center;
		}
		
		self.centerButton.layer.masksToBounds = false
		self.centerButton.layer.shadowOffset = CGSizeMake(0.0, 2.0)
		self.centerButton.layer.shadowRadius = 2.0
		self.centerButton.layer.shadowOpacity = 0.3
		let path: UIBezierPath = UIBezierPath(roundedRect: self.centerButton.bounds, cornerRadius: CGFloat(self.centerButton.layer.cornerRadius))
		self.centerButton.layer.shadowPath = path.CGPath
		
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
    }
    
    func reachabilityChanged() {
        if ReachabilityManager.instance.isReachable() {
            hideMessageBar()
        }
        else {
            showMessageBar()
        }
    }
	
	func addAction(sender: AnyObject) {
		if self.actionDelegate != nil {
			self.actionDelegate!.actionPressed!()
		}
		else {
			if !UserController.instance.authenticated {
				UserController.instance.showGuestGuard(controller: nil, message: "Sign up for a free account to create patches and more.")
				return
			}
			
			let controller = PatchEditViewController()
			let navController = UINavigationController()
			controller.inputState = .Creating
			navController.viewControllers = [controller]
			self.presentViewController(navController, animated: true, completion: nil)
		}
	}
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainTabBarController.reachabilityChanged), name: kReachabilityChangedNotification, object: nil)
		
		delegate = self
		
		self.view.accessibilityIdentifier = View.Main
		
		let patches = PatchNavigationController()
		patches.tabBarItem = UITabBarItem(title: "Patches", image: UIImage(named: "tabBarPatches24"), selectedImage: nil)
		var tabBarItem = patches.tabBarItem
		tabBarItem.accessibilityIdentifier = Tab.Patches
		tabBarItem.tag = 1
		
		let notifications = UINavigationController()
		notifications.tabBarItem = UITabBarItem(title: "Notifications", image: UIImage(named: "tabBarNotifications24"), selectedImage: nil)
		tabBarItem = notifications.tabBarItem
		tabBarItem.accessibilityIdentifier = Tab.Notifications
		tabBarItem.tag = 2
		
		let notificationsController = NotificationsTableViewController()
		notifications.viewControllers = [notificationsController]
		
		let search = UINavigationController()
		search.tabBarItem = UITabBarItem(title: "Search", image: UIImage(named: "tabBarSearch24"), selectedImage: nil)
		tabBarItem = search.tabBarItem
		tabBarItem.accessibilityIdentifier = Tab.Search
		tabBarItem.tag = 3
		
		let controller = SearchViewController()
		search.viewControllers = [controller]
		
		let user = UINavigationController()
		user.tabBarItem = UITabBarItem(title: "Me", image: UIImage(named: "tabBarUser24"), selectedImage: nil)
		tabBarItem = user.tabBarItem
		tabBarItem.accessibilityIdentifier = Tab.Profile
		tabBarItem.tag = 4
		
		let userController = UserDetailViewController()
		user.viewControllers = [userController]
		
		let blank = UINavigationController()
		
		self.viewControllers = [patches, notifications, blank, search, user]
		
		/* Center button */
		let button = DynamicButton(style: DynamicButtonStylePlus.self)
		button.frame = CGRectMake(0, 0, 60, 60)
		button.contentEdgeInsets = UIEdgeInsets(top: 22, left: 22, bottom: 22, right: 22)
		button.autoresizingMask = [.FlexibleRightMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleTopMargin]
		button.layer.cornerRadius = button.bounds.width / 2
		button.backgroundColor = Colors.accentColor
		button.strokeColor = Colors.white
		self.view.addSubview(button)
		self.centerButton = button
		button.addTarget(self, action: #selector(MainTabBarController.addAction(_:)), forControlEvents: .TouchUpInside)
		
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

@objc protocol ActionDelegate {
	optional func actionPressed() -> Void
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
					UserController.instance.showGuestGuard(controller: self, message: nil)
					return false
				}
			}
			else if let _ = navigationController.topViewController as? NotificationsTableViewController {
				if !UserController.instance.authenticated {
					UserController.instance.showGuestGuard(controller: self, message: nil)
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