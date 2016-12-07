/*
 * BingController
 */
import UserNotifications
import Firebase
import FirebaseInstanceID
import FirebaseMessaging

class NotificationController: NSObject {

    static let instance  = NotificationController()
    
    var groupBadgeCounts: [String: Int] = [:]
    var channelBadgeCounts: [String: Int] = [:]
    var newMessages: [String: Bool] = [:]
    var totalBadgeCount = 0
    
    private override init() {}

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func didReceiveLocalNotification(application: UIApplication, notification: UILocalNotification) {
        didReceiveRemoteNotification(application: application, notification: notification.userInfo!, fetchCompletionHandler: nil)
    }
    
    func didReceiveRemoteNotification(application: UIApplication, notification: [AnyHashable: Any], fetchCompletionHandler completionHandler: ((UIBackgroundFetchResult) -> Void)?) {
        /*
         * The remote notification has already been displayed to the user and now we
         * have a chance to do any processing that should accompany the notification. Even
         * if the user has turned off remote notifications, we still get this call.
         */
        Log.d("Notification received...")
        Log.d("App state: \(application.applicationState == .background ? "background" : application.applicationState == .active ? "active" : "inactive")")
        /*
         * Inactive:    Always means that the user tapped on remote notification.
         * Active:      Notification received while app is active (foreground).
         * Background:  Notification received while app is not active (background or dead)
         */
        let channelId = notification["channelId"] as! String
        let groupId = notification["groupId"] as! String
        let messageId = notification["messageId"] as! String
        let userId = UserController.instance.userId
        
        if application.applicationState == .inactive {
            /* Switch to the channel */
            StateController.instance.setGroupId(groupId: groupId, channelId: channelId)
            MainController.instance.showChannel(groupId: groupId, channelId: channelId)
        }
        else {
            if let creatorId = notification["userId"] as? String, creatorId != userId {
                if application.applicationState == .background {
                    self.totalBadgeCount += 1
                    application.applicationIconBadgeNumber = self.totalBadgeCount
                }
                
                if self.groupBadgeCounts[groupId] == nil {
                    self.groupBadgeCounts[groupId] = 0
                }
                
                if self.channelBadgeCounts[channelId] == nil {
                    self.channelBadgeCounts[channelId] = 0
                }
                
                self.newMessages[messageId] = true
                self.groupBadgeCounts[groupId] = self.groupBadgeCounts[groupId]! + 1
                self.channelBadgeCounts[channelId] = self.channelBadgeCounts[channelId]! + 1
                
                if userId != nil {
                    let channelQuery = ChannelQuery(groupId: groupId, channelId: channelId, userId: userId)
                    channelQuery.once(with: { channel in
                        if channel?.priority != 0 {
                            channel?.unread(on: true)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.UnreadChange), object: self, userInfo: nil)
                        }
                    })
                }
            }
        }
        /*
         * We have thirty seconds to process and call the completion handler before being
         * terminated if the app was woken to process the notification.
         */
        if (completionHandler != nil) {
            completionHandler!(.noData)
        }
    }
    
    func didRegisterForRemoteNotificationsWithDeviceToken(application: UIApplication, deviceToken: Data) {
        Log.d("Success registering for remote notifications")
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(application: UIApplication, error: Error) {
        Log.w("Failed to register for remote notifications: \(error)")
    }
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func prepare() {
        // Add observer for InstanceID token refresh callback.
        NotificationCenter.default.addObserver(self
            , selector: #selector(tokenRefreshNotification)
            , name: .firInstanceIDTokenRefresh
            , object: nil)
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            Log.d("InstanceID token: \(refreshedToken)")
            if let userId = UserController.instance.userId {
                FireController.db.child("installs/\(userId)/\(refreshedToken)").setValue(true)
            }
        }
        connectToFcm() /* Connect to FCM since connection may have failed when attempted before having a token. */
    }
    
    func connectToFcm() {
        FIRMessaging.messaging().connect { error in
            Log.d((error != nil) ? "Unable to connect with FCM. \(error!)" : "Connected to FCM.")
        }
    }
    
    func disconnectFromFcm() {
        FIRMessaging.messaging().disconnect()
        Log.d("Disconnected from FCM.")
    }
}

