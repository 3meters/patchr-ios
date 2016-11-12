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
import Branch

class MainController: NSObject, iRateDelegate {

    static let instance = MainController()
    
    let db = FIRDatabase.database().reference()
    var window: UIWindow?
    
    var emptyController = EmptyViewController()
    var channelController = ChannelViewController()
    var sideMenuController = SideMenuViewController()
    var channelPickerController = ChannelPickerController()
    
    var slideController : SlideMenuController!
    var navigationController: AirNavigationController!
    var lobbyController: AirNavigationController!
    
    var upgradeRequired = false

    private override init() { }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Notifications
    *--------------------------------------------------------------------------------------------*/

    func channelDidChange(notification: NSNotification) {
        route()
    }
    
    func groupDidChange(notification: NSNotification) {
        route()
    }

    func userStateDidChange(notification: NSNotification) {
        route()
    }
    
    func stateInitialized(notification: NSNotification) {
        checkCompatibility()
        route()
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidChange(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(channelDidChange(notification:)), name: NSNotification.Name(rawValue: Events.ChannelDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userStateDidChange(notification:)), name: NSNotification.Name(rawValue: Events.UserStateDidChange), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    func prepare(launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) {

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

        /* Get the primary ui components ready */
        SlideMenuOptions.leftViewWidth = NAVIGATION_DRAWER_WIDTH
        SlideMenuOptions.rightViewWidth = SIDE_MENU_WIDTH
        SlideMenuOptions.animationDuration = CGFloat(0.2)
        SlideMenuOptions.simultaneousGestureRecognizers = false

        self.lobbyController = AirNavigationController(rootViewController: LobbyViewController())
        self.navigationController = AirNavigationController(rootViewController: self.channelPickerController)
        self.navigationController.setNavigationBarHidden(true, animated: false)

        self.slideController = SlideMenuController(
            mainViewController: self.emptyController,
            leftMenuViewController: self.navigationController,
            rightMenuViewController: self.sideMenuController)

        self.window?.setRootViewController(rootViewController: self.slideController, animated: true) // While we wait for state to initialize
        self.window?.makeKeyAndVisible()
        
        /* Initialize Branch: The deepLinkHandler gets called every time the app opens. */
        Branch.getInstance().initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: { params, error in
            if error == nil {
                /* A hit could mean a deferred link match */
                if let clickedBranchLink = params["+clicked_branch_link"] as? Bool , clickedBranchLink {
                    Log.d("Deep link routing based on clicked branch link", breadcrumb: true)
                    self.routeDeepLink(params: params, error: error)    /* Presents modally on top of main tab controller. */
                }
            }
        })

        /* Turn on network activity indicator */
        AFNetworkActivityIndicatorManager.shared().isEnabled = true

        NotificationCenter.default.addObserver(self, selector: #selector(stateInitialized(notification:)), name: NSNotification.Name(rawValue: Events.StateInitialized), object: nil)
    }

    func route() {
        if self.upgradeRequired {
            showLobby()
        }
        else if UserController.instance.userId == nil {
            showLobby()
        }
        else if StateController.instance.groupId != nil && StateController.instance.channelId != nil {
            showMain()
            showChannel(groupId: StateController.instance.groupId!, channelId: StateController.instance.channelId!)
        }
    }
    
    func showMain() {
        if self.slideController.mainViewController != self.channelController {
            _ = self.channelController.view // Triggers viewDidLoad
            let nav = AirNavigationController(navigationBarClass: AirNavigationBar.self, toolbarClass: nil)
            nav.viewControllers = [self.channelController]
            self.slideController.changeMainViewController(nav, close: false)
        }
        if self.window?.rootViewController != self.slideController {
            self.window?.setRootViewController(rootViewController: self.slideController, animated: true)
        }
    }

    func showLobby() {
        if self.window?.rootViewController != self.lobbyController {
            self.window?.setRootViewController(rootViewController: self.lobbyController, animated: true)
        }
    }

    func showGroupPicker() {
        let controller = GroupPickerController()
        controller.mode = .fullscreen
        let nav = AirNavigationController(rootViewController: controller)
        self.window?.setRootViewController(rootViewController: nav, animated: true)
    }

    func showChannel(groupId: String, channelId: String) {
        self.channelController.bind(groupId: groupId, channelId: channelId)
    }

    func clearChannel() {
        if let slideMenuController = self.window?.rootViewController?.slideMenuController() {
            let controller = EmptyViewController()
            controller.emptyLabel.text = "You really need to select a channel!"
            slideMenuController.changeMainViewController(controller, close: false)
        }
    }

    func checkCompatibility() {
        db.child("clients").child("ios").observeSingleEvent(of: .value, with: { snap in
            if let minVersion = snap.value as? Int {
                if !UIShared.versionIsValid(versionMin: Int(minVersion)) {
                    self.upgradeRequired = true
                    UIShared.compatibilityUpgrade()
                }
            }
        })
    }

    func disableAnimations(state: Bool) {
        UIView.setAnimationsEnabled(!state)
        UIApplication.shared.keyWindow!.layer.speed = state ? 100.0 : 1.0
    }
    
    func routeDeepLink(params: [AnyHashable: Any]?, error: Error?) {
        if let groupId = params?["groupId"] as? String {
            let channelId = params?["channelId"] as? String
            let guest = params?["guest"] as? Bool
            
            if UserController.instance.authenticated {
                let userId = UserController.instance.userId
                FireController.db.child("group-members/\(groupId)/\(userId!)").observeSingleEvent(of: .value, with: { snap in
                    let alreadyMember = !(snap.value is NSNull)
                    if !alreadyMember {
                        FireController.instance.addUserToGroup(groupId: groupId, channelId: channelId, guest: guest!, complete: { error in
                            StateController.instance.setGroupId(groupId: groupId, channelId: channelId)
                        })
                    }
                    else {
                        /* Toast: Already a member */
                        UIShared.Toast(message: "Already a member of this group!")
                    }
                })
            }
            else {
                /*
                 * - User needs to log in or sign up.
                 * - Add user to group/channel as member/guest
                 * - Auto switch to group/channel
                 */
            }
        }
    }

    func resetToLobby() {
        /*
         * Client state is reset but service may still see the install as signed in.
         * The service will still send notifications to the install based on the signed in user.
         * We assume that if no authenticated user then we are at correct initial state.
         */
        ZUserController.instance.discardCredentials()
        Reporting.updateUser(user: nil)
        BranchProvider.logout()

        UserDefaults.standard.set(nil, forKey: PatchrUserDefaultKey(subKey: "userEmail"))
        ZUserController.instance.clearStore()
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
