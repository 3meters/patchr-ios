/*
 * Firebase controller
 *
 * Provide convenience functionality when interacting with the Firebase database.
 */

import UIKit
import Keys
import AFNetworking
import iRate
import SlideMenuControllerSwift
import Firebase
import FirebaseDatabase
import RxSwift

class MainController: NSObject, iRateDelegate {

    static let instance = MainController()
    
    var onlineRef: FIRDatabaseReference!
    var userRef: FIRDatabaseReference!

    var window: UIWindow?
    let db = FIRDatabase.database().reference()
    var disposeBag = DisposeBag()
    var groupId: String?
    var channelId: String?

    private override init() { }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Notifications
    *--------------------------------------------------------------------------------------------*/

    func channelDidChange(notification: NSNotification) {
        let channelId = notification.userInfo?["channelId"] as? String
        let groupId = notification.userInfo?["groupId"] as? String
        if (channelId != nil && groupId != nil) {
            self.showChannel(groupId: self.groupId!, channelId: channelId!)
        }
        else {
            self.clearChannel()
        }
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    func prepare() {

        iRate.sharedInstance().verboseLogging = false
        iRate.sharedInstance().daysUntilPrompt = 7
        iRate.sharedInstance().usesUntilPrompt = 10
        iRate.sharedInstance().remindPeriod = 1
        iRate.sharedInstance().promptForNewVersionIfUserRated = true
        iRate.sharedInstance().onlyPromptIfLatestVersion = true
        iRate.sharedInstance().useUIAlertControllerIfAvailable = true
        iRate.sharedInstance().promptAtLaunch = false
        iRate.sharedInstance().delegate = self

        self.window = (UIApplication.shared.delegate?.window)!

        /* Initialize Creative sdk: 25% of method time */
        AdobeUXAuthManager.shared().setAuthenticationParametersWithClientID(PatchrKeys().creativeSdkClientId(), clientSecret: PatchrKeys().creativeSdkClientSecret(), enableSignUp: false)

        /* Turn on status bar */
        let statusBarHidden = UserDefaults.standard.bool(forKey: PatchrUserDefaultKey(subKey: "statusBarHidden"))    // Default = false, set in dev settings
        UIApplication.shared.setStatusBarHidden(statusBarHidden, with: UIStatusBarAnimation.slide)

        /* Global UI tweaks */
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: Theme.fontBarText], for: UIControlState.normal)
        self.window?.backgroundColor = Theme.colorBackgroundWindow
        self.window?.tintColor = Theme.colorTint
        UINavigationBar.appearance().tintColor = Theme.colorTint
        UITabBar.appearance().tintColor = Theme.colorTabBarTint
        UISwitch.appearance().onTintColor = Theme.colorTint

        /* Turn on network activity indicator */
        AFNetworkActivityIndicatorManager.shared().isEnabled = true

        self.groupId = UserDefaults.standard.string(forKey: "groupId")
        if self.groupId != nil {
            self.channelId = UserDefaults.standard.string(forKey: self.groupId!)
        }
        
        self.onlineRef = FIRDatabase.database().reference().child(".info/connected")
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if user != nil {
                self.userRef = FIRDatabase.database().reference().child("users/\(user!.uid)")
                self.onlineRef.observe(.value, with: { snap in
                    if snap.value != nil {
                        self.userRef.onDisconnectUpdateChildValues(["presence": FIRServerValue.timestamp()])
                        self.userRef.updateChildValues(["presence": true])
                    }
                })
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainController.channelDidChange(notification:)), name: NSNotification.Name(rawValue: Events.ChannelDidChange), object: nil)
    }

    func didLaunch() {
        checkCompatibility()
        route()
    }

    func route() {
        if (UserController.instance.fireUser) != nil {
            showMain()
        }
        else {
            showLobby()
        }
        self.window?.makeKeyAndVisible()
    }

    func showMain() {

        SlideMenuOptions.leftViewWidth = NAVIGATION_DRAWER_WIDTH
        SlideMenuOptions.rightViewWidth = SIDE_MENU_WIDTH
        SlideMenuOptions.animationDuration = CGFloat(0.2)
        SlideMenuOptions.simultaneousGestureRecognizers = false

        let mainController = EmptyViewController()   // Placeholder
        let channelPicker = ChannelPickerController()
        let menuController = SideMenuViewController()
        let leftNavController = AirNavigationController(rootViewController: channelPicker)
        
        leftNavController.setNavigationBarHidden(true, animated: false)
        channelPicker.inputGroupId = self.groupId
        mainController.emptyLabel.text = "Loading..."

        let drawerController = SlideMenuController(mainViewController: mainController, leftMenuViewController: leftNavController, rightMenuViewController: menuController)
        self.window?.setRootViewController(rootViewController: drawerController, animated: true)
        
        if self.channelId != nil {
            showChannel(groupId: self.groupId!, channelId: self.channelId!)
        }
    }

    func showLobby() {
        let controller = LobbyViewController()
        let navController = AirNavigationController()
        navController.viewControllers = [controller]
        self.window?.setRootViewController(rootViewController: navController, animated: true)
    }

    func showChannel(groupId: String, channelId: String) {
        let controller = ChannelViewController()
        controller.inputChannelId = channelId
        controller.inputGroupId = groupId
        let nav = AirNavigationController(rootViewController: controller)
        self.window?.rootViewController?.slideMenuController()?.changeMainViewController(nav, close: true)
    }

    func clearChannel() {
        if let slideMenuController = self.window?.rootViewController?.slideMenuController() {
            let controller = EmptyViewController()
            controller.emptyLabel.text = "You really need to select a channel!"
            slideMenuController.changeMainViewController(controller, close: false)
        }
    }

    func setGroupId(groupId: String?) {

        /* Setting to nil */
        guard let groupId = groupId else {
            UserDefaults.standard.removeObject(forKey: "groupId")
            if self.groupId != nil {
                UserDefaults.standard.removeObject(forKey: self.groupId!)
                self.groupId = nil
            }
            setChannelId(channelId: nil)
            return
        }

        /* Changing */
        if self.groupId != groupId {
            self.groupId = groupId
            UserDefaults.standard.set(groupId, forKey: "groupId")
            let lastChannelId = UserDefaults.standard.string(forKey: groupId)
            setChannelId(channelId: lastChannelId ?? nil)
            let userInfo = [
                "groupId": self.groupId
            ]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: userInfo)
        }
    }

    func setChannelId(channelId: String?) {
        self.channelId = channelId
        UserDefaults.standard.set(channelId, forKey: self.groupId!)
        let userInfo = [
            "groupId": self.groupId,
            "channelId":self.channelId
        ]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.ChannelDidChange), object: self, userInfo: userInfo)
    }

    func checkCompatibility() {
        db.child("clients").child("ios").observeSingleEvent(of: .value, with: {
            snapshot in
            if let minVersion = snapshot.value as? Int {
                if !UIShared.versionIsValid(versionMin: Int(minVersion)) {
                    UIShared.compatibilityUpgrade()
                }
            }
        })
    }

    func disableAnimations(state: Bool) {
        UIView.setAnimationsEnabled(!state)
        UIApplication.shared.keyWindow!.layer.speed = state ? 100.0 : 1.0
    }

    func resetToLobby() {
        /*
         * Client state is reset but service may still see the install as signed in.
         * The service will still send notifications to the install based on the signed in user.
         * We assume that if no authenticated user then we are at correct initial state.
         */
        UserController.instance.discardCredentials()
        Reporting.updateUser(user: nil)
        BranchProvider.logout()

        UserDefaults.standard.set(nil, forKey: PatchrUserDefaultKey(subKey: "userEmail"))
        UserController.instance.clearStore()
        LocationController.instance.clearLastLocationAccepted()

        if !(UIViewController.topMostViewController() is LobbyViewController) {
            let navController = AirNavigationController()
            navController.viewControllers = [LobbyViewController()]
            self.window!.setRootViewController(rootViewController: navController, animated: true)
        }
    }
}

extension MainController {
    func iRateDidPromptForRating() {
        Reporting.track("Prompted for Rating")
    }

    func iRateUserDidAttemptToRateApp() {
        Reporting.track("Attempted to Rate")
    }

    func iRateUserDidDeclineToRateApp() {
        Reporting.track("Declined to Rate")
    }

    func iRateUserDidRequestReminderToRateApp() {
        Reporting.track("Requested Reminder to Rate")
    }
}
