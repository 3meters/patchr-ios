//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//
import MBProgressHUD
import DateTools
import AirPhotoBrowser

struct UIShared {
	
	static func compatibilityUpgrade() {
		
		NSOperationQueue.mainQueue().addOperationWithBlock {
			
			if let controller = UIViewController.topMostViewController() {
				controller.UpdateConfirmationAlert(
					"Update required",
					message: "Your version of Patchr is not compatible with the Patchr service. Please update to a newer version.",
					actionTitle: "Update",
					cancelTitle: "Later") {
						doIt in
						if doIt {
							Log.w("Incompatible version: Update selected")
							Reporting.track("Selected to Update Incompatible Version")
							let appStoreURL = "itms-apps://itunes.apple.com/app/id\(APPLE_APP_ID)"
							if let url = NSURL(string: appStoreURL) {
								UIApplication.sharedApplication().openURL(url)
							}
						}
						else {
							Log.w("Incompatible version: Declined so signout and jump to lobby")
							Reporting.track("Declined to Update Incompatible Version")
							UserController.instance.signout()
						}
				}
			}
		}
	}
	
	static func versionIsValid(versionMin: Int) -> Bool {
		let clientVersionCode = Int(NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String)!
		DataController.proxibase.versionIsValid = (clientVersionCode >= versionMin)	// Sticks until the app is terminated
		return (clientVersionCode >= versionMin)
	}
	
	static func askToEnableLocationService() {
		NSOperationQueue.mainQueue().addOperationWithBlock {
			
			if let controller = UIViewController.topMostViewController() {
				controller.LocationSettingsAlert(
					"Location Services is disabled",
					message: "Patchr uses your location to discover nearby patches. Please turn on Location Services in your device settings.",
					actionTitle: "Settings",
					cancelTitle: "No Thanks") {
						doIt in
						if doIt {
							Log.w("Prompt to enable location: Go to settings option selected")
							Reporting.track("Selected to View Location Settings")
							let settingsURL = UIApplicationOpenSettingsURLString
							if let url = NSURL(string: settingsURL) {
								UIApplication.sharedApplication().openURL(url)
							}
						}
						else {
							Log.w("Prompt to enable location: Declined")
							Reporting.track("Declined to View Location Settings")
						}
				}
			}
		}
	}

    static func showPhotoBrowser(image: UIImage!, animateFromView: UIView!, viewController: UIViewController!, entity: Entity?) -> PhotoBrowser {
        /*
        * Create browser (must be done each time photo browser is displayed. Photo
        * browser objects cannot be re-used)
        */
        let photo = IDMPhoto(image:image)
        let photos = Array([photo])
        let browser = PhotoBrowser(photos:photos as [AnyObject], animatedFromView: animateFromView)
        
        browser.usePopAnimation = true
        browser.scaleImage = image  // Used because final image might have different aspect ratio than initially
        browser.useWhiteBackgroundColor = true
        browser.disableVerticalSwipe = false
		
        if entity != nil {
            browser.bindEntity(entity)
        }
        
        viewController.navigationController!.presentViewController(browser, animated:true, completion:nil)
        
        return browser
    }
	
	static func StickyToast(message: String?, controller: UIViewController? = nil, addToWindow: Bool = true) -> AirProgress {
		
		var targetView: UIView = UIApplication.sharedApplication().windows.last!
		
		if !addToWindow {
			if controller == nil  {
				targetView = UIViewController.topMostViewController()!.view
			}
			else {
				targetView = controller!.view
			}
		}
		
		let progress = AirProgress.showHUDAddedTo(targetView, animated: true)
		progress.mode = MBProgressHUDMode.Text
		progress.styleAs(.ToastLight)
		progress.labelText = message
		progress.accessibilityIdentifier = "toast"
		progress.detailsLabelText = "Tap to dismiss"
		progress.yOffset = Float((UIScreen.mainScreen().bounds.size.height / 2) - 200)
		progress.shadow = true
		progress.removeFromSuperViewOnHide = false
		progress.userInteractionEnabled = true
		
		return progress
	}
	
	static func Toast(message: String?, duration: NSTimeInterval = 3.0, controller: UIViewController? = nil, addToWindow: Bool = true, identifier: String? = nil) -> AirProgress {
		
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
		progress.accessibilityIdentifier = identifier ?? "toast"
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