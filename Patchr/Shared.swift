//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

struct Shared {

    static func showPhotoBrowser(image: UIImage!, animateFromView: UIView!, viewController: UIViewController!, entity: Entity?) -> AirPhotoBrowser {
        /*
        * Create browser (must be done each time photo browser is displayed. Photo
        * browser objects cannot be re-used)
        */
        let photo = IDMPhoto(image:image)
        let photos = Array([photo])
        let browser = AirPhotoBrowser(photos:photos as [AnyObject], animatedFromView: animateFromView)
        
        browser.usePopAnimation = true
        browser.scaleImage = image  // Used because final image might have different aspect ratio than initially
        browser.useWhiteBackgroundColor = true
        browser.forceHideStatusBar = true
        browser.disableVerticalSwipe = false
		
        if entity != nil {
            browser.linkedEntity = entity
        }
        
        viewController.navigationController!.presentViewController(browser, animated:true, completion:nil)
        
        return browser
    }
    
    static func Toast(message: String?, duration: NSTimeInterval = 3.0, controller: UIViewController? = nil, addToWindow: Bool = true) -> AirProgress {
        
        var targetView: UIView = UIApplication.sharedApplication().windows.last!
        
        if !addToWindow {
            if controller == nil  {
                targetView = UIViewController.topMostViewController()!.view
            }
            else {
                targetView = controller!.view
            }
        }
        
        var progress: AirProgress
        progress = AirProgress.showHUDAddedTo(targetView, animated: true)
        progress.mode = MBProgressHUDMode.Text
        progress.styleAs(.ToastLight)
        progress.labelText = message
        progress.yOffset = Float((UIScreen.mainScreen().bounds.size.height / 2) - 200)
        progress.shadow = true
        progress.removeFromSuperViewOnHide = true
        progress.userInteractionEnabled = false
        progress.hide(true, afterDelay: duration)
        
        return progress
    }
	
    static func hasConnectivity() -> Bool {
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: Int = reachability.currentReachabilityStatus().rawValue
        return networkStatus != 0
    }
	
	static func timeAgoMedium(date: NSDate) -> String {
		if date.monthsAgo() >= 1 {
			return date.formattedDateWithStyle(.ShortStyle)
		}
		else {
			return date.timeAgoSinceNow()
		}
	}
	
	static func timeAgoShort(date: NSDate) -> String {
		if date.monthsAgo() >= 1 {
			return date.formattedDateWithStyle(.ShortStyle)
		}
		else {
			return date.shortTimeAgoSinceNow()
		}
	}
}