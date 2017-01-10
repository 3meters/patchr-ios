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
import PopupDialog

class MainController: NSObject, iRateDelegate {

    static let instance = MainController()
    var window: UIWindow?
    var upgradeRequired = false
    static let channelPicker = ChannelPickerController()
    static let groupPicker = GroupPickerController()

    private override init() { }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Notifications
    *--------------------------------------------------------------------------------------------*/

    func stateInitialized(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.StateInitialized), object: nil)
        Log.d("State initialized - app state: \(Utils.appState())")
        checkCompatibility()
        route()
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
        
        let dialogAppearance = PopupDialogDefaultView.appearance()
        
        dialogAppearance.backgroundColor = UIColor.white
        dialogAppearance.titleFont = Theme.fontTitleLarge
        dialogAppearance.titleColor = Theme.colorTextTitle
        dialogAppearance.titleTextAlignment = .center
        dialogAppearance.messageFont = Theme.fontTextDisplay
        dialogAppearance.messageColor = Theme.colorTextDisplay
        dialogAppearance.messageTextAlignment = .center
        dialogAppearance.cornerRadius = 4
        
        let overlayAppearance = PopupDialogOverlayView.appearance()
        
        overlayAppearance.color = Colors.clear
        overlayAppearance.blurRadius = 5
        overlayAppearance.blurEnabled = true
        overlayAppearance.liveBlur = false
        
        let buttonAppearance = DefaultButton.appearance()
        
        buttonAppearance.titleFont = Theme.fontButtonTitle
        buttonAppearance.titleColor = Theme.colorButtonTitle
        buttonAppearance.buttonColor = Colors.clear
        buttonAppearance.separatorColor = Theme.colorRule
        CancelButton.appearance().titleFont = Theme.fontButtonTitle

        /* Get the primary ui components ready */
        SlideMenuOptions.leftViewWidth = NAVIGATION_DRAWER_WIDTH
        SlideMenuOptions.rightViewWidth = SIDE_MENU_WIDTH
        SlideMenuOptions.animationDuration = CGFloat(0.2)
        SlideMenuOptions.simultaneousGestureRecognizers = false
        
        MainController.groupPicker.simplePicker = true

        self.window?.setRootViewController(rootViewController: EmptyViewController(), animated: true) // While we wait for state to initialize
        self.window?.makeKeyAndVisible()
        
        /* Initialize Branch: The deepLinkHandler gets called every time the app opens. */
        Branch.getInstance().initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: { [weak self] params, error in
            if error == nil {
                /* A hit could mean a deferred link match */
                if let clickedBranchLink = params?["+clicked_branch_link"] as? Bool , clickedBranchLink {
                    Log.d("Deep link routing based on clicked branch link", breadcrumb: true)
                    self?.routeDeepLink(params: params, error: error)    /* Presents modally on top of main tab controller. */
                }
            }
        })

        /* Turn on network activity indicator */
        AFNetworkActivityIndicatorManager.shared().isEnabled = true

        NotificationCenter.default.addObserver(self, selector: #selector(stateInitialized(notification:)), name: NSNotification.Name(rawValue: Events.StateInitialized), object: nil)
    }

    func route() {
        
        let groupId = StateController.instance.groupId
        let channelId = StateController.instance.channelId
        
        if self.upgradeRequired {
            showLobby()
        }
        else if !UserController.instance.authenticated {
            showLobby()
        }
        else if groupId == nil || channelId == nil {
            showLobby(controller: GroupPickerController())
        }
        else {
            showChannel(groupId: groupId!, channelId: channelId!)
        }
    }
    
    func showLobby(controller: UIViewController? = nil, then: (() -> Void)? = nil) {
        
        StateController.instance.clearGroup()   // Make sure group and channel are both unset
        
        let controller = controller ?? LobbyViewController()
        let wrapper = AirNavigationController(rootViewController: controller)
        
        if let emptyController = self.window?.rootViewController as? EmptyViewController {
            if !(controller is LobbyViewController) {
                emptyController.startScene() {
                    self.window?.setRootViewController(rootViewController: wrapper, animated: true) // Fade in
                    then?()
                }
                return
            }
        }
        
        self.window?.setRootViewController(rootViewController: wrapper, animated: true) // Fade in
        then?()
    }
    
    func showMain(then: (() -> Void)? = nil) {
        
        if self.window?.rootViewController is SlideMenuController {
            then?()
            return
        }
        
        let mainWrapper = AirNavigationController(navigationBarClass: AirNavigationBar.self, toolbarClass: nil)
        let menuController = SideMenuViewController()
        let drawerWrapper = AirNavigationController(navigationBarClass: AirNavigationBar.self, toolbarClass: nil)
        let slideController = SlideMenuController(mainViewController: mainWrapper
            , leftMenuViewController: drawerWrapper
            , rightMenuViewController: menuController)
        
        drawerWrapper.viewControllers = [MainController.groupPicker, MainController.channelPicker]
        
        if let emptyController = self.window?.rootViewController as? EmptyViewController,
            !emptyController.scenePlayed {
            emptyController.startScene() {
                self.window?.setRootViewController(rootViewController: slideController, animated: true)
                then?()
            }
        }
        else {
            if let wrapper = self.window?.rootViewController as? AirNavigationController {
                wrapper.viewControllers = []
            }
            self.window?.setRootViewController(rootViewController: slideController, animated: true)
            then?()
        }
    }

    func showChannel(groupId: String, channelId: String) {
        
        showMain {
            if let wrapper = self.window?.rootViewController?.slideMenuController()?.mainViewController as? AirNavigationController {
                let controller = ChannelViewController()
                controller.inputGroupId = groupId
                controller.inputChannelId = channelId
                wrapper.setViewControllers([controller], animated: true)
            }
        }
    }

    func routeDeepLink(params: [AnyHashable: Any]?, error: Error?) {
        /*
         * Logged in: open in channel
         * Not logged in: email -> username|password -> open channel
         */
        let groupId = (params?["groupId"] as! String)
        
        FireController.db.child("groups/\(groupId)").observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                
                if UserController.instance.authenticated {
                    
                    let userId = UserController.instance.userId!
                    let path = "group-members/\(groupId)/\(userId)"
                    
                    FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
                        if !(snap.value is NSNull) {
                            if let topController = UIViewController.topMostViewController() {
                                let groupTitle = params!["groupTitle"] as! String
                                let popup = PopupDialog(title: "Already a Member", message: "You are currently a member of the \(groupTitle) Patchr group!")
                                let button = DefaultButton(title: "OK") {}
                                button.buttonHeight = 48
                                popup.addButton(button)
                                topController.present(popup, animated: true)
                            }
                        }
                        else {
                            if let topController = UIViewController.topMostViewController() {
                                
                                let groupTitle = params!["groupTitle"] as! String
                                let referrerName = params!["referrerName"] as! String
                                let role = params!["role"] as! String
                                let channelId = params!["channelId"] as? String
                                let channelName = params!["channelName"] as? String
                                
                                var message = "\(referrerName) has invited you to join the \"\(groupTitle)\" Patchr group."
                                if channelId != nil {
                                   message = "\(referrerName) has invited you to join the #\(channelName!) channel of the \(groupTitle) Patchr group."
                                }
                                
                                let popup = PopupDialog(title: "Invitation", message: message)
                                let cancelButton = CancelButton(title: "Cancel".uppercased(), height: 48) {
                                    /* If we don't have a currrent group|channel then we are in the lobby */
                                    if StateController.instance.groupId == nil || StateController.instance.channelId == nil {
                                        self.route()
                                    }
                                }
                                let joinButton = DefaultButton(title: "Join".uppercased(), height: 48) {
                                    FireController.instance.addUserToGroup(userId: userId, groupId: groupId, channelId: channelId, role: role, then: { success in
                                        if success {
                                            if channelId != nil {
                                                StateController.instance.setChannelId(channelId: channelId!, groupId: groupId)
                                                self.showChannel(groupId: groupId, channelId: channelId!)
                                                Utils.delay(1.0) {
                                                    if let topController = UIViewController.topMostViewController() {
                                                        let popup = PopupDialog(title: "Welcome!", message: "You have joined the #\(channelName!) channel of the \(groupTitle) Patchr group. Use the message bar to send your first message.")
                                                        popup.buttonAlignment = .horizontal
                                                        let showButton = DefaultButton(title: "Show Me".uppercased(), height: 48) {
                                                            if let slideController = self.window?.rootViewController as? SlideMenuController,
                                                                let wrapper = slideController.mainViewController as? AirNavigationController,
                                                                let channelController = wrapper.topViewController as? ChannelViewController {
                                                                    channelController.textInputbar.textView.becomeFirstResponder()
                                                            }
                                                        }
                                                        let doneButton = DefaultButton(title: "Carry On".uppercased(), height: 48) {}
                                                        popup.addButtons([showButton, doneButton])
                                                        topController.present(popup, animated: true)
                                                    }
                                                }
                                            }
                                            else {
                                                FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                                                    if firstChannelId != nil {
                                                        StateController.instance.setChannelId(channelId: firstChannelId!, groupId: groupId)
                                                        self.showChannel(groupId: groupId, channelId: firstChannelId!)
                                                        Utils.delay(1.0) {
                                                            if let topController = UIViewController.topMostViewController() {
                                                                let popup = PopupDialog(title: "Welcome!", message: "You are now a member of the \(groupTitle) Patchr group. Use the navigation drawer to discover and join channels.")
                                                                popup.buttonAlignment = .horizontal
                                                                let showButton = DefaultButton(title: "Show Me".uppercased(), height: 48) {
                                                                    if let slideController = self.window?.rootViewController as? SlideMenuController {
                                                                        slideController.openLeft()
                                                                    }
                                                                }
                                                                let doneButton = DefaultButton(title: "Carry On".uppercased(), height: 48) {}
                                                                popup.addButtons([showButton, doneButton])
                                                                topController.present(popup, animated: true)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    })
                                }
                                
                                popup.buttonAlignment = .horizontal
                                popup.addButtons([cancelButton, joinButton])
                                topController.present(popup, animated: true, completion: nil)
                                
//                                let controller = JoinViewController()
//                                controller.inputGroupId = params?["groupId"] as? String
//                                controller.inputRole = params?["role"] as? String
//                                controller.inputChannelId = params?["channelId"] as? String
//                                controller.inputGroupTitle = params?["groupTitle"] as? String
//                                controller.inputChannelName = params?["channelName"] as? String
//                                controller.inputReferrerName = params?["referrerName"] as? String
//                                controller.inputReferrerId = params?["referrerId"] as? String
//                                controller.inputReferrerPhotoUrl = params?["referrerPhotoUrl"] as? String
//                                controller.flow = .onboardInvite
                            }
                        }
                    })
                }
                else {
                    let controller = EmailViewController()
                    controller.flow = .onboardInvite
                    controller.inputInviteParams = params
                    self.showLobby(controller: controller)
                }
            }
            else {
                UIShared.Toast(message: "The \(params!["groupTitle"]) Patchr group is not active")
            }
        })
    }
    
    func checkCompatibility() {
        FireController.db.child("clients").child("ios").observeSingleEvent(of: .value, with: { snap in
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
