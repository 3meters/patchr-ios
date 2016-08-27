//
//  NotificationManager.swift
//  Patchr
//
//  Created by Jay Massena on 5/10/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Foundation
import AudioToolbox
import RxSwift

class NotificationController: NSObject {

    static let instance = NotificationController()
    
    var installId: String?
    var activityDate: Int64!
    
    private var _badgeNumber = Variable(0)
    var badgeNumber: Observable<Int> {
        return _badgeNumber.asObservable()
    }

    private override init() {
        self.activityDate = Utils.now()
    }

    func initWithLaunchOptions(launchOptions: [NSObject:AnyObject]!) {
        
        /* We delay asking for notification permissions until they join a patch */
        OneSignal.initWithLaunchOptions(
                launchOptions,
                appId: "f43fe789-3392-4f2b-bf52-950d0c78fffe",
                handleNotificationAction: nil,
                settings: [kOSSettingsKeyAutoPrompt: false, kOSSettingsKeyInAppAlerts: false])
        
        #if DEBUG
            OneSignal.setLogLevel(.LL_DEBUG, visualLevel: .LL_NONE)
        #endif
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    func didReceiveLocalNotification(application: UIApplication, notification: UILocalNotification) {
        didReceiveRemoteNotification(application, notification: notification.userInfo!, fetchCompletionHandler: nil)
    }

    func didReceiveRemoteNotification(application: UIApplication, notification: [NSObject:AnyObject], fetchCompletionHandler completionHandler: ((UIBackgroundFetchResult) -> Void)?) {
        /*
         * The remote notification has already been displayed to the user and now we
         * have a chance to do any processing that should accompany the notification. Even
         * if the user has turned off remote notifications, we still get this call.
         */
        Log.d("Notification received...")
        Log.d("App state: \(application.applicationState == .Background ? "background" : application.applicationState == .Active ? "active" : "inactive")")

        let json: JSON = JSON(notification)
        let data = json["custom"]["a"].dictionaryObject!
        /*
         * Inactive:    Always means that the user tapped on remote notification.
         * Active:      Notification received while app is active (foreground).
         * Background:  Notification received while app is not active (background or dead)
         */
        if application.applicationState == .Inactive {
            deepLink(data["targetId"] as! String)
        }
        else {
            self._badgeNumber.value += 1
            self.activityDate = Utils.now() // So we check if our notification list is stale
            if application.applicationState == .Active {
                NSNotificationCenter.defaultCenter().postNotificationName(Events.DidReceiveRemoteNotification, object: self, userInfo: data as [NSObject:AnyObject])
            }
        }
        /* 
         * We have thirty seconds to process and call the completion handler before being
         * terminated if the app was woken to process the notification.
         */
        if (completionHandler != nil) {
            completionHandler!(.NoData)
        }
    }

    func didRegisterForRemoteNotificationsWithDeviceToken(application: UIApplication, deviceToken: NSData) {
        Log.d("Success registering for remote notifications")
    }

    func didFailToRegisterForRemoteNotificationsWithError(application: UIApplication, error: NSError) {
        Log.w("Failed to register for remote notifications: \(error)")
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func deepLink(targetId: String) {
        
        let topController = UIViewController.topMostViewController()
        
        if targetId.hasPrefix("pa.") {
            let controller = PatchDetailViewController()
            let navController = AirNavigationController()
            navController.viewControllers = [controller]
            controller.entityId = targetId
            let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: controller, action: #selector(controller.dismissAction(_:)))
            controller.navigationItem.leftBarButtonItems = [doneButton]
            topController!.presentViewController(navController, animated: true, completion: nil)
        }
        else if targetId.hasPrefix("me.") {
            let controller = MessageDetailViewController()
            let navController = AirNavigationController()
            navController.viewControllers = [controller]
            controller.inputMessageId = targetId
            let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: controller, action: #selector(controller.dismissAction(_:)))
            controller.navigationItem.leftBarButtonItems = [doneButton]
            topController!.presentViewController(navController, animated: true, completion: nil)
        }
    }
    
    func activateUser() {
        
        guard UserController.instance.userId != nil else {
            fatalError("Activating user for notifications requires a current user")
        }
        
        OneSignal.syncHashedEmail(UserController.instance.userId)
        
        OneSignal.IdsAvailable() {
            userId, pushToken in
            
            NotificationController.instance.installId = userId
            
            if userId != nil {
                DataController.proxibase.registerInstall() {
                    response, error in
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        if let error = ServerError(error) {
                            Log.w("Error during registerInstall: \(error)")
                        }
                        else {
                            Log.i("Install registered or updated: \(NotificationController.instance.installId!)")
                        }
                    }
                }
            }
        }
    }
    
    func clearBadgeNumber() {
        self._badgeNumber.value = 0
    }

    func guardedRegisterForRemoteNotifications(message: String?) {

        let message = message ?? "Would you like to alerted when messages are posted to this patch?"

        if let controller = UIViewController.topMostViewController() {
            let alert = UIAlertController(title: "Joining Patch", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let submit = UIAlertAction(title: "Notify me", style: .Default) {
                action in
                self.registerForRemoteNotifications()
                Reporting.track("Selected Notifications for Patch")
            }
            let cancel = UIAlertAction(title: "No thanks", style: .Cancel) {
                action in
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
        OneSignal.registerForPushNotifications()
    }
}