//
//  ContainerController.swift
//  Teeny
//
//  Created by Jay Massena on 3/30/17.
//  Copyright © 2017 3meters. All rights reserved.
//

import ReachabilitySwift

class ContainerController: UIViewController {
    
    var controller: UIViewController!
    var containerView: UIView!
    
    var messageBar = UILabel()
    var messageBarTop = CGFloat(0)
    var actionButton: AirRadialMenu?
    var actionButtonCenter: CGPoint!
    var actionButtonAnimating = false
    var actionButtonVisible = false
    
    func setViewController(_ controller: UIViewController) {
        self.controller = controller
        self.containerView = UIView(frame: self.view.bounds)
        self.containerView.backgroundColor = UIColor.clear
        self.containerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.view.insertSubview(self.containerView, at: 0)
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    open override func viewWillLayoutSubviews() {
        setupController(controller: self.controller)
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Notifications
     *--------------------------------------------------------------------------------------------*/
    
    func viewDidBecomeActive(sender: NSNotification) {
        reachabilityChanged()
        Log.d("Container controller is active")
    }
    
    func viewWillResignActive(sender: NSNotification) {
        Log.d("Container controller will resign active")
    }
    
    func unreadChange(notification: NSNotification?) {
        /* Sent two ways:
         - when counter observer in user controller get a callback with changed count.
         - app delegate receives new message notification and app is active. */
    }
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(unreadChange(notification:)), name: NSNotification.Name(rawValue: Events.UnreadChange), object: nil)
    }

    open func changeController(controller: UIViewController) {
        removeController(self.controller)
        self.controller = controller
        self.setNeedsStatusBarAppearanceUpdate()
        
        UIView.transition(with: self.containerView
            , duration: 0.65
            , options: [.transitionCrossDissolve]
            , animations: {
                /*
                 * The animation enabling/disabling are to address a status bar issue
                 * on the destination view controller: http://stackoverflow.com/a/8505364/2247399
                 */
                let oldState = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(false)
                self.setupController(controller: controller)
                UIView.setAnimationsEnabled(oldState)
            }
            , completion: nil)

    }

    fileprivate func setupController(controller: UIViewController?) {
        if let controller = controller {
            controller.view.frame = self.containerView.bounds
            if (!self.childViewControllers.contains(controller)) {
                addChildViewController(controller)
                self.containerView.addSubview(controller.view)
                controller.didMove(toParentViewController: self)
            }
        }
    }
    
    fileprivate func removeController(_ controller: UIViewController?) {
        if let controller = controller {
            controller.view.layer.removeAllAnimations()
            controller.willMove(toParentViewController: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParentViewController()
        }
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
        self.actionButtonAnimating = false
        self.actionButtonVisible = false
        
        if self.actionButton != nil {
            self.view.insertSubview(self.actionButton!, at: self.view.subviews.count)
            self.actionButton!.bounds = CGRect(x: 0, y: 0, width: 56, height: 56)
            self.actionButton!.transform = CGAffineTransform.identity
            self.actionButton!.anchorBottomRight(withRightPadding: 16, bottomPadding: 16, width: self.actionButton!.width(), height: self.actionButton!.height())
            self.actionButtonCenter = self.actionButton!.center
            if startHidden {
                self.actionButton!.transform = CGAffineTransform(scaleX: CGFloat(0.0001), y: CGFloat(0.0001)) // Hide by scaling
                self.actionButtonAnimating = false
                self.actionButtonVisible = false
            }
            else {
                self.actionButtonVisible = true
            }
        }
    }
    
    func hideActionButton() {
        if self.actionButtonVisible && !self.actionButtonAnimating && self.actionButton != nil {
            self.actionButtonAnimating = true
            self.actionButton!.scaleOut() {
                finished in
                self.actionButtonAnimating = false
                self.actionButtonVisible = false
            }
        }
    }
    
    func showActionButton() {
        if !self.actionButtonVisible && !self.actionButtonAnimating && self.actionButton != nil {
            self.actionButtonAnimating = true
            self.actionButton!.scaleIn() {
                finished in
                self.actionButtonAnimating = false
                self.actionButtonVisible = true
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