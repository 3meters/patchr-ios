//
//  TabBarController.swift
//  Patchr
//
//  Created by Jay Massena on 7/20/17.
//  Copyright © 2017 3meters. All rights reserved.
//

import UIKit
import Firebase
import ReachabilitySwift
import SDWebImage

class TabBarController: UITabBarController {
    
    var messageBar = UILabel()
    var messageBarTop = CGFloat(0)
    var actionButton: AirRadialMenu?
    var actionButtonCenter: CGPoint!
    var actionButtonAnimating = false
    var actionButtonLocked = false
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func loadView() {
        super.loadView()
        initialize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reachabilityChanged()
        if let link = MainController.instance.link {
            MainController.instance.link = nil
            MainController.instance.routeDeepLink(link: link, error: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        Log.w("Patchr received memory warning: clearing memory image cache")
        SDImageCache.shared().clearMemory()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.actionButton?.center = self.actionButtonCenter
        if self.messageBar.alpha > 0.0 {
            self.messageBar.alignUnder(self.navigationController?.navigationBar, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 40)
        }
    }
    
    deinit {
        Log.v("TabBarController released")
        NotificationCenter.default.removeObserver(self)
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Notifications
     *--------------------------------------------------------------------------------------------*/
    
    func viewDidBecomeActive(sender: NSNotification) {
        reachabilityChanged()
        Log.d("Tab controller is active")
    }
    
    func viewWillResignActive(sender: NSNotification) {
        Log.d("Tab controller will resign active")
    }
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        delegate = self
        
        let layout = UICollectionViewFlowLayout()
        let controller = ChannelGridController(collectionViewLayout: layout)
        let channels = AirNavigationController(rootViewController: controller)
        let user = AirNavigationController(rootViewController: MemberViewController(userId: UserController.instance.userId!))
        
        channels.tabBarItem = UITabBarItem(title: "Channels", image: #imageLiteral(resourceName: "tabBarChannels24"), tag: 1)
        user.tabBarItem = UITabBarItem(title: "Me", image: #imageLiteral(resourceName: "tabBarUser24"), tag: 2)
        
        self.viewControllers = [channels, user]
        
        /* Message bar */
        self.messageBar.font = Theme.fontTextDisplay
        self.messageBar.text = "Connection is offline"
        self.messageBar.numberOfLines = 0
        self.messageBar.textAlignment = NSTextAlignment.center
        self.messageBar.textColor = Colors.white
        self.messageBar.layer.backgroundColor = Colors.accentColorFill.cgColor
        self.messageBar.alpha = 0.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: ReachabilityChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewWillResignActive(sender:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidBecomeActive(sender:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func reachabilityChanged() {
        if ReachabilityManager.instance.isReachable() {
            Reporting.track("network_available")
            hideMessageBar()
        }
        else {
            Reporting.track("network_unavailable")
            showMessageBar()
        }
    }
    
    func setActionButton(button: AirRadialMenu?, startHidden: Bool = true) {
        
        self.actionButton?.removeFromSuperview()
        
        self.actionButton = button
        
        if self.actionButton != nil {
            self.view.insertSubview(self.actionButton!, at: self.view.subviews.count)
            self.actionButton!.bounds = CGRect(x: 0, y: 0, width: 56, height: 56)
            self.actionButton!.transform = CGAffineTransform.identity
            self.actionButton!.anchorBottomRight(withRightPadding: 16, bottomPadding: self.tabBar.bounds.size.height + 16, width: self.actionButton!.width(), height: self.actionButton!.height())
            self.actionButtonCenter = self.actionButton!.center
            if startHidden {
                self.actionButton!.transform = CGAffineTransform(scaleX: CGFloat(0.0001), y: CGFloat(0.0001)) // Hide by scaling
                self.actionButtonAnimating = false
            }
        }
    }
    
    func hideActionButton() {
        if !self.actionButtonLocked && !self.actionButtonAnimating && self.actionButton != nil {
            self.actionButtonAnimating = true
            self.actionButton!.scaleOut() {
                finished in
                self.actionButtonAnimating = false
            }
        }
    }
    
    func showActionButton() {
        if !self.actionButtonLocked && !self.actionButtonAnimating && self.actionButton != nil {
            self.actionButtonAnimating = true
            self.actionButton!.scaleIn() {
                finished in
                self.actionButtonAnimating = false
            }
        }
    }
    
    func showMessageBar() {
        if self.messageBar.alpha == 0 && self.messageBar.superview == nil {
            Log.d("Showing message bar")
            self.view.insertSubview(self.messageBar, at: self.view.subviews.count)
            self.messageBar.alignUnder(self.navigationController?.navigationBar, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 40)
            self.messageBarTop = self.messageBar.frame.origin.y
            UIView.animate(
                withDuration: 0.20,
                delay: 0,
                options: UIViewAnimationOptions.curveEaseOut,
                animations: {
                    self.messageBar.alpha = 1
            })
        }
    }
    
    func hideMessageBar() {
        if self.messageBar.alpha == 1 && self.messageBar.superview != nil {
            Log.d("Hiding message bar")
            UIView.animate(
                withDuration: 0.30,
                delay: 0,
                options: UIViewAnimationOptions.curveEaseOut,
                animations: {
                    self.messageBar.alpha = 0
            }) { _ in
                self.messageBar.removeFromSuperview()
            }
        }
    }
}

extension TabBarController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        /* Pop to channels grid if staying on channels tab */
        
        if (self.selectedViewController == nil || viewController == self.selectedViewController) {
            if let navigationController = viewController as? UINavigationController,
                let _ = navigationController.topViewController as? ChannelViewController {
                navigationController.popViewController(animated: true)
                return false
            }
        }
        
        /* Scroll to top if on channels grid */
        
        if (self.selectedViewController != nil && viewController == self.selectedViewController) {
            if let navigationController = self.selectedViewController as? UINavigationController,
                let controller = navigationController.topViewController as? ChannelGridController {
                controller.scrollToFirstRow(animated: false)
                return false
            }
        }
        
        /* A little animation sugar */
        
        let fromView = self.selectedViewController?.view
        let toView = viewController.view
        
        UIView.transition(
            from: fromView!,
            to: toView!,
            duration: 0.4,
            options: .transitionCrossDissolve,
            completion: nil);
        
        return true
    }
}
