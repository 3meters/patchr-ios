//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import pop

class SlideBounceAnimationController: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {

    /* UIViewControllerAnimatedTransitioning */
    
    var presenting: Bool = false
    var duration = 0.5

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        let containerView = transitionContext.containerView
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!

        if !presenting {
            toView.frame = CGRect(x: 0, y: 0, width: containerView.width(), height: containerView.height())
            toView.center = containerView.center
            toView.center.y = containerView.center.y + containerView.height()

            /* add the both views to our view controller */
            containerView.addSubview(toView)
            containerView.sendSubview(toBack: fromView)

            let spring = POPSpringAnimation(propertyNamed: kPOPLayerPositionY)
            spring?.toValue = containerView.center.y
            spring?.springBounciness = 10
            spring?.springSpeed = 8
            spring?.completionBlock = { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
            toView.layer.pop_add(spring, forKey: "positionAnimation")
        }
        else {
            fromView.frame = CGRect(x: 0, y: 0, width: containerView.width(), height: containerView.height())
            fromView.center = containerView.center
            fromView.center.y = containerView.center.y

            containerView.addSubview(toView)
            containerView.sendSubview(toBack: toView)

            let spring = POPSpringAnimation(propertyNamed: kPOPLayerPositionY)
            spring?.toValue = containerView.center.y + containerView.height()
            spring?.springBounciness = 10
            spring?.springSpeed = 8
            spring?.completionBlock = { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
            fromView.layer.pop_add(spring, forKey: "positionAnimation")
        }
    }
    
    /* UIViewControllerTransitioningDelegate */
    
    func animationController(forPresented presented: UIViewController
        , presenting: UIViewController
        , source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
}
