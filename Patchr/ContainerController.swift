//
//  ContainerController.swift
//  Patchr
//
//  Created by Jay Massena on 3/30/17.
//  Copyright © 2017 3meters. All rights reserved.
//

import Foundation

class ContainerController: UIViewController {
    
    var controller: UIViewController!
    var containerView: UIView!
    
    func setViewController(_ controller: UIViewController) {
        self.controller = controller
        self.containerView = UIView(frame: self.view.bounds)
        self.containerView.backgroundColor = UIColor.clear
        self.containerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.view.insertSubview(self.containerView, at: 0)
    }
    
    open override func viewWillLayoutSubviews() {
        setupController(controller: self.controller)
    }
    
    open func changeController(controller: UIViewController) {
        removeController(self.controller)
        self.controller = controller
        
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
}
