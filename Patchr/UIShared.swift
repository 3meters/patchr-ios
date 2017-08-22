//
//  UI.swift
//  Teeny
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
					message: "Your version of Teeny is not compatible with the Teeny service. Please update to a newer version.",
					actionTitle: "Update",
					cancelTitle: "Later") {
						doIt in
						if doIt {
                            Log.w("Incompatible version: Update selected")
                            Reporting.track("accept_update")
                            var appStoreURL = "itms-apps://itunes.apple.com/app/id\(Ids.appleAppId)"
                            if Config.appConfiguration == .testFlight {
                                appStoreURL = "https://beta.itunes.apple.com/v1/app/\(Ids.appleAppId)"
                            }
							if let url = NSURL(string: appStoreURL) {
								UIApplication.shared.openURL(url as URL)
							}
						}
						else {
							if UserController.instance.authenticated {
								Log.w("Incompatible version: Declined so signout and jump to lobby")
								Reporting.track("decline_update")
                                Reporting.track("logout")
								UserController.instance.logout()
							}
						}
				}
			}
		}
	}
    
    static func styleChrome(navigationBar: UINavigationBar, translucent: Bool) {
        if translucent {
            navigationBar.isTranslucent = true
            navigationBar.setBackgroundImage(UIImage(), for: .topAttached, barMetrics: .default)
            navigationBar.shadowImage = UIImage()
            navigationBar.tintColor = Colors.white
            navigationBar.barTintColor = Colors.clear
        }
        else {
            navigationBar.isTranslucent = false
            navigationBar.setBackgroundImage(nil, for: .topAttached, barMetrics: .default)
            navigationBar.shadowImage = nil
            navigationBar.tintColor = Theme.colorNavBarTint
            navigationBar.barTintColor = Theme.colorNavBarBackground
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
					message: "Teeny Social uses your location to discover nearby messages. Please turn on Location Services in your device settings.",
					actionTitle: "Settings",
					cancelTitle: "No Thanks") {
						doIt in
						if doIt {
							Log.w("Prompt to enable location: Go to settings option selected")
							let settingsURL = UIApplicationOpenSettingsURLString
							if let url = NSURL(string: settingsURL) {
								UIApplication.shared.openURL(url as URL)
							}
						}
						else {
							Log.w("Prompt to enable location: Declined")
						}
				}
			}
		}
	}

    @discardableResult static func showPhotos(photos: [String: DisplayPhoto]
        , animateFromView: UIView!
        , viewController: UIViewController!
        , initialIndex: UInt?) -> PhotoBrowser {
        
        let photosArray: [DisplayPhoto] = Array(photos.values).sorted(by: { $0.createdDateValue! > $1.createdDateValue! })
        let browser = (PhotoBrowser(photos: photosArray as [Any], animatedFrom: animateFromView))!
            
        browser.mode = .gallery
        browser.setInitialPageIndex(initialIndex ?? 0)
        browser.useWhiteBackgroundColor = true
        browser.usePopAnimation = true
        browser.scaleImage = (animateFromView as! UIImageView).image  // Used because final image might have different aspect ratio than initially
        browser.disableVerticalSwipe = false
        browser.autoHideInterface = false
        browser.delegate = viewController as! IDMPhotoBrowserDelegate!
        
        viewController.navigationController!.present(browser, animated:true, completion:nil)
        
        return browser
    }
		
	@discardableResult static func toast(message: String?, duration: TimeInterval = 3.0, controller: UIViewController? = nil, addToWindow: Bool = true, identifier: String? = nil) -> AirProgress {
		
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
        progress.styleAs(progressStyle: .toastLight)
        progress.labelText = message
        progress.yOffset = Float((UIScreen.main.bounds.size.height / 2) - 200)
        progress.shadow = true
        progress.removeFromSuperViewOnHide = true
        progress.isUserInteractionEnabled = false
        progress.hide(true, afterDelay: duration)
        
        return progress
    }
}
