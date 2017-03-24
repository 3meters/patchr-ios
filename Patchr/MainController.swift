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
import SDWebImage

class MainController: NSObject, iRateDelegate {

    static let instance = MainController()
    var window: UIWindow?
    var upgradeRequired = false
    var link: [AnyHashable: Any]?
    var introPlayed = false
    var bootstrapping = true
    static let channelPicker = ChannelSwitcherController()
    static let groupPicker = GroupSwitcherController()

    private override init() { }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Notifications
    *--------------------------------------------------------------------------------------------*/

    func stateInitialized(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.StateInitialized), object: nil)
        Log.d("State initialized - app state: \(Config.appState())")
        checkCompatibility() { compatible in
            if compatible || Config.appConfiguration == .debug {
                self.route()
            }
        }
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
        UIToolbar.appearance().tintColor = Theme.colorTint
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
        SlideMenuOptions.leftViewWidth = Config.navigationDrawerWidth
        SlideMenuOptions.rightViewWidth = Config.sideMenuWidth
        SlideMenuOptions.animationDuration = CGFloat(0.2)
        SlideMenuOptions.simultaneousGestureRecognizers = false
        
        MainController.groupPicker.simplePicker = true

        /* We always begin with the empty controller */
        self.window?.setRootViewController(rootViewController: EmptyViewController(), animated: true) // While we wait for state to initialize
        self.window?.makeKeyAndVisible()
        
        /* Initialize Branch: The deepLinkHandler gets called every time the app opens. */
        Branch.getInstance().initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: { [weak self] params, error in
            if error == nil {
                /* A hit could mean a deferred link match */
                if let clickedBranchLink = params?["+clicked_branch_link"] as? Bool , clickedBranchLink {
                    Log.d("Deep link routing based on clicked branch link", breadcrumb: true)
                    if !(self?.bootstrapping)! && self?.link == nil {
                        self?.routeDeepLink(link: params!, error: error)
                    }
                    else {
                        self?.link = params!
                    }
                }
            }
        })

        /* Turn on network activity indicator */
        AFNetworkActivityIndicatorManager.shared().isEnabled = true
        
        /* Put anything to keep synched here */
        FireController.db.child("clients").child("ios").keepSynced(true)

        NotificationCenter.default.addObserver(self, selector: #selector(stateInitialized(notification:)), name: NSNotification.Name(rawValue: Events.StateInitialized), object: nil)
    }

    func route() {
        
        let groupId = StateController.instance.groupId
        let channelId = StateController.instance.channelId
        
        if self.upgradeRequired {
            showLobby()
        }
        else if !UserController.instance.authenticated {
            showLobby() {
                self.bootstrapping = false
                if let link = MainController.instance.link {
                    MainController.instance.routeDeepLink(link: link, error: nil)
                }
            }
        }
        else if groupId == nil || channelId == nil {
            showLobby(controller: GroupSwitcherController()) {
                self.bootstrapping = false
                if let link = MainController.instance.link {
                    MainController.instance.routeDeepLink(link: link, error: nil)
                }
            }
        }
        else {
            showChannel(groupId: groupId!, channelId: channelId!) {
                self.bootstrapping = false
            }
        }
    }
    
    func showLobby(controller: UIViewController? = nil, then: (() -> Void)? = nil) {
        
        if StateController.instance.groupId != nil {
            StateController.instance.clearGroup()   // Make sure group and channel are both unset
        }
        
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
        let mainBar = mainWrapper.navigationBar as! AirNavigationBar
        let menuController = SideMenuViewController()
        let drawerWrapper = AirNavigationController(navigationBarClass: AirNavigationBar.self, toolbarClass: nil)
        let drawerBar = drawerWrapper.navigationBar as! AirNavigationBar
        
        mainBar.navigationBarHeight = 54
        drawerBar.navigationBarHeight = UserDefaults.standard.bool(forKey: Prefs.statusBarHidden) ? 74 : 54

        let slideController = SlideMenuController(mainViewController: mainWrapper
            , leftMenuViewController: drawerWrapper
            , rightMenuViewController: menuController)
        
        drawerWrapper.viewControllers = [MainController.channelPicker]
        drawerWrapper.view.backgroundColor = Theme.colorBackgroundTable
        
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

    func showChannel(groupId: String, channelId: String, then: (() -> Void)? = nil) {
        
        showMain {
            if let wrapper = self.window?.rootViewController?.slideMenuController()?.mainViewController as? AirNavigationController {
                let controller = ChannelViewController()
                controller.inputGroupId = groupId
                controller.inputChannelId = channelId
                wrapper.setViewControllers([controller], animated: true)
            }
            then?()
        }
    }

    func showEmpty(then: (() -> Void)? = nil) {
        
        showMain {
            if let wrapper = self.window?.rootViewController?.slideMenuController()?.mainViewController as? AirNavigationController {
                let controller = EmptyViewController()
                wrapper.setViewControllers([controller], animated: true)
            }
            then?()
        }
    }
    
    func routeDeepLink(link: [AnyHashable: Any], flow: Flow = .none, error: Error?) {
        /*
         * Logged in: open in channel
         * Not logged in: email -> username|password -> open channel
         */
        MainController.instance.link = nil
        if UserController.instance.authenticated {
            let groupId = (link["group_id"] as! String)
            let userId = UserController.instance.userId!
            
            /* Must be group member or we get permission denied */
            FireController.db.child("group-members/\(groupId)/\(userId)").observeSingleEvent(of: .value, with: { snap in
                if let membership = snap.value as? [String: Any] {
                    let role = membership["role"] as? String
                    self.processInvite(link: link, member: true, memberRole: role, flow: flow)
                }
                else {
                    self.processInvite(link: link, member: false, memberRole: nil, flow: flow)
                }
            }, withCancel: { error in
                self.processInvite(link: link, member: false, memberRole: nil, flow: flow)  // permission denied means not group member
            })
        }
        else {
            let controller = EmailViewController()
            controller.flow = .onboardInvite
            controller.inputInviteLink = link
            self.showLobby(controller: controller)
        }
    }
    
    func processInvite(link: [AnyHashable: Any], member: Bool = false, memberRole: String?, flow: Flow) {
        
        if let topController = UIViewController.topMostViewController() {
            
            let groupId = (link["group_id"] as! String)
            let groupTitle = link["groupTitle"] as! String
            let inviterName = link["inviterName"] as! String
            let inviteId = (link["invite_id"] as! String)
            let inviterId = (link["invited_by"] as! String)
            let channels = link["channels"] as? [String: String]
            let role = link["role"] as! String
            
            /* Check if already a member and not a channel invite */
            if memberRole != nil && memberRole! != "guest" && (channels == nil || channels!.count == 0) {
                if let topController = UIViewController.topMostViewController() {
                    let groupTitle = link["groupTitle"] as! String
                    let popup = PopupDialog(title: "Already a Member", message: "You are currently a member of the \(groupTitle) Patchr group!")
                    let button = DefaultButton(title: "OK") {
                        if flow == .onboardInvite {
                            let controller = GroupSwitcherController()
                            topController.navigationController?.pushViewController(controller, animated: true)
                        }
                    }
                    button.buttonHeight = 48
                    popup.addButton(button)
                    topController.present(popup, animated: true)
                }
                return
            }
            
            var message = "\(inviterName) has invited you to join the \"\(groupTitle)\" Patchr group."
            if channels != nil && channels!.count > 0 {
                if channels!.count > 1 {
                    message = "\(inviterName) has invited you to join these channels in the \(groupTitle) Patchr group.\n"
                    for channelName in channels!.values {
                        message += "\n#\(channelName)"
                    }
                }
                else {
                    let channelName = channels!.first!.value
                    message = "\(inviterName) has invited you to join the #\(channelName) channel in the \(groupTitle) Patchr group."
                }
            }
            
            let popup = PopupDialog(title: "Invitation", message: message)
            
            let cancelButton = CancelButton(title: "Cancel".uppercased(), height: 48) {
                // If we don't have a currrent group|channel then we are in the lobby
                if StateController.instance.groupId == nil || StateController.instance.channelId == nil {
                    self.route()
                }
            }
            
            let joinButton = DefaultButton(title: "Join".uppercased(), height: 48) {
                FireController.instance.addUserToGroup(groupId: groupId, channels: channels, role: role, inviteId: inviteId, invitedBy: inviterId) { error, result in
                    if error == nil {
                        if channels != nil {
                            self.afterChannelInvite(groupId: groupId, groupTitle: groupTitle, channels: channels)
                        } else {
                            self.afterGroupInvite(groupId: groupId, groupTitle: groupTitle)
                        }
                    }
                    else {
                        if let topController = UIViewController.topMostViewController() {
                            let popup = PopupDialog(title: "Expired Invitation", message: "Your invitation has expired or been revoked.")
                            let button = DefaultButton(title: "OK") {
                                if flow == .onboardInvite {
                                    // If we don't have a currrent group|channel then we are in the lobby
                                    if StateController.instance.groupId == nil || StateController.instance.channelId == nil {
                                        self.route()
                                    }
                                }
                            }
                            button.buttonHeight = 48
                            popup.addButton(button)
                            topController.present(popup, animated: true)
                        }
                    }
                }
            }
            
            popup.buttonAlignment = .horizontal
            popup.addButtons([cancelButton, joinButton])
            topController.present(popup, animated: true, completion: nil)
        }
    }
    
    func afterGroupInvite(groupId: String, groupTitle: String) {
        
        FireController.instance.autoPickChannel(groupId: groupId) { channelId in
            if channelId != nil {
                StateController.instance.setChannelId(channelId: channelId!, groupId: groupId)
                self.showChannel(groupId: groupId, channelId: channelId!)
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
    
    func afterChannelInvite(groupId: String, groupTitle: String, channels: [String: Any]?) {
        
        let channelId = channels!.first!.key
        let channelName = channels!.first!.value as! String
        StateController.instance.setChannelId(channelId: channelId, groupId: groupId)
        self.showChannel(groupId: groupId, channelId: channelId)
        
        Utils.delay(1.0) {
            if let topController = UIViewController.topMostViewController() {
                var message = "You have joined the #\(channelName) channel in the \(groupTitle) Patchr group. Use the message bar to send your first message."
                if channels!.count > 1 {
                    message = "You have joined multiple channels in the \(groupTitle) Patchr group. Use the message bar to send your first message."
                }
                let popup = PopupDialog(title: "Welcome!", message: message)
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
    
    func checkCompatibility(then: ((Bool) -> Void)? = nil) {
        FireController.db.child("clients").child("ios").observeSingleEvent(of: .value, with: { snap in
            if let minVersion = snap.value as? Int {
                if !UIShared.versionIsValid(versionMin: Int(minVersion)) {
                    self.upgradeRequired = true
                    UIShared.compatibilityUpgrade()
                }
            }
            then?(!self.upgradeRequired)
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

enum Flow: Int {
    case onboardLogin
    case onboardCreate
    case onboardInvite
    case internalCreate
    case internalInvite
    case none
}
