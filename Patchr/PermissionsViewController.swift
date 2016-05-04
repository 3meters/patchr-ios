//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PermissionsViewController: BaseViewController {
	
    var heading      = AirLabelTitle()
    var message      = AirLabelDisplay()
    var disclaimer   = AirLabelDisplay()
    var allowButton  = AirFeaturedButton()
    var cancelButton = AirButton()
	
    var locationNeeded        = true
    var notificationNeeded    = true
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let headingSize = self.heading.sizeThatFits(CGSizeMake(228, CGFloat.max))
		let messageSize = self.message.sizeThatFits(CGSizeMake(228, CGFloat.max))
		let disclaimerSize = self.disclaimer.sizeThatFits(CGSizeMake(228, CGFloat.max))
		
		self.heading.anchorTopCenterWithTopPadding(0, width: 228, height: headingSize.height)
		self.message.alignUnder(self.heading, matchingCenterWithTopPadding: 24, width: 228, height: messageSize.height)
		self.disclaimer.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: 228, height: disclaimerSize.height)
		self.allowButton.alignUnder(self.disclaimer, matchingCenterWithTopPadding: 24, width: 228, height: 44)
		self.cancelButton.alignUnder(self.allowButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
		
		self.contentHolder.resizeToFitSubviews()
		self.scrollView.contentSize = CGSizeMake(self.contentHolder.frame.size.width, self.contentHolder.frame.size.height + CGFloat(32))
		self.contentHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 16, height: self.contentHolder.frame.size.height)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	func allowAction(sender: AnyObject?) {
		
		if self.locationNeeded {
			LocationController.instance.requestAlwaysAuthorization()
		}
		else if self.notificationNeeded {
			NotificationController.instance.registerForRemoteNotifications()
			routeToMain()
		}
		Reporting.track("Selected Full Permissions")
	}
	
	func cancelAction(sender: AnyObject?) {
		routeToMain()
		Reporting.track("Selected Limited Permissions")
	}
	
	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/
	
	func locationWasDenied(sender: NSNotification?) {
		if self.notificationNeeded {
			NotificationController.instance.registerForRemoteNotifications()
		}
		routeToMain()
	}
	
	func locationWasAllowed(sender: NSNotification) {
		if self.notificationNeeded {
			NotificationController.instance.registerForRemoteNotifications()
		}
		routeToMain()
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		Reporting.screen("Permissions")
		self.view.accessibilityIdentifier = View.Permissions
		
		if CLLocationManager.authorizationStatus() != .NotDetermined {
			self.locationNeeded = false
		}
		else if UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
			self.notificationNeeded = false
		}
		
		self.heading.text = "Activate Patchr"
		self.heading.textAlignment = NSTextAlignment.Center
		self.heading.numberOfLines = 0
		
		self.message.text = "Patchr uses location to discover nearby patches and uses notifications for patch invitations."
		self.message.textAlignment = NSTextAlignment.Center
		self.message.numberOfLines = 0
		
		self.disclaimer.text = "Patchr never shares your location with anyone."
		self.disclaimer.textColor = Theme.colorTextSecondary
		self.disclaimer.textAlignment = NSTextAlignment.Center
		self.disclaimer.numberOfLines = 0
		
		self.allowButton.setTitle("Nearby and invitations".uppercaseString, forState: .Normal)
		self.cancelButton.setTitle("Limited".uppercaseString, forState: .Normal)
		
		self.allowButton.addTarget(self, action: #selector(PermissionsViewController.allowAction(_:)), forControlEvents: .TouchUpInside)
		self.cancelButton.addTarget(self, action: #selector(PermissionsViewController.cancelAction(_:)), forControlEvents: .TouchUpInside)
		
		self.contentHolder.addSubview(self.heading)
		self.contentHolder.addSubview(self.message)
		self.contentHolder.addSubview(self.disclaimer)
		self.contentHolder.addSubview(self.allowButton)
		self.contentHolder.addSubview(self.cancelButton)
		
		/* Navigation bar buttons */
		self.navigationItem.leftBarButtonItems = []
		self.navigationItem.hidesBackButton = true
		self.navigationItem.rightBarButtonItems = []
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PermissionsViewController.locationWasDenied(_:)), name: Events.LocationWasDenied, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PermissionsViewController.locationWasAllowed(_:)), name: Events.LocationWasAllowed, object: nil)
	}
	
	func routeToMain() {
		let controller = MainTabBarController()
		controller.selectedIndex = 0
		AppDelegate.appDelegate().window!.setRootViewController(controller, animated: true)
	}
}