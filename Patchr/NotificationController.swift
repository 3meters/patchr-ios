//
//  NotificationManager.swift
//  Patchr
//
//  Created by Jay Massena on 5/10/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Foundation
import Parse
import AudioToolbox

class NotificationController {
    
    static let instance = NotificationController()
    
    var activityDate: Int64!
    
    private init() {
        self.activityDate = Utils.now()
    }
	
	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/
    
    func didReceiveLocalNotification(application: UIApplication, notification: UILocalNotification) {
        didReceiveRemoteNotification(application, notification: notification.userInfo!, fetchCompletionHandler: nil)
    }
    
    func didReceiveRemoteNotification(application: UIApplication, notification: [NSObject : AnyObject], fetchCompletionHandler completionHandler: ((UIBackgroundFetchResult) -> Void)? ) {
        
        Log.d("Notification received...")
		/*
		 * Notifications targeting iOS do not come with "_id" set to a unique identifier. 
		 */
        let state = application.applicationState
        if let stateString: String = state == .Background ? "background" : state == .Active ? "active" : "inactive" {
            Log.d("App state: \(stateString)")
        }
        Log.d(String(format: "%@", notification))
        
        /* Tickle the activityDate so consumers know that something has happened */
		self.activityDate = Utils.now()

        /* Special capture for nearby notifications */
        if let trigger = notification["trigger"] as? String where trigger == "nearby" {
            var nearby = notification
            let aps = nearby["aps"] as! NSDictionary
            nearby["summary"] = aps["alert"]
            nearby["sentDate"] = NSNumber(longLong: Utils.now()) // Only way to store Int64 as AnyObject
            nearby["createdDate"] = nearby["sentDate"]
            nearby["sortDate"] = nearby["sentDate"]
            nearby["type"] = "nearby"
            nearby["schema"] = "notification"
			if nearby["id"] == nil {	// Service is planning change to start including a service generated id
				nearby["id"] = "no.\(nearby["targetId"]!.substringFromIndex(2))"
			}
            nearby.removeValueForKey("aps")
            Utils.updateNearbys(nearby)
        }
        /*
         * Inactive always means that the user tapped on remote notification.
         * Active = notification received while app is active (foreground)
         */
        if state == .Inactive || state == .Active {
            let augmentedUserInfo = NSMutableDictionary(dictionary: notification)
            augmentedUserInfo["receivedInApplicationState"] = application.applicationState.rawValue // active, inactive, background
            NSNotificationCenter.defaultCenter().postNotificationName(Events.DidReceiveRemoteNotification, object: self, userInfo: augmentedUserInfo as [NSObject : AnyObject])
        }
        /*
         * Background = notification received while app is not active (background or dead)
         */
        else if state == .Background {
            /*
             * If alert/sound/badge properties are set then they will get handled 
			 * by the os as a remote notification. Muted (low priority) notifications will badge
			 * but to not include alert or sound settings that would be handled by the os.
             */
			let notificationDate = NSNumber(longLong: Utils.now()) // Only way to store Int64 as AnyObject
			NSUserDefaults.standardUserDefaults().setObject(notificationDate, forKey: PatchrUserDefaultKey("notificationDate"))
			NSUserDefaults.standardUserDefaults().synchronize()
			Log.d("App was system launched so stashed notification date")
			
			if let settings =  UIApplication.sharedApplication().currentUserNotificationSettings() {
				/*
				 * If allowed, we play a sound even if the user has disabled notifications.
				 */
				if settings.types == .None {
					let json:JSON = JSON(notification)
					
					/* Only chirp if sounds turned on in app and not muted for the related patch */
					if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("SoundForNotifications")) {
						if let priority = json["priority"].int {
							if priority == 2 {
								return
							}
						}
						AudioServicesPlaySystemSound(AudioController.chirpSound)
					}
				}
			}
        }
		
		if (completionHandler != nil) {
			completionHandler!(.NoData)
		}
    }
	
    func didRegisterForRemoteNotificationsWithDeviceToken(application: UIApplication, deviceToken: NSData) {
        let parseInstallation = PFInstallation.currentInstallation()
        parseInstallation.setDeviceTokenFromData(deviceToken)
        parseInstallation.saveInBackgroundWithBlock(nil)
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(application: UIApplication, error: NSError) {
        Log.w("failed to register for remote notifications: \(error)")
    }

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

	func guardedRegisterForRemoteNotifications(message: String?) {
		
		let message = message ?? "Would you like to alerted when messages are posted to this patch?"
		
		if let controller = UIViewController.topMostViewController() {
			
			let alert = UIAlertController(title: "Joining Patch", message: message, preferredStyle: UIAlertControllerStyle.Alert)
			let submit = UIAlertAction(title: "Notify me", style: .Default) { action in
				self.registerForRemoteNotifications()
				Reporting.track("Selected Notifications for Patch")
			}
			let cancel = UIAlertAction(title: "No thanks", style: .Cancel) { action in
				Log.d("Remote notifications declined")
				alert.dismissViewControllerAnimated(true, completion: nil)
				Reporting.track("Declined Notifications for Patch")
			}
			
			alert.addAction(cancel)
			alert.addAction(submit)
			
			controller.presentViewController(alert, animated: true, completion: nil)
		}
	}
	
    func registerForRemoteNotifications() {
		/* Only called from UserController or self */
        let application = UIApplication.sharedApplication()
		let settings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
		application.registerUserNotificationSettings(settings)	// Triggers notification permission UI to the user
		application.registerForRemoteNotifications()
		Log.d("Registered for remote notifications")
    }
}