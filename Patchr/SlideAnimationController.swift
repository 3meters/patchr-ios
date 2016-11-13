//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation

class SlideControllerAnimation: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {

    /* UIViewControllerAnimatedTransitioning */

    fileprivate var presenting: Bool = false

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        /* get reference to our fromView, toView and the container view that we should perform the transition in. */
        let container = transitionContext.containerView
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!

        /* Set up from 2D transforms that we'll use in the animation */
        let offScreenRight = CGAffineTransform(translationX: container.frame.width, y: 0)
        let offScreenLeft = CGAffineTransform(translationX: -container.frame.width, y: 0)

        /* Start the toView to the right of the screen */
        toView.transform = self.presenting ? offScreenRight : offScreenLeft

        /* add the both views to our view controller */
        container.addSubview(toView)
        container.addSubview(fromView)

        /* Duration of the animation from the delegate */
        let duration = self.transitionDuration(using: transitionContext)

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
                    toView.transform = CGAffineTransform.identity }
                , completion: { finished in
            /* tell our transitionContext object that we've finished animating */
            transitionContext.completeTransition(true)}
                )
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
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
