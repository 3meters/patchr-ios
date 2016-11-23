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

        let headingSize = self.heading.sizeThatFits(CGSize(width:228, height:CGFloat.greatestFiniteMagnitude))
        let messageSize = self.message.sizeThatFits(CGSize(width:228, height:CGFloat.greatestFiniteMagnitude))
        let disclaimerSize = self.disclaimer.sizeThatFits(CGSize(width:228, height:CGFloat.greatestFiniteMagnitude))

        self.heading.anchorTopCenter(withTopPadding: 0, width: 228, height: headingSize.height)
        self.message.alignUnder(self.heading, matchingCenterWithTopPadding: 24, width: 228, height: messageSize.height)
        self.disclaimer.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: 228, height: disclaimerSize.height)
        self.allowButton.alignUnder(self.disclaimer, matchingCenterWithTopPadding: 24, width: 228, height: 44)
        self.cancelButton.alignUnder(self.allowButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)

        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.contentHolder.frame.size.height)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func allowAction(sender: AnyObject?) {

//        if self.locationNeeded {
//            LocationController.instance.requestWhenInUseAuthorization()
//        }
        if self.notificationNeeded {
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
        }
        routeToMain()
    }

    func locationWasAllowed(sender: NSNotification) {
        if self.notificationNeeded {
        }
        routeToMain()
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        Reporting.screen("Permissions")

        if UIApplication.shared.isRegisteredForRemoteNotifications {
            self.notificationNeeded = false
        }

        self.heading.text = "Activate Patchr"
        self.heading.textAlignment = NSTextAlignment.center
        self.heading.numberOfLines = 0

        self.message.text = "Patchr uses location to discover nearby patches and uses notifications for patch invitations."
        self.message.textAlignment = NSTextAlignment.center
        self.message.numberOfLines = 0

        self.disclaimer.text = "Patchr never shares your location with anyone."
        self.disclaimer.textColor = Theme.colorTextSecondary
        self.disclaimer.textAlignment = NSTextAlignment.center
        self.disclaimer.numberOfLines = 0

        self.allowButton.setTitle("Nearby and invitations".uppercased(), for: .normal)
        self.cancelButton.setTitle("Limited".uppercased(), for: .normal)

        self.allowButton.addTarget(self, action: #selector(PermissionsViewController.allowAction(sender:)), for: .touchUpInside)
        self.cancelButton.addTarget(self, action: #selector(PermissionsViewController.cancelAction(sender:)), for: .touchUpInside)

        self.contentHolder.addSubview(self.heading)
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.disclaimer)
        self.contentHolder.addSubview(self.allowButton)
        self.contentHolder.addSubview(self.cancelButton)

        /* Navigation bar buttons */
        self.navigationItem.leftBarButtonItems = []
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItems = []

        NotificationCenter.default.addObserver(self, selector: #selector(PermissionsViewController.locationWasDenied(sender:)), name: NSNotification.Name(rawValue: Events.LocationWasDenied), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PermissionsViewController.locationWasAllowed(sender:)), name: NSNotification.Name(rawValue: Events.LocationWasAllowed), object: nil)
    }

    func routeToMain() {
        MainController.instance.route()
    }
}
