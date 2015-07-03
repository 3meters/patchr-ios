//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

struct Shared {

    static func showPhotoBrowser(image: UIImage!, view: UIView!, viewController: UIViewController!) -> AirPhotoBrowser {
        /*
        * Create browser (must be done each time photo browser is displayed. Photo
        * browser objects cannot be re-used)
        */
        var photo = IDMPhoto(image:image)
        var photos = Array([photo])
        var browser = AirPhotoBrowser(photos:photos as [AnyObject], animatedFromView: view)
        
        browser.usePopAnimation = true
        browser.scaleImage = image  // Used because final image might have different aspect ratio than initially
        browser.useWhiteBackgroundColor = true
        browser.disableVerticalSwipe = false
        browser.forceHideStatusBar = false
        browser.displayDoneButton = false
        browser.addNavigationBar()
        
        viewController.presentViewController(browser, animated:true, completion:nil)
        return browser
    }

    static func setTabBarVisible(visible:Bool, animated:Bool, viewController: UIViewController!) {
        
        //* This cannot be called before viewDidLayoutSubviews(), because the frame is not set before this time
        
        // bail if the current state matches the desired state
        if (tabBarIsVisible(viewController) == visible) { return }
        
        // get a frame calculation ready
        let frame = viewController.tabBarController?.tabBar.frame
        let height = frame?.size.height
        let offsetY = (visible ? -height! : height)
        
        // zero duration means no animation
        let duration:NSTimeInterval = (animated ? 0.3 : 0.0)
        
        //  animate the tabBar
        if frame != nil {
            UIView.animateWithDuration(duration) {
                viewController.tabBarController?.tabBar.frame = CGRectOffset(frame!, 0, offsetY!)
                return
            }
        }
    }
    
    static func tabBarIsVisible(viewController: UIViewController) ->Bool {
        return viewController.tabBarController?.tabBar.frame.origin.y < CGRectGetMaxY(viewController.view.frame)
    }    
}