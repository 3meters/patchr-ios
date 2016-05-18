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

@objc protocol ActionDelegate {
	optional func actionButtonTapped(button: AirRadialMenu) -> Bool
	optional func actionItemTapped(type: String) -> Bool
}

class MainTabBarController: UITabBarController {
    
    var messageBar		= UILabel()
	var centerButton	: AirRadialMenu!
	var _actionDelegate	: ActionDelegate?
	
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
		
		self.centerButton.anchorBottomCenterWithBottomPadding(6, width: self.centerButton.width(), height: self.centerButton.height())
		
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
	
	func actionButtonTapped(gester: UIGestureRecognizer) {
		
		if !UserController.instance.authenticated {
			UserController.instance.showGuestGuard(controller: nil, message: "Sign up for a free account to create patches and more.")
			return
		}
		
		if self._actionDelegate != nil {
			self._actionDelegate!.actionButtonTapped!(self.centerButton)
		}
		Animation.bounce(self.centerButton)
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
		let button = AirRadialMenu(attachedToView: self.view)
		button.bounds.size = CGSizeMake(56, 56)
		button.autoresizingMask = [.FlexibleRightMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleTopMargin]
		button.delegate = self
		button.centerView.gestureRecognizers?.forEach(button.centerView.removeGestureRecognizer) /* Remove default tap regcognizer */
		let tap = UITapGestureRecognizer(target: self, action: #selector(actionButtonTapped(_:)))
		button.centerView.addGestureRecognizer(tap)
		
		/* Stash popouts */
		button.addPopoutView(button.makePopupView(UIImage(named: "imgTripLight")!, color: Colors.brandColor, size: 48), withIndentifier: "trip")
		button.addPopoutView(button.makePopupView(UIImage(named: "imgLocation2Light")!, color: Colors.brandColor, size: 48), withIndentifier: "place")
		button.addPopoutView(button.makePopupView(UIImage(named: "imgEventLight")!, color: Colors.brandColor, size: 48), withIndentifier: "event")
		button.addPopoutView(button.makePopupView(UIImage(named: "imgGroupLight")!, color: Colors.brandColor, size: 48), withIndentifier: "group")
		button.startAngle = 295
		button.distanceFromCenter = 100
		button.distanceBetweenPopouts = 43
		
		self.view.addSubview(button)
		self.centerButton = button
		
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
	
	func setActionDelegate(delegate: ActionDelegate?) {
		self._actionDelegate = delegate
		if delegate == nil {
			self.centerButton.imageView.fadeOut(0.1)
		}
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

extension MainTabBarController: CKRadialMenuDelegate {
	
	func radialMenu(radialMenu: CKRadialMenu!, didSelectPopoutWithIndentifier identifier: String!) {
		if self._actionDelegate != nil {
			self._actionDelegate!.actionItemTapped!(identifier!)
		}
		self.centerButton.toggleOff()
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
		
		/* Scroll to top if staying on same tab */
		
        if (self.selectedViewController == nil || viewController == self.selectedViewController) {
			if let navigationController = viewController as? UINavigationController,
				let controller = navigationController.topViewController as? BaseTableViewController {
					controller.scrollToFirstRow()
			}
			else if let controller = viewController as? BaseTableViewController {
				controller.scrollToFirstRow()
			}
            return true;
        }
		
		/* Reset to top if leaving a list */
		
		if (self.selectedViewController != nil) {
			if let navigationController = self.selectedViewController as? UINavigationController,
				let controller = navigationController.topViewController as? BaseTableViewController {
				controller.scrollToFirstRow(false)
			}
			else if let controller = self.selectedViewController as? BaseTableViewController {
				controller.scrollToFirstRow(false)
			}
			return true;
		}
		
		/* A little animation sugar */
		
        let fromView = self.selectedViewController?.view
        let toView = viewController.view
        
        UIView.transitionFromView(fromView!, toView: toView, duration: 0.4,
            options: UIViewAnimationOptions.TransitionCrossDissolve, completion: nil);
        
        return true
	}
}