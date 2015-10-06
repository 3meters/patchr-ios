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

/*
2015-07-27 17:10:15.925 Patchr[3944:1140648] {
aps =     {
alert = "\"Moo\" sent a message to your patch \"Test Me!\": \"Yay\"";
badge = 18;
};
parentId = "pa.150227.01674.918.326046";
targetId = "me.150728.00614.046.516341";
trigger = "own_to";
}
2015-07-27 17:13:23.899 Patchr[3944:1140648] {
aps =     {
alert = "\"Moo\" liked your message: \"Let try it\"";
badge = 19;
};
targetId = "me.150608.85514.713.474815";
trigger = "own_to";
}
2015-07-27 17:14:34.355 Patchr[3944:1140648] {
aps =     {
alert = "\"Moo\" created the patch \"Moo Time\" nearby";
badge = 20;
};
targetId = "pa.150728.00872.983.302833";
trigger = nearby;
}
2015-07-27 17:16:59.047 Patchr[3944:1140648] {
aps =     {
alert = "\"Moo\" added your patch \"Test Me!\" as a favorite";
badge = 21;
};
targetId = "pa.150227.01674.918.326046";
trigger = "own_to";
}
2015-07-27 17:17:01.630 Patchr[3944:1140648] {
aps =     {
alert = "\"Moo\" started watching your patch \"Test Me!\"";
badge = 22;
};
targetId = "pa.150227.01674.918.326046";
trigger = "own_to";
}
*/
let PAApplicationDidReceiveRemoteNotification = "PAApplicationDidReceiveRemoteNotification"

class NotificationController {
    
    static let instance = NotificationController()
    
    var activityDate: Int64!
    
    private init() {
        self.activityDate = Int64(NSDate().timeIntervalSince1970 * 1000)
    }
    
    func didReceiveLocalNotification(application: UIApplication, notification: UILocalNotification) {
        didReceiveRemoteNotification(application, userInfo: notification.userInfo!, fetchCompletionHandler: nil)
    }
    
    func didReceiveRemoteNotification(application: UIApplication, userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: ((UIBackgroundFetchResult) -> Void)? ) {
        
        Log.d("Notification received...")
        let state = application.applicationState
        if let stateString: String = state == .Background ? "background" : state == .Active ? "active" : "inactive" {
            Log.d("App state: \(stateString)")
        }
        Log.d(String(format: "%@", userInfo))
        
        /* Tickle the activityDate so consumers know that something has happened */
        self.activityDate = Int64(NSDate().timeIntervalSince1970 * 1000)
        
        /* Special capture for nearby notifications */
        if let trigger = userInfo["trigger"] as? String where trigger == "nearby" {
            var nearby = userInfo
            let aps = nearby["aps"] as! NSDictionary
            nearby["summary"] = aps["alert"]
            nearby["sentDate"] = NSNumber(longLong: Int64(NSDate().timeIntervalSince1970 * 1000)) // Only way to store Int64 as AnyObject
            nearby["createdDate"] = nearby["sentDate"]
            nearby["sortDate"] = nearby["sentDate"]
            nearby["type"] = "nearby"
            nearby["schema"] = "notification"
            nearby.removeValueForKey("aps")
            Utils.updateNearbys(nearby)
        }
        /*
         * Inactive always means that the user tapped on remote notification.
         * Active = notification received while app is active (foreground)
         */
        if state == .Inactive || state == .Active {
            let augmentedUserInfo = NSMutableDictionary(dictionary: userInfo)
            augmentedUserInfo["receivedInApplicationState"] = application.applicationState.rawValue // active, inactive, background
            NSNotificationCenter.defaultCenter().postNotificationName(PAApplicationDidReceiveRemoteNotification, object: self, userInfo: augmentedUserInfo as [NSObject : AnyObject])
            if (completionHandler != nil) {
                completionHandler!(.NoData)
            }
        }
        /*
        * Background = notification received while app is not active (background or dead)
        */
        else if state == .Background {
            /*
             * If alert property is set then it will get handled as a remote notification otherwise
             * we re-route it as a local notification.
             */
            if let aps = userInfo["aps"] as? NSDictionary {
                if aps["alert"] == nil {
                    let notification = UILocalNotification()
                    notification.alertBody = (userInfo["alert-x"] as! String) // Text that will be displayed in the notification
                    notification.alertAction = "open" // Text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
                    notification.fireDate = NSDate() // Date when notification will be fired (now)
                    if let sound = userInfo["sound-x"] as? String {
                        notification.soundName = sound
                    }
                    notification.userInfo = userInfo
                    UIApplication.sharedApplication().scheduleLocalNotification(notification)
                }
            }
            if (completionHandler != nil) {
                completionHandler!(.NoData)
            }
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
    
    func registerForRemoteNotifications() {
        
        let application = UIApplication.sharedApplication()
        
        if #available(iOS 8.0, *) {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        else {
            // Register for Push Notifications before iOS 8
            application.registerForRemoteNotificationTypes([.Alert, .Badge, .Sound])
        }
    }
}