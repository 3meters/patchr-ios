//
//  DropdownTransitionManager.swift
//  Patchr
//
//  Created by Jay Massena on 1/24/17.
//  Copyright © 2017 3meters. All rights reserved.
//

import Foundation

class PushDownAnimationController: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    /* UIViewControllerAnimatedTransitioning */
    
    var duration = 0.5
    var snapshot: UIView?
    var presenting: Bool = false
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let container = transitionContext.containerView
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        
        /* Set up the transforms for sliding */
        let offScreenAbove = CGAffineTransform(translationX: 0, y: -container.frame.height)
        let onScreenTop = CGAffineTransform(translationX: 0, y: 74)
        //let moveBack = CGAffineTransform(scaleX: CGFloat(0.85), y: CGFloat(0.85))
        
        /* add the both views to our view controller */
        if self.presenting {
            toView.transform = offScreenAbove // Start off screen above
            container.addSubview(toView)
            container.sendSubview(toBack: fromView)
        }
        else {
            container.addSubview(toView)
            container.sendSubview(toBack: toView)
        }
        
        // Perform the animation
        UIView.animate(withDuration: duration
            , delay: 0.0
            , usingSpringWithDamping: 0.9
            , initialSpringVelocity: 0.3
            , options: [.curveEaseIn]
            , animations: {
                if self.presenting {
                    toView.transform = onScreenTop
                }
                else {
                    fromView.transform = offScreenAbove
                }
            }
            , completion: { finished in
                transitionContext.completeTransition(true)
                if !self.presenting {
                    self.snapshot?.removeFromSuperview()
                }
            })
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationControllerForPresentedController(presented: UIViewController
        , presentingController presenting: UIViewController
        , sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}
