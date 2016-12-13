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
import Branch

class MainController: NSObject, iRateDelegate {

    static let instance = MainController()
    
    let db = FIRDatabase.database().reference()
    var window: UIWindow?
    
    var slideController : SlideMenuController!
    var sideMenuController = SideMenuViewController()
    var channelPickerController = ChannelPickerController()
    
    var emptyController = EmptyViewController()
    var channelController = ChannelViewController()
    var lobbyController = LobbyViewController()
    
    var mainWrapper: AirNavigationController!
    var lobbyWrapper: AirNavigationController!
    
    var upgradeRequired = false

    private override init() { }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Notifications
    *--------------------------------------------------------------------------------------------*/

    func stateInitialized(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.StateInitialized), object: nil)
        checkCompatibility()
        route()
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

        self.mainWrapper = AirNavigationController(navigationBarClass: AirNavigationBar.self, toolbarClass: nil)
        self.mainWrapper.viewControllers = [self.channelController]
        self.slideController = SlideMenuController(mainViewController: self.mainWrapper
            , leftMenuViewController: self.channelPickerController
            , rightMenuViewController: self.sideMenuController)
        self.lobbyWrapper = AirNavigationController(rootViewController: self.lobbyController)

        self.window?.setRootViewController(rootViewController: self.emptyController, animated: true) // While we wait for state to initialize
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
        else if !UserController.instance.authenticated {
            showLobby()
        }
        else if StateController.instance.groupId == nil || StateController.instance.channelId == nil {
            self.showGroupPicker() // Here to catch inconsistent state
        }
        else {
            self.showMain()
            self.showChannel(groupId: StateController.instance.groupId!, channelId: StateController.instance.channelId!)
        }
    }
    
    func showLobby() {
        self.window?.setRootViewController(rootViewController: self.lobbyWrapper, animated: true)
    }
    
    fileprivate func showGroupPicker() {
        
        StateController.instance.clearGroup()   // Make sure group and channel are both unset
        let controller = GroupPickerController()
        let wrapper = AirNavigationController()
        wrapper.viewControllers = [controller]
        
        if self.window?.rootViewController == self.emptyController {
            self.emptyController.startScene() {
                UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
            }
        }
        else {
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
    }
    
    func showMain() {
        if self.window?.rootViewController == self.emptyController {
            self.emptyController.startScene() {
                self.window?.setRootViewController(rootViewController: self.slideController, animated: true)
            }
        }
    }

    func showChannel(groupId: String, channelId: String) {
        if let root = self.window?.rootViewController, root != self.slideController {
            showMain()
        }
        let _ = self.channelController.view // Triggers viewDidLoad
        self.channelController.bind(groupId: groupId, channelId: channelId)
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
        /*
         * Logged in: username -> open in group or group/channel
         * Else: email -> password -> username -> open in group or group/channel
         */
        let groupId = (params?["groupId"] as! String)
        
        FireController.db.child("groups/\(groupId)").observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                if UserController.instance.authenticated {
                    
                    let userId = UserController.instance.userId!
                    let path = "group-members/\(groupId)/\(userId)"
                    
                    FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
                        if !(snap.value is NSNull) {
                            UIShared.Toast(message: "Already a member of the \(params!["groupTitle"]) Patchr group!")
                        }
                        else {
                            let controller = JoinViewController()
                            let wrapper = AirNavigationController()
                            controller.inputGroupId = params?["groupId"] as? String
                            controller.inputRole = params?["role"] as? String
                            controller.inputChannelId = params?["channelId"] as? String
                            controller.inputGroupTitle = params?["groupTitle"] as? String
                            controller.inputChannelName = params?["channelName"] as? String
                            controller.inputReferrerName = params?["referrerName"] as? String
                            controller.inputReferrerId = params?["referrerId"] as? String
                            controller.inputReferrerPhotoUrl = params?["referrerPhotoUrl"] as? String
                            controller.flow = .onboardInvite
                            wrapper.viewControllers = [controller]
                            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
                        }
                    })
                }
                else {
                    let controller = EmailViewController()
                    let wrapper = AirNavigationController()
                    controller.flow = .onboardInvite
                    controller.inputInviteParams = params
                    wrapper.viewControllers = [controller]
                    UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
                }
            }
            else {
                UIShared.Toast(message: "The \(params!["groupTitle"]) Patchr group is not active")
            }
        })
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
