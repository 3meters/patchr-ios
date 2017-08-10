/*
 * Firebase controller
 *
 * Provide convenience functionality when interacting with the Firebase database.
 */

import UIKit
import Keys
import AFNetworking
import iRate
import Firebase
import FirebaseDatabase
import Branch
import PopupDialog
import SDWebImage
import MBProgressHUD

class MainController: NSObject, iRateDelegate {

    static let instance = MainController()
    var progress: AirProgress?
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
            if compatible {
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
        UISwitch.appearance().onTintColor = Theme.colorTint
        
        UIApplication.shared.statusBarStyle = .default
        if UserDefaults.standard.bool(forKey: Prefs.statusBarHidden) {
            UIApplication.shared.isStatusBarHidden = true
        }
        
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = Theme.colorNavBarTint
        UINavigationBar.appearance().barTintColor = Theme.colorNavBarBackground
        
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
                    if let feature = params?["~feature"] as? String, feature.lowercased() == "textmetheapp" {
                        Reporting.track("install_via_website")
                        Log.d("App install using TextMeTheApp", breadcrumb: true)
                    }
                    else {
                        Log.d("Deep link routing based on clicked branch link", breadcrumb: true)
                        if !this.bootstrapping && this.link == nil {
                            this.routeDeepLink(link: params!, error: error)
                        }
                        else {
                            this.link = params!
                        }
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
        else if channelId == nil {
            showChannelsGrid() {
                self.bootstrapping = false
                if let link = MainController.instance.link {
                    Reporting.track("resume_invite")
                    MainController.instance.link = nil
                    MainController.instance.routeDeepLink(link: link, error: nil)
                }
            }
        }
        else {
            showChannel(channelId: channelId!) {
                self.bootstrapping = false
            }
        }
    }

    func showLobby(controller: UIViewController? = nil, then: (() -> Void)? = nil) {
        
        /* If onboarding via invite, passed in controller is email form */
        Reporting.track("view_lobby")

        if StateController.instance.channelId != nil {
            StateController.instance.clearChannel()   // Make sure channel is unset
        }
        
        let controller = controller ?? LobbyViewController()
        let wrapper = AirNavigationController(rootViewController: controller)
        wrapper.tag = "lobby"
        wrapper.removeStatusBarView()
        
        /* If empty controller is the root then animate scene before the switch */
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
    
    func showChannel(channelId: String, animated: Bool = false, then: (() -> Void)? = nil) {
        showChannelsGrid {
            if let channelsGrid = self.containerController.controller as? AirNavigationController {
                Reporting.track("view_channel")
                let controller = ChannelViewController(channelId: channelId)
                channelsGrid.pushViewController(controller, animated: animated)
            }
            then?()
        }
    }

    func showChannelsGrid(then: (() -> Void)? = nil) {
        
        if let controller = self.containerController.controller as? AirNavigationController {
            if controller.tag == nil || controller.tag != "lobby" {
                then?()
                return
            }
        }
        
        let channelsGrid = AirNavigationController(rootViewController: ChannelGridController(collectionViewLayout: UICollectionViewFlowLayout()))

        /* If transitioning from empty */
        if let emptyController = self.containerController.controller as? EmptyViewController,
            !emptyController.scenePlayed {
            emptyController.startScene() {
                self.containerController.changeController(controller: channelsGrid)
                then?()
            }
            return
        }
        else {
            self.containerController.changeController(controller: channelsGrid)
            then?()
        }
    }
    
    func routeDeepLink(link: [AnyHashable: Any], flow: Flow = .none, error: Error?) {
        /*
         * Logged in: open in channel
         * Not logged in: email -> username|password -> open channel
         */
        if UserController.instance.authenticated {
            
            guard let channelId = link["channel_id"] as? String
                , let userId = UserController.instance.userId else { return }
            
            /* Must be group member or we get permission denied. Weirdly, we can get callbacks on with and withCancel
               when there is no membership record. So we have to use a flag to prevent double handling. */
            var inviteProcessing = false
            FireController.db.child("channel-members/\(channelId)/\(userId)").observeSingleEvent(of: .value, with: { snap in
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
        
        let userId = UserController.instance.userId!
        let channelId = link["channel_id"] as! String
        let channelTitle = link["channel_title"] as! String
        let code = link["code"] as! String
        let role = link["role"] as! String
        
        let isChannelMember = (memberRole != nil)
        
        /* Check if already a member and not a channel invite */
        if isChannelMember {
            if let topController = UIViewController.topMostViewController() {
                let popup = PopupDialog(title: "Already a Member", message: "You are currently a member of the \(channelTitle) channel!")
                let button = DefaultButton(title: "OK") {
                    if flow == .onboardInvite {
                        StateController.instance.setChannelId(channelId: channelId)
                        self.showChannel(channelId: channelId)
                    }
                }
                button.buttonHeight = 48
                popup.addButton(button)
                topController.present(popup, animated: true)
            }
            return
        }
        else {
            FireController.instance.addUserToChannel(userId: userId, channelId: channelId, code: code, role: role) { [weak self] error, result in
                guard let this = self else { return }
                this.progress?.hide(true)
                if error == nil {
                    this.afterChannelInvite(channelId: channelId, channelTitle: channelTitle)
                }
                else {
                    if flow == .onboardInvite {
                        this.showChannelsGrid()
                    }
                    /* Otherwise leave the user at their current location */
                }
            }
        }
    }
    
    func afterChannelInvite(channelId: String, channelTitle: String) {
        
        StateController.instance.setChannelId(channelId: channelId)
        self.showChannel(channelId: channelId) { // User permissions are in place
            Utils.delay(0.5) {
                if let topController = UIViewController.topMostViewController() {
                    let popup = PopupDialog(title: "Welcome!", message: "You have joined the \(channelTitle) channel!")
                    let button = DefaultButton(title: "OK".uppercased(), height: 48) {
                        Reporting.track("invite_carry_on")
                    }
                    button.buttonHeight = 48
                    popup.addButton(button)
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
    case onboardSignup
    case onboardInvite
    case internalCreate
    case internalInvite
    case none
}
