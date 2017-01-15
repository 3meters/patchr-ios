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
    static let channelPicker = ChannelSwitcherController()
    static let groupPicker = GroupSwitcherController()

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
                    self?.routeDeepLink(link: params!, error: error)    /* Presents modally on top of main tab controller. */
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
            showLobby(controller: GroupSwitcherController())
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

    func routeDeepLink(link: [AnyHashable: Any], error: Error?) {
        /*
         * Logged in: open in channel
         * Not logged in: email -> username|password -> open channel
         */
        let groupId = (link["groupId"] as! String)
        var member = false
        var role = link["role"] as! String
        
        FireController.db.child("groups/\(groupId)").observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                
                if UserController.instance.authenticated {
                    let userId = UserController.instance.userId!
                    FireController.db.child("group-members/\(groupId)/\(userId)").observeSingleEvent(of: .value, with: { snap in
                        if !(snap.value is NSNull) {
                            let membership = snap.value as! [String: Any]
                            role = membership["role"] as! String
                            member = true
                            if role != "guest" {
                                if let topController = UIViewController.topMostViewController() {
                                    let groupTitle = link["groupTitle"] as! String
                                    let popup = PopupDialog(title: "Already a Member", message: "You are currently a member of the \(groupTitle) Patchr group!")
                                    let button = DefaultButton(title: "OK") {}
                                    button.buttonHeight = 48
                                    popup.addButton(button)
                                    topController.present(popup, animated: true)
                                }
                                return
                            }
                        }
                        
                        /* We only get here if not a member already or is a guest member */
                        
                        let inviteId = (link["inviteId"] as! String)
                        FireController.db.child("invites/\(groupId)")
                            .queryOrdered(byChild: "inviteId")
                            .queryEqual(toValue: inviteId)
                            .observeSingleEvent(of: .value, with: { snap in
                                if !(snap.value is NSNull) {
                                    /* invite exists for the email and group */
                                    let inviteWithKey = snap.value as! [String: Any]
                                    var invite = inviteWithKey.first?.value as! [String: Any]
                                    invite["key"] = inviteWithKey.first?.key
                                    self.processInvite(link: link, invite: invite, member: member)
                                }
                                else {
                                    /* invite does not exist for the email and group */
                                    if let topController = UIViewController.topMostViewController() {
                                        let popup = PopupDialog(title: "Expired Invitation", message: "Your invitation has expired or been revoked.")
                                        let button = DefaultButton(title: "OK") {}
                                        button.buttonHeight = 48
                                        popup.addButton(button)
                                        topController.present(popup, animated: true)
                                    }
                                }
                        })
                    })
                }
                else {
                    let controller = EmailViewController()
                    controller.flow = .onboardInvite
                    controller.inputInviteLink = link
                    self.showLobby(controller: controller)
                }
            }
            else {
                UIShared.Toast(message: "The \(link["groupTitle"]) Patchr group is not active")
            }
        })
    }
    
    func processInvite(link: [AnyHashable: Any], invite: [String: Any], member: Bool = false) {
        
        if let topController = UIViewController.topMostViewController() {
            
            let userId = UserController.instance.userId!
            let groupId = (link["groupId"] as! String)
            let email = (link["email"] as! String)
            let groupTitle = link["groupTitle"] as! String
            let referrerName = link["referrerName"] as! String
            
            /* Invite trumps link */
            let role = invite["role"] as! String
            let channels = invite["channels"] as? [String: Any]
            
            var message = "\(referrerName) has invited you to join the \"\(groupTitle)\" Patchr group."
            if channels != nil && channels!.count > 0 {
                if channels!.count > 1 {
                    message = "\(referrerName) has invited you to join these channels in the \(groupTitle) Patchr group.\n"
                    for channelName in channels!.values {
                        message += "\n#\(channelName)"
                    }
                }
                else {
                    let channelName = channels!.first!.value as! String
                    message = "\(referrerName) has invited you to join the #\(channelName) channel in the \(groupTitle) Patchr group."
                }
            }
            
            let popup = PopupDialog(title: "Invitation", message: message)
            
            let cancelButton = CancelButton(title: "Cancel".uppercased(), height: 48) {
                if StateController.instance.groupId == nil || StateController.instance.channelId == nil {
                    self.route() // If we don't have a currrent group|channel then we are in the lobby
                }
            }
            
            let joinButton = DefaultButton(title: "Join".uppercased(), height: 48) {
                if member && channels != nil {
                    FireController.instance.addUserToChannels(userId: userId, groupId: groupId, channels: channels!) { success in
                        if success {
                            self.afterInvite(groupId: groupId, groupTitle: groupTitle, channels: channels)
                        }
                    }
                    return
                }
                
                FireController.instance.addUserToGroup(userId: userId, groupId: groupId, channels: channels, role: role, email: email, then: { success in
                    if success {
                        if channels != nil {
                            self.afterInvite(groupId: groupId, groupTitle: groupTitle, channels: channels)
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
        }
    }
    
    func afterInvite(groupId: String, groupTitle: String, channels: [String: Any]?) {
        
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
