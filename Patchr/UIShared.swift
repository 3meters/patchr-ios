//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//
import MBProgressHUD
import DateTools
import IDMPhotoBrowser
import ReachabilitySwift

struct UIShared {
	
	static func compatibilityUpgrade() {
		
		OperationQueue.main.addOperation {
			
			if let controller = UIViewController.topMostViewController() {
				controller.UpdateConfirmationAlert(
					title: "Update required",
					message: "Your version of Patchr is not compatible with the Patchr service. Please update to a newer version.",
					actionTitle: "Update",
					cancelTitle: "Later") {
						doIt in
						if doIt {
							Log.w("Incompatible version: Update selected")
							Reporting.track("Selected to Update Incompatible Version")
							let appStoreURL = "itms-apps://itunes.apple.com/app/id\(APPLE_APP_ID)"
							if let url = NSURL(string: appStoreURL) {
								UIApplication.shared.openURL(url as URL)
							}
						}
						else {
							Log.w("Incompatible version: Declined so signout and jump to lobby")
							Reporting.track("Declined to Update Incompatible Version")
							UserController.instance.logout()
						}
				}
			}
		}
	}
	
	static func versionIsValid(versionMin: Int) -> Bool {
		let clientVersionCode = Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)!
		return (clientVersionCode >= versionMin)
	}
	
	static func askToEnableLocationService() {
		OperationQueue.main.addOperation {
			
			if let controller = UIViewController.topMostViewController() {
				controller.LocationSettingsAlert(
					title: "Location Services is disabled",
					message: "Patchr uses your location to discover nearby patches. Please turn on Location Services in your device settings.",
					actionTitle: "Settings",
					cancelTitle: "No Thanks") {
						doIt in
						if doIt {
							Log.w("Prompt to enable location: Go to settings option selected")
							Reporting.track("Selected to View Location Settings")
							let settingsURL = UIApplicationOpenSettingsURLString
							if let url = NSURL(string: settingsURL) {
								UIApplication.shared.openURL(url as URL)
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

    @discardableResult static func showPhoto(image: UIImage!, animateFromView: UIView!, viewController: UIViewController!, message: FireMessage?) -> FirePhotoBrowser {
        /*
         * Create browser (must be done each time photo browser is displayed. Photo
         * browser objects cannot be re-used)
         */
        let photo = IDMPhoto(image: image)!
        let photos = Array([photo])
        let browser = FirePhotoBrowser(photos:photos as [AnyObject], animatedFrom: animateFromView)
        
        browser?.usePopAnimation = true
        browser?.scaleImage = image  // Used because final image might have different aspect ratio than initially
        browser?.useWhiteBackgroundColor = true
        browser?.disableVerticalSwipe = false
        
        if message != nil {
            browser?.bind(message: message)
        }
        
        viewController.navigationController!.present(browser!, animated:true, completion:nil)
        
        return browser!
    }
	
	@discardableResult static func StickyToast(message: String?, controller: UIViewController? = nil, addToWindow: Bool = true) -> AirProgress {
		
		var targetView: UIView = UIApplication.shared.windows.last!
		
		if !addToWindow {
			if controller == nil  {
				targetView = UIViewController.topMostViewController()!.view
			}
			else {
				targetView = controller!.view
			}
		}
		
		let progress = AirProgress.showAdded(to: targetView, animated: true)
		progress?.mode = MBProgressHUDMode.text
		progress?.styleAs(progressStyle: .ToastLight)
		progress?.labelText = message
		progress?.detailsLabelText = "Tap to dismiss"
		progress?.xOffset = Float((UIScreen.main.bounds.size.height / 2) - 200)
		progress?.shadow = true
		progress?.removeFromSuperViewOnHide = false
		progress?.isUserInteractionEnabled = true
		
		return progress!
	}
	
	@discardableResult static func Toast(message: String?, duration: TimeInterval = 3.0, controller: UIViewController? = nil, addToWindow: Bool = true, identifier: String? = nil) -> AirProgress {
		
        var targetView: UIView = UIApplication.shared.windows.last!
        
        if !addToWindow {
            if controller == nil  {
                targetView = UIViewController.topMostViewController()!.view
            }
            else {
                targetView = controller!.view
            }
        }
        
        var progress: AirProgress
        progress = AirProgress.showAdded(to: targetView, animated: true)
        progress.mode = MBProgressHUDMode.text
        progress.styleAs(progressStyle: .ToastLight)
        progress.labelText = message
        progress.yOffset = Float((UIScreen.main.bounds.size.height / 2) - 200)
        progress.shadow = true
        progress.removeFromSuperViewOnHide = true
        progress.isUserInteractionEnabled = false
        progress.hide(true, afterDelay: duration)
        
        return progress
    }
	
    static func hasConnectivity() -> Bool {
        let reachability: Reachability? = Reachability()
        let networkStatus: Reachability.NetworkStatus = (reachability?.currentReachabilityStatus)!
        return (networkStatus != .notReachable)
    }
	
	static func timeAgoMedium(date: NSDate) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
		if date.monthsAgo() >= 1 {
			return dateFormatter.string(from: date as Date)
		}
		else {
			return date.timeAgoSinceNow()
		}
	}
	
	static func timeAgoShort(date: NSDate) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
		if date.monthsAgo() >= 1 {
            return dateFormatter.string(from: date as Date)
		}
		else {
			return date.shortTimeAgoSinceNow()
		}
	}
}
