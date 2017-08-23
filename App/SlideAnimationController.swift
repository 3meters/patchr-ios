//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation

class SlideAnimationController: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {

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

        /* Set up from 2D transforms that we'll use in the animation */
        let offScreenRight = CGAffineTransform(translationX: containerView.frame.width, y: 0)
        let offScreenLeft = CGAffineTransform(translationX: -containerView.frame.width, y: 0)

        /* Start the toView to the right of the screen */
        toView.transform = self.presenting ? offScreenRight : offScreenLeft

        /* add the both views to our view controller */
        containerView.addSubview(toView)
        containerView.addSubview(fromView)

        /* Animate!
         * for this example, just slid both fromView and toView to the left at the same time
         * meaning fromView is pushed off the screen and toView slides into view
         * we also use the block animation usingSpringWithDamping for a little bounce */
        UIView.animate(withDuration: duration
                , delay: 0.0
                , usingSpringWithDamping: 0.5
                , initialSpringVelocity: 0.8
                , options: UIViewAnimationOptions()
                , animations: {
                    fromView.transform = self.presenting ? offScreenLeft : offScreenRight
                    toView.transform = CGAffineTransform.identity
                }
                , completion: { finished in
                    /* tell our transitionContext object that we've finished animating */
                    transitionContext.completeTransition(true)
                })
    }

    /* UIViewControllerTransitioningDelegate */

    func animationControllerForPresentedController(presented: UIViewController
            , presentingController presenting: UIViewController
            , sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
}
