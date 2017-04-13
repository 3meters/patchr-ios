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
    var containerController: ContainerController!

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
        AdobeUXAuthManager.shared().setAuthenticationParametersWithClientID(Ids.creativeClientId
            , clientSecret: PatchrKeys().creativeSdkClientSecret, enableSignUp: false)

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
        
        /* We always begin with the empty controller */
        self.containerController = ContainerController()
        self.containerController.setViewController(EmptyViewController())
        self.window?.setRootViewController(rootViewController: self.containerController) // While we wait for state to initialize
        self.window?.makeKeyAndVisible()
        
        /* Initialize Branch: The deepLinkHandler gets called every time the app opens. */
        Branch.getInstance().initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: { [weak self] params, error in
            guard let this = self else { return }
            if error == nil {
                /* A hit could mean a deferred link match */
                if let clickedBranchLink = params?["+clicked_branch_link"] as? Bool , clickedBranchLink {
                    Log.d("Deep link routing based on clicked branch link", breadcrumb: true)
                    if !this.bootstrapping && this.link == nil {
                        this.routeDeepLink(link: params!, error: error)
                    }
                    else {
                        this.link = params!
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
                    Reporting.track("resume_invite")
                    MainController.instance.link = nil
                    MainController.instance.routeDeepLink(link: link, error: nil)
                }
            }
        }
        else if groupId == nil || channelId == nil {
            let userId = UserController.instance.userId!
            FireController.instance.findFirstGroup(userId: userId) { groupId in
                if groupId == nil {
                    self.showUserLobby() {
                        self.bootstrapping = false
                        if let link = MainController.instance.link {
                            Reporting.track("resume_invite")
                            MainController.instance.link = nil
                            MainController.instance.routeDeepLink(link: link, error: nil)
                        }
                    }
                }
                else {
                    self.showGroupSwitcher() {
                        self.bootstrapping = false
                        if let link = MainController.instance.link {
                            Reporting.track("resume_invite")
                            MainController.instance.link = nil
                            MainController.instance.routeDeepLink(link: link, error: nil)
                        }
                    }
                }
            }
        }
        else {
            showChannel(channelId: channelId!, groupId: groupId!) {
                self.bootstrapping = false
            }
        }
    }

    func showLobby(controller: UIViewController? = nil, then: (() -> Void)? = nil) {
        
        /* If onboarding via invite, passed in controller is email form */
        Reporting.track("view_lobby")

        if StateController.instance.groupId != nil {
            StateController.instance.clearGroup()   // Make sure group and channel are both unset
        }
        
        let controller = controller ?? LobbyViewController()
        let wrapper = AirNavigationController(rootViewController: controller)
        
        if let emptyController = self.containerController.controller as? EmptyViewController {
            if !(controller is LobbyViewController) {
                emptyController.startScene() {
                    self.containerController.changeController(controller: wrapper)
                    then?()
                }
                return
            }
        }
        
        self.containerController.changeController(controller: wrapper)
        then?()
    }
    
    func showUserLobby(then: (() -> Void)? = nil) {
        
        Reporting.track("view_user_lobby")
        
        if StateController.instance.groupId != nil {
            StateController.instance.clearGroup()   // Make sure group and channel are both unset
        }
        
        let controller = UserLobbyController()
        let wrapper = AirNavigationController(rootViewController: controller)
        
        if let emptyController = self.containerController.controller as? EmptyViewController {
            emptyController.startScene() {
                self.containerController.changeController(controller: wrapper)
                then?()
            }
            return
        }
        
        self.containerController.changeController(controller: wrapper)
        then?()
    }
    
    func showGroupSwitcher(then: (() -> Void)? = nil) {
        Reporting.track("view_group_switcher")
        let controller = GroupSwitcherController()
        let wrapper = AirNavigationController(rootViewController: controller)
        self.containerController.changeController(controller: wrapper)
        then?()
    }
    
    func showMain(then: (() -> Void)? = nil) {
        
        if self.containerController.controller is SlideViewController {
            then?()
            return
        }
        
        let mainWrapper = AirNavigationController(navigationBarClass: AirNavigationBar.self, toolbarClass: nil)
        let mainBar = mainWrapper.navigationBar as! AirNavigationBar
        let menuController = SideMenuViewController()
        let drawerWrapper = AirNavigationController(navigationBarClass: AirNavigationBar.self, toolbarClass: nil)
        let drawerBar = drawerWrapper.navigationBar as! AirNavigationBar
        let channelSwitcher = ChannelSwitcherController()
        
        mainBar.navigationBarHeight = 54
        drawerBar.navigationBarHeight = UserDefaults.standard.bool(forKey: Prefs.statusBarHidden) ? 74 : 54

        let slideController = SlideViewController(mainViewController: mainWrapper
            , leftMenuViewController: drawerWrapper
            , rightMenuViewController: menuController)
        
        drawerWrapper.viewControllers = [channelSwitcher]
        drawerWrapper.view.backgroundColor = Theme.colorBackgroundTable
        
        if let emptyController = self.containerController.controller as? EmptyViewController,
            !emptyController.scenePlayed {
            emptyController.startScene() {
                self.containerController.changeController(controller: slideController)
                then?()
            }
            return
        }
        
        self.containerController.changeController(controller: slideController)
        then?()
    }

    func showChannel(channelId: String, groupId: String, then: (() -> Void)? = nil) {
        showMain {
            if let slide = self.containerController.controller as? SlideViewController {
                if let wrapper = slide.mainViewController as? AirNavigationController {
                    Reporting.track("view_channel")
                    let controller = ChannelViewController()
                    controller.inputGroupId = groupId
                    controller.inputChannelId = channelId
                    wrapper.setViewControllers([controller], animated: true)
                }
            }
            then?()
        }
    }

    func showEmpty(then: (() -> Void)? = nil) {
        showMain {
            if let wrapper = self.containerController.controller as? AirNavigationController {
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
        if UserController.instance.authenticated {
            let groupId = (link["group_id"] as! String)
            let userId = UserController.instance.userId!
            
            /* Must be group member or we get permission denied. Weirdly, we can get callbacks on with and withCancel
               when there is no membership record. So we have to use a flag to prevent double handling. */
            var inviteProcessing = false
            FireController.db.child("group-members/\(groupId)/\(userId)").observeSingleEvent(of: .value, with: { snap in
                guard !inviteProcessing else { return }
                inviteProcessing = true
                if let membership = snap.value as? [String: Any] {
                    /* Already a member */
                    let role = membership["role"] as? String
                    Reporting.track("process_invite")
                    self.processInvite(link: link, member: true, memberRole: role, flow: flow)
                }
                else {
                    /* Not a group member yet */
                    Reporting.track("process_invite")
                    self.processInvite(link: link, member: false, memberRole: nil, flow: flow)
                }
            }, withCancel: { error in
                /* Not a member yet */
                guard !inviteProcessing else { return }
                inviteProcessing = true
                Reporting.track("process_invite")
                self.processInvite(link: link, member: false, memberRole: nil, flow: flow)  // permission denied means not group member
            })
        }
        else {
            Reporting.track("pause_invite_for_login")
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
            var role = link["role"] as! String
            
            let isGroupMember = (memberRole != nil && memberRole! != "guest")
            if isGroupMember { // Retain full group member status even if invite role is guest.
                role = "member"
            }
            
            /* Check if already a member and not a channel invite */
            if isGroupMember && (channels == nil || channels!.count == 0) {
                if let topController = UIViewController.topMostViewController() {
                    let groupTitle = link["groupTitle"] as! String
                    let popup = PopupDialog(title: "Already a Member", message: "You are currently a member of the \(groupTitle) Patchr group!")
                    let button = DefaultButton(title: "OK") {
                        if flow == .onboardInvite {
                            Reporting.track("view_group_switcher")
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
                Reporting.track("cancel_invite")
                if StateController.instance.groupId == nil || StateController.instance.channelId == nil {
                    self.route()
                }
            }
            
            let joinButton = DefaultButton(title: "Join".uppercased(), height: 48) {
                Reporting.track("accept_invite")
                FireController.instance.addUserToGroup(groupId: groupId, channels: channels, role: role, inviteId: inviteId, invitedBy: inviterId) { [weak self] error, result in
                    guard let this = self else { return }
                    if error == nil {
                        if channels != nil {
                            this.afterChannelInvite(groupId: groupId, groupTitle: groupTitle, channels: channels)
                        } else {
                            this.afterGroupInvite(groupId: groupId, groupTitle: groupTitle)
                        }
                    }
                    else {
                        if let topController = UIViewController.topMostViewController() {
                            Reporting.track((error!.code == 404.2) ? "error_invite_used" : "error_invite_invalid")
                            let title = (error!.code == 404.2) ? "Used Invitation" : "Unusable Invitation"
                            let message = (error!.code == 404.2) ? "The invitation has already been used." : "The invitation has been used or revoked."
                            let popup = PopupDialog(title: title, message: message)
                            let button = DefaultButton(title: "OK") {
                                if flow == .onboardInvite {
                                    // If we don't have a current group|channel then we are in the lobby
                                    if StateController.instance.groupId == nil || StateController.instance.channelId == nil {
                                        this.route()
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
        
        FireController.instance.autoPickChannel(groupId: groupId, role: "member") { channelId in
            if channelId != nil {
                StateController.instance.setChannelId(channelId: channelId!, groupId: groupId)
                self.showChannel(channelId: channelId!, groupId: groupId)
                Utils.delay(1.0) {
                    if let topController = UIViewController.topMostViewController() {
                        let popup = PopupDialog(title: "Welcome!", message: "You are now a member of the \(groupTitle) Patchr group. Use the navigation drawer to discover and join channels.")
                        popup.buttonAlignment = .horizontal
                        let showButton = DefaultButton(title: "Show Me".uppercased(), height: 48) {
                            Reporting.track("invite_show_me")
                            if let slideController = self.window?.rootViewController as? SlideViewController {
                                slideController.openLeft()
                            }
                        }
                        let doneButton = DefaultButton(title: "Carry On".uppercased(), height: 48) {
                            Reporting.track("invite_carry_on")
                        }
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
        self.showChannel(channelId: channelId, groupId: groupId) { // User permissions are in place
            Utils.delay(0.5) {
                if let topController = UIViewController.topMostViewController() {
                    var message = "You have joined the #\(channelName) channel in the \(groupTitle) Patchr group. Use the message bar to send your first message."
                    if channels!.count > 1 {
                        message = "You have joined multiple channels in the \(groupTitle) Patchr group. Use the message bar to send your first message."
                    }
                    let popup = PopupDialog(title: "Welcome!", message: message)
                    popup.buttonAlignment = .horizontal
                    let showButton = DefaultButton(title: "Show Me".uppercased(), height: 48) {
                        Reporting.track("invite_show_me")
                        if let slideController = self.window?.rootViewController as? SlideViewController,
                            let wrapper = slideController.mainViewController as? AirNavigationController,
                            let channelController = wrapper.topViewController as? ChannelViewController {
                            channelController.textInputbar.textView.becomeFirstResponder()
                        }
                    }
                    let doneButton = DefaultButton(title: "Carry On".uppercased(), height: 48) {
                        Reporting.track("invite_carry_on")
                    }
                    popup.addButtons([showButton, doneButton])
                    topController.present(popup, animated: true)
                }
            }
        }
    }
    
    func checkCompatibility(then: ((Bool) -> Void)? = nil) {
        FireController.db.child("clients").child("ios").observeSingleEvent(of: .value, with: { snap in
            if let minVersion = snap.value as? Int {
                if !UIShared.versionIsValid(versionMin: Int(minVersion)) {
                    Reporting.track("version_update_required")
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
        Reporting.track("rate_prompted")
    }

    func iRateUserDidAttemptToRateApp() {
        Reporting.track("rate_attempted")
    }

    func iRateUserDidDeclineToRateApp() {
        Reporting.track("rate_declined")
    }

    func iRateUserDidRequestReminderToRateApp() {
        Reporting.track("rate_requested_reminder")
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
