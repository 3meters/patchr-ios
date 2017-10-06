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
import Localize_Swift
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
    var channelQuery: ChannelQuery?

    private override init() { }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Notifications
    *--------------------------------------------------------------------------------------------*/

    @objc func stateInitialized(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.StateInitialized), object: nil)
        Log.d("State initialized - app state: \(Config.appState())")
        checkCompatibility() { compatible in
            if compatible {
                self.launchUI()
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
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: Theme.fontBarText], for: UIControlState.normal)
        self.window?.backgroundColor = Theme.colorBackgroundWindow
        self.window?.tintColor = Theme.colorTint
        UISwitch.appearance().onTintColor = Theme.colorTint
        
        UIApplication.shared.statusBarStyle = .default
        UIApplication.shared.isStatusBarHidden = true
        UIApplication.shared.isStatusBarHidden = false
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
        buttonAppearance.buttonHeight = 48
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

        NotificationCenter.default.addObserver(self, selector: #selector(bindLanguage), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stateInitialized(notification:)), name: NSNotification.Name(rawValue: Events.StateInitialized), object: nil)
    }
    
    @objc func bindLanguage() {
        /* Update language in user profile */
        let userId = UserController.instance.userId!
        let language = Localize.currentLanguage()
        var updates = [String: Any]()
        updates["language"] = language
        Reporting.track("update_language")
        FireController.db.child("users/\(userId)/profile").updateChildValues(updates)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.UserDidUpdate), object: self, userInfo: ["user_id": userId])

        iRate.sharedInstance().appStoreCountry = Localize.currentLanguage()
        iRate.sharedInstance().message = "irate_app_message".localized()
        iRate.sharedInstance().cancelButtonLabel = "irate_cancel_button".localized()
        iRate.sharedInstance().messageTitle = "irate_message_title".localized()
        iRate.sharedInstance().rateButtonLabel = "irate_rate_button".localized()
        iRate.sharedInstance().remindButtonLabel = "irate_remind_button".localized()
    }

    func launchUI() {
        
        /* ContainerController is currently showing EmptyViewController or a 
           deep stack with presented NavigationController wrapping
           SettingsTableViewController on top (logout) */
        
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
            if let wrapper = self.containerController.controller as? AirNavigationController {
                Reporting.track("view_channel")
                let controller = ChannelViewController(channelId: channelId)
                wrapper.pushViewController(controller, animated: animated)
            }
            then?()
        }
    }

    func showChannelsGrid(then: (() -> Void)? = nil) {
        
        if let controller = self.containerController.controller as? AirNavigationController {
            if controller.tag == nil || controller.tag != "lobby" {
                Log.v("Inferred that channels grid already exists based on controller.tag")
                then?()
                return
            }
        }
        
        let channelsGrid = ChannelGridController(collectionViewLayout: UICollectionViewLayout())
        let wrapper = AirNavigationController(rootViewController: channelsGrid)
        Log.v("Creating channels grid")

        /* If transitioning from empty */
        if let emptyController = self.containerController.controller as? EmptyViewController,
            !emptyController.scenePlayed {
            emptyController.startScene() {
                self.containerController.changeController(controller: wrapper)
                then?()
            }
            return
        }
        else {
            self.containerController.changeController(controller: wrapper)
            then?()
        }
    }
    
    func routeDeepLink(link: [AnyHashable: Any], flow: Flow = .none, error: Error?) {
        /*
         * Logged in: open in channel
         * Not logged in: email -> username|password -> open channel
         */
        if UserController.instance.authenticated {
            processInvite(link: link, flow: flow)
        }
        else {
            Reporting.track("pause_invite_for_login")
            let controller = EmailViewController()
            controller.flow = .onboardInvite
            controller.inputInviteLink = link
            self.showLobby(controller: controller)
        }
    }
    
    func processInvite(link: [AnyHashable: Any], flow: Flow) {
        
        guard let channelId = link["channel_id"] as? String
            , let userId = UserController.instance.userId else { return }
        let channelTitle = link["channel_title"] as! String
        let code = link["code"] as! String
        let role = link["role"] as! String
        
        Reporting.track("process_invite")
        
        FireController.instance.addUserToChannel(userId: userId
            , channelId: channelId
            , code: code
            , role: role) { [weak self] error, result in
                
            guard let this = self else { return }
            this.progress?.hide(true)
            if error == nil {
                this.afterInvite(channelId: channelId, channelTitle: channelTitle)
            }
            else { // Channel is gone or channel secret is bad
                if let topController = UIViewController.topController {
                    let popup = PopupDialog(title: "channel_missing_title".localized()
                        , message: "channel_missing_message".localizedFormat(channelTitle))
                    let button = DefaultButton(title: "ok".localized().uppercased(), height: 48) {
                        Reporting.track("invite_channel_missing")
                        /* Leave the user at their current location unless onboarding */
                        if flow == .onboardInvite {
                            this.showChannelsGrid()
                        }
                    }
                    popup.addButton(button)
                    topController.present(popup, animated: true)
                }
            }
        }
    }
    
    func afterInvite(channelId: String, channelTitle: String) {
        
        StateController.instance.setChannelId(channelId: channelId)
        self.showChannel(channelId: channelId) { // User permissions are in place
            Utils.delay(0.5) {
                if let topController = UIViewController.topController {
                    let popup = PopupDialog(title: "channel_joined_title".localized()
                        , message: "channel_joined_message".localizedFormat(channelTitle))
                    let button = DefaultButton(title: "ok".localized().uppercased(), height: 48) {
                        Reporting.track("invite_carry_on")
                    }
                    popup.addButton(button)
                    topController.present(popup, animated: true)
                    if UserDefaults.standard.bool(forKey: PerUserKey(key: Prefs.soundEffects)) {
                        AudioController.instance.play(sound: Sound.greeting.rawValue)
                    }
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
    case onboardLogin // Entering app via login
    case onboardSignup // Entering app via signup
    case onboardInvite // Login/signup triggered by invite
    case internalCreate // Authenticated user is creating a new channel
    case none
}
