//
//  PatchDetailViewController.swift
//

import UIKit
import Branch
import MessageUI
import iRate
import IDMPhotoBrowser
import NHBalancedFlowLayout
import ReachabilitySwift

let UIActivityTypeGmail = "com.google.Gmail.ShareExtension"
let UIActivityTypeOutlook = "com.microsoft.Office.Outlook.compose-shareextension"
let UIActivityTypePatchr = "com.3meters.patchr.ios.PatchrShare"

class PatchDetailViewController: BaseDetailViewController {

    fileprivate var contextAction: ContextAction = .None
    fileprivate var originalRect: CGRect?
    fileprivate var originalScrollTop = CGFloat(-64.0)

    var actionButton: AirRadialMenu!
    var actionButtonCenter: CGPoint!
    var actionButtonAnimating = false
    var messageBar = UILabel()
    var messageBarTop = CGFloat(0)

    var lastContentOffset = CGFloat(0)
    var processing = false

    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        /*
        * Inputs are already available.
        */
        super.loadView()
        initialize()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.showEmptyLabel {
            self.emptyLabel.layer.borderWidth = 0
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
        let header = self.header as! PatchDetailView
        let viewHeight = (viewWidth * 0.625) + header.buttonGroup.height()
        self.tableView.tableHeaderView?.bounds.size = CGSize(width:viewWidth, height:viewHeight)    // Triggers layoutSubviews on header
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)        // calls bind if we have cached entity
        fetch(strategy: .UseCacheAndVerify, resetList: self.firstAppearance)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)    // Clears firstAppearance

        if self.actionButton != nil && self.entity != nil && (!self.entity!.lockedValue || isUserOwner()) {
            showActionButton()
        }

        iRate.sharedInstance().promptIfAllCriteriaMet()
        reachabilityChanged()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/

    override func photoAction(sender: AnyObject?) {
        super.photoAction(sender: sender)
        /* Stub to handle processing if we unify gallery browsing */
    }

    func watchersAction(sender: AnyObject) {
        let controller = UserTableViewController()
        controller.patch = self.entity as! Patch
        controller.filter = .PatchWatchers
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func photosAction(sender: AnyObject) {
        showPhotos()
    }

    func contextButtonAction(sender: UIButton) {
        if self.contextAction == .JoinPatch {
            watchAction()
        }
    }

    func mapAction(sender: AnyObject) {
        let controller = PatchMapViewController()
        controller.locationDelegate = self
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func dismissAction(sender: AnyObject) {
        self.dismiss(animated: true) {
            MainController.instance.route()
        }
    }

    func toggleAction(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }

    func addAction() {
        
        /* Has its own nav because we segue modally and it needs its own stack */
        let controller = MessageEditViewController()
//        controller.inputToString = self.entity!.name
//        controller.inputPatchId = self.entityId
//        controller.inputState = .Creating

        let navController = AirNavigationController()
        navController.viewControllers = [controller]

        self.present(navController, animated: true, completion: nil)
    }

    func editAction() {

        let controller = PatchEditViewController()
        controller.inputPatch = self.entity as? Patch

        let navController = AirNavigationController()
        navController.viewControllers = [controller]

        self.present(navController, animated: true, completion: nil)
    }

    func watchAction() {

        if self.entity == nil {
            return
        }

        let patch = self.entity as? Patch

        if patch!.userWatchStatusValue == .member {
            DataController.proxibase.deleteLinkById(linkID: patch!.userWatchId!) {
                response, error in

                OperationQueue.main.addOperation {
                    if let error = ServerError(error) {
                        UIViewController.topMostViewController()!.handleError(error)
                    }
                    else {
                        if DataController.instance.dataWrapperForResponse(response: response!) != nil {
                            patch!.userWatchId = nil
                            patch!.userWatchStatusValue = .nonMember
                            patch!.countWatchingValue -= 1
                            DataController.instance.activityDateWatching = Utils.now()
                        }
                        Reporting.track("Left Patch")
                        Log.d("Resetting patch and messages because watch status changed")
                        if UserDefaults.standard.bool(forKey: PatchrUserDefaultKey(subKey: "SoundEffects")) {
                            AudioController.instance.play(sound: Sound.pop.rawValue)
                        }
                        self.fetch(strategy: .IgnoreCache, resetList: true)
                    }
                }
            }
        }
        else if patch!.userWatchStatusValue == .pending {
            DataController.proxibase.deleteLinkById(linkID: patch!.userWatchId!) {
                response, error in

                OperationQueue.main.addOperation {
                    if let error = ServerError(error) {
                        UIViewController.topMostViewController()!.handleError(error)
                    }
                    else {
                        if DataController.instance.dataWrapperForResponse(response: response!) != nil {
                            patch!.userWatchId = nil
                            patch!.userWatchStatusValue = .nonMember
                        }
                        Reporting.track("Canceled Member Request")
                        Log.d("Resetting patch and messages because watch status changed")
                        if UserDefaults.standard.bool(forKey: PatchrUserDefaultKey(subKey: "SoundEffects")) {
                            AudioController.instance.play(sound: Sound.pop.rawValue)
                        }
                        self.fetch(strategy: .IgnoreCache, resetList: true)
                    }
                }
            }
        }
        else if patch!.userWatchStatusValue == .nonMember {
            /* Service automatically sets enabled = false if user is not the patch owner */
            DataController.proxibase.insertLink(fromID: ZUserController.instance.userId! as String, toID: patch!.id_, linkType: .Watch) {
                response, error in

                OperationQueue.main.addOperation {
                    if let error = ServerError(error) {
                        UIViewController.topMostViewController()!.handleError(error)
                    }
                    else {
                        if let serviceData = DataController.instance.dataWrapperForResponse(response: response!) {
                            if serviceData.countValue == 1 {
                                if let entityDictionaries = serviceData.data as? [[String:NSObject]] {
                                    let map = entityDictionaries[0]
                                    patch!.userWatchId = map["_id"] as! String
                                    if let enabled = map["enabled"] as? Bool {
                                        if enabled {
                                            patch!.userWatchStatusValue = .member
                                            patch!.countWatchingValue += 1
                                            DataController.instance.activityDateWatching = Utils.now()
                                            Reporting.track("Joined Patch")
                                        }
                                        else {
                                            patch!.userWatchStatusValue = .pending
                                            Reporting.track("Requested to Join Patch")
                                        }
                                    }
                                }
                            }
                        }
                        Log.d("Resetting patch and messages because watch status changed")
                        if UserDefaults.standard.bool(forKey: PatchrUserDefaultKey(subKey: "SoundEffects")) {
                            AudioController.instance.play(sound: Sound.pop.rawValue)
                        }
                        self.fetch(strategy: .IgnoreCache, resetList: true)

                        if !UIApplication.shared.isRegisteredForRemoteNotifications {
                            NotificationController.instance.guardedRegisterForRemoteNotifications(message: "Would you like to be alerted when messages are posted to this patch?")
                        }
                    }
                }
            }
        }
    }

    func muteAction() {

        if self.entity == nil {
            return
        }

        let muted = !self.entity!.userWatchMutedValue

        DataController.proxibase.muteLinkById(linkId: self.entity!.userWatchId!, muted: muted, completion: {
            response, error in

            OperationQueue.main.addOperation {
                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    self.entity!.userWatchMutedValue = muted
                    let header = self.header as! PatchDetailView
                    header.bindToEntity(entity: self.entity)
                    Reporting.track(muted ? "Muted Patch" : "Unmuted Patch")

                    if muted {
                        UIShared.Toast(message: "Notifications muted")
                    }

                    if !muted {
                        UIShared.Toast(message: "Notifications active")
                    }
                }
            }
        })
    }

    func shareAction(sender: AnyObject?) {

        if self.entity != nil {
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

            let patchr = UIAlertAction(title: "Invite using Patchr", style: .default) {
                action in
                self.shareUsing(route: .Patchr)
            }
            let facebook = UIAlertAction(title: "Invite using Facebook", style: .default) {
                action in
                self.shareUsing(route: .Facebook)
            }
            let airdrop = UIAlertAction(title: "AirDrop", style: .default) {
                action in
                self.shareUsing(route: .AirDrop)
            }
            let android = UIAlertAction(title: "More...", style: .default) {
                action in
                self.shareUsing(route: .Actions)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) {
                action in
                sheet.dismiss(animated: true, completion: nil)
            }

            sheet.addAction(patchr)
            sheet.addAction(facebook)
            sheet.addAction(airdrop)
            sheet.addAction(android)
            sheet.addAction(cancel)

            if let presenter = sheet.popoverPresentationController {
                if let button = sender as? UIBarButtonItem {
                    presenter.barButtonItem = button
                }
                else if let button = sender as? UIView {
                    presenter.sourceView = button;
                    presenter.sourceRect = button.bounds;
                }
            }

            present(sheet, animated: true, completion: nil)
        }
    }

    func moreAction(sender: AnyObject?) {

        if self.entity != nil {
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

            if isUserOwner() {
                let edit = UIAlertAction(title: "Edit patch", style: .default) {
                    action in
                    self.editAction()
                }
                sheet.addAction(edit)
            }

            let mute = UIAlertAction(title: self.entity!.userWatchMutedValue ? "Unmute patch" : "Mute patch", style: .default) {
                action in
                self.muteAction()
            }

            sheet.addAction(mute)

            if let patch = self.entity as? Patch {
                if patch.userWatchStatusValue == .member {
                    let leave = UIAlertAction(title: "Leave patch", style: .default) {
                        action in
                        self.watchAction()
                        Utils.delay(1.0) {
                            UIShared.Toast(message: "You have left this patch", controller: self, addToWindow: false)
                        }
                    }
                    sheet.addAction(leave)
                }
            }

            let cancel = UIAlertAction(title: "Cancel", style: .cancel) {
                action in
                sheet.dismiss(animated: true, completion: nil)
            }

            sheet.addAction(cancel)

            if let presenter = sheet.popoverPresentationController {
                if let button = sender as? UIBarButtonItem {
                    presenter.barButtonItem = button
                }
                else if let button = sender as? UIView {
                    presenter.sourceView = button;
                    presenter.sourceRect = button.bounds;
                }
            }

            present(sheet, animated: true, completion: nil)
        }
    }

    func sideMenuAction(sender: AnyObject?) {
        self.slideMenuController()?.openRight()
    }

    func joinAction(sender: AnyObject?) {
        watchAction() // Should trigger fetch via watch notification
    }

    func cancelRequestAction(sender: AnyObject?) {
        watchAction() // Should trigger fetch via watch notification
    }

    func loginAction(sender: AnyObject?) {
        let controller = LoginViewController()
        let navController = AirNavigationController()
        navController.viewControllers = [controller]
        controller.onboardMode = OnboardMode.Login
        controller.inputRouteToMain = false
        controller.source = "Invite"
        self.present(navController, animated: true) {
        }
    }

    func signupAction(sender: AnyObject?) {
        let controller = LoginViewController()
        let navController = AirNavigationController()
        navController.viewControllers = [controller]
        controller.onboardMode = OnboardMode.Signup
        controller.inputRouteToMain = false
        controller.source = "Invite"
        self.present(navController, animated: true) {
        }
    }

    func actionButtonTapped(gester: UIGestureRecognizer) {
        addAction()
        Animation.bounce(view: self.actionButton)
    }

    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    func didFetch(notification: NSNotification) {
        /*
         * Called after fetch is complete for form entity. bind() is called
         * just before this notification.
         */
        if ((notification.userInfo?["deleted"]) == nil) {
            if self.entity!.lockedValue {
                hideActionButton()
            }
            bindContextView()
        }
    }

    override func didFetchQuery(notification: NSNotification) {
        super.didFetchQuery(notification: notification)
    }

    func didInsertMessage(sender: NSNotification) { }

    func didReceiveRemoteNotification(notification: NSNotification) {
        let data = notification.userInfo!
        if self.isViewLoaded {
            if let parentId = data["parentId"] as? String , parentId == self.entityId {
                self.pullToRefreshAction(sender: self.refreshControl)
            }
            else if let targetId = data["targetId"] as? String , targetId == self.entityId {
                self.pullToRefreshAction(sender: self.refreshControl)
            }
        }
    }

    func applicationDidEnterBackground(sender: NSNotification) { }

    func applicationWillEnterForeground(sender: NSNotification) {
        /* User either switched to patchr or turned their screen back on. */
        reachabilityChanged()
    }

    func reachabilityChanged() {
        if ReachabilityManager.instance.isReachable() {
            hideMessageBar()
        }
        else {
            showMessageBar()
        }
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    func initialize() {

        Reporting.screen("PatchDetail")

        self.queryName = DataStoreQueryName.MessagesForPatch.rawValue

        self.header = PatchDetailView()
        self.tableView = AirTableView(frame: self.tableView.frame, style: .plain)

        let header = self.header as! PatchDetailView

        header.membersButton.addTarget(self, action: #selector(PatchDetailViewController.watchersAction(sender:)), for: UIControlEvents.touchUpInside)
        header.photosButton.addTarget(self, action: #selector(PatchDetailViewController.photosAction(sender:)), for: UIControlEvents.touchUpInside)

        if let contextButton = header.contextButton as? AirFeaturedButton {
            contextButton.addTarget(self, action: #selector(PatchDetailViewController.contextButtonAction(sender:)), for: .touchUpInside)
            contextButton.setTitle("", for: .normal)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(PatchDetailViewController.didReceiveRemoteNotification(notification:)), name: NSNotification.Name(rawValue: Events.DidReceiveRemoteNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PatchDetailViewController.didFetch(notification:)), name: NSNotification.Name(rawValue: Events.DidFetch), object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(PatchDetailViewController.didInsertMessage(sender:)), name: NSNotification.Name(rawValue: Events.DidInsertMessage), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PatchDetailViewController.reachabilityChanged), name: ReachabilityChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PatchDetailViewController.applicationDidEnterBackground(sender:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PatchDetailViewController.applicationWillEnterForeground(sender:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

        self.showEmptyLabel = true
        self.showProgress = true
        self.progressOffsetY = 80
        self.loadMoreMessage = "LOAD MORE MESSAGES"

        /* UI prep */
        self.patchNameVisible = false

        /* Message bar */
        self.messageBar.font = Theme.fontTextDisplay
        self.messageBar.text = "Connection is offline"
        self.messageBar.numberOfLines = 0
        self.messageBar.textAlignment = NSTextAlignment.center
        self.messageBar.textColor = Colors.white
        self.messageBar.layer.backgroundColor = Colors.accentColorFill.cgColor
        self.messageBar.alpha = 0.0
        
        /* Action button */
        self.actionButton = AirRadialMenu(attachedToView: self.view)
        self.actionButton.bounds.size = CGSize(width:56, height:56)
        self.actionButton.autoresizingMask = [.flexibleRightMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleTopMargin]
        self.actionButton.centerView.gestureRecognizers?.forEach(self.actionButton.centerView.removeGestureRecognizer) /* Remove default tap regcognizer */
        self.actionButton.imageInsets = UIEdgeInsetsMake(14, 14, 14, 14)
        self.actionButton.imageView.image = UIImage(named: "imgAddLight")    // Default
        self.actionButton.showBackground = false
        self.actionButton.centerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(actionButtonTapped(gester:))))
        self.actionButton!.transform = CGAffineTransform.identity
        
        self.view.insertSubview(self.actionButton, at: self.view.subviews.count)
        
        self.actionButton.anchorBottomRight(withRightPadding: 16, bottomPadding: 0, width: self.actionButton!.width(), height: self.actionButton!.height())
        self.actionButtonCenter = self.actionButton.center

        /* Navigation bar buttons */
        drawNavBarButtons()
    }

    override func bind() {

        if let patch = self.entity as? Patch {
            self.disableCells = (patch.visibility == "private" && !patch.userIsMember())

            let header = self.header as! PatchDetailView

            /* We do this here so we have tableView sizing */
            if self.tableView.tableHeaderView == nil {
                let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
                let viewHeight = (viewWidth * 0.625) + 48
                header.frame = CGRect(x:0, y:0, width:viewWidth, height:viewHeight)
                header.setNeedsLayout()
                header.layoutIfNeeded()
                header.photo.frame = CGRect(x:-24, y:-36, width:header.bannerGroup.width() + 48, height: header.bannerGroup.height() + 72)
                self.originalRect = header.photo.frame
                self.tableView.tableHeaderView = self.header
                self.tableView.reloadData()
            }

            bindContextView()
            header.bindToEntity(entity: patch)

            if patch.userWatchStatusValue == .member {
                self.emptyMessage = "Be the first to post a message to this patch"
            }
            else {
                self.emptyMessage = (patch.visibility == "private") ? "Only members can see messages" : "Be the first to post a message to this patch"
            }

            self.emptyLabel.setTitle(self.emptyMessage, for: .normal)
        }
    }

    override func drawNavBarButtons() {

        var button = UIButton(type: .custom)
        button.frame = CGRect(x:0, y:0, width:36, height:36)
        button.addTarget(self, action: #selector(PatchDetailViewController.sideMenuAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgOverflowLight"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);

        let moreButton = UIBarButtonItem(customView: button)
        
        /* Channel indicator */
        button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(PatchDetailViewController.moreAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setTitleColor(Colors.black, for: .normal)
        button.titleLabel!.font = UIFont.fontAwesome(ofSize: 16)
        
        if let patch = self.entity as? Patch {
            if patch.visibility != nil && patch.visibility == "public" {
                button.setTitle(String.fontAwesomeIcon(name: .hashtag), for: .normal)
            }
            else {
                button.setTitle(String.fontAwesomeIcon(name: .lock), for: .normal)
            }
            button.sizeToFit()
            button.bounds.size.width = 16
        }
        
        let channelButton = UIBarButtonItem(customView: button)

        /* Title button */
        button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(PatchDetailViewController.moreAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setTitleColor(Colors.black, for: .normal)
        button.titleLabel!.font = Theme.fontTextBold

        if let patch = self.entity as? Patch {
            button.setTitle(patch.name.lowercased().replacingOccurrences(of: " ", with: "-"), for: .normal)
            button.sizeToFit()
        }

        let titleButton = UIBarButtonItem(customView: button)

        /* Dropdown button */
        button = UIButton(type: .custom)
        button.frame = CGRect(x:0, y:0, width:30, height:30)
        button.addTarget(self, action: #selector(PatchDetailViewController.moreAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgDropdown3Light"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 6, 16);

        let dropdownButton = UIBarButtonItem(customView: button)

        /* Navigation button */
        button = UIButton(type: .custom)
        button.frame = CGRect(x:0, y:0, width:36, height:36)
        button.addTarget(self, action: #selector(PatchDetailViewController.toggleAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgNavigationLight"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 0, 8, 16);

        let navButton = UIBarButtonItem(customView: button)

        self.navigationItem.setLeftBarButtonItems([navButton, Utils.spacer, channelButton, titleButton, dropdownButton], animated: true)
        self.navigationItem.setRightBarButtonItems([moreButton], animated: true)
    }

    func hideActionButton() {
        if !self.actionButtonAnimating && self.actionButton != nil {
            self.actionButtonAnimating = true
            self.actionButton!.scaleOut() {
                finished in
                self.actionButtonAnimating = false
            }
        }
    }

    func showActionButton() {
        if !self.actionButtonAnimating && self.actionButton != nil {
            self.actionButtonAnimating = true
            self.actionButton!.scaleIn() {
                finished in
                self.actionButtonAnimating = false
            }
        }
    }

    func bindContextView() {

        let originalContextAction = self.contextAction

        if let patch = self.entity as? Patch {
            let header = self.header as! PatchDetailView

            if !(header.contextButton is UIButton) {
                header.contextButton.removeFromSuperview()
                header.contextButton = AirFeaturedButton()
                header.buttonGroup.addSubview(header.contextButton)
            }

            if let button = header.contextButton as? UIButton {
                
                self.contextAction = .None
                
                if patch.userWatchStatusValue != .member {
                    button.setTitle("Join".uppercased(), for: .normal)
                    self.contextAction = .JoinPatch
                }

                if self.contextAction != originalContextAction {
                    if (self.contextAction == .None || originalContextAction == .None) {
                        button.isHidden = (self.contextAction == .None)

                        if self.tableView.tableHeaderView != nil {
                            let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
                            let viewHeight = (viewWidth * 0.625) + (self.contextAction == .None ? 44 : 100)
                            self.tableView.tableHeaderView!.frame = CGRect(x:0, y:0, width:viewWidth, height:viewHeight)
                        }
                    }
                }
            }
        }
    }

    func showPhotos() {

        /* Cherry pick display photos */
        var displayPhotos = [String: DisplayPhoto]()

        for item in self.query.queryItems {
            let queryItem = item as! QueryItem
            let entity = queryItem.object as! Entity
            if entity.photo != nil {
                let displayPhoto = DisplayPhoto.fromEntity(entity: entity)
                displayPhotos[displayPhoto.entityId!] = displayPhoto
            }
        }

        let navController = AirNavigationController()
        let layout = NHBalancedFlowLayout()
        layout.preferredRowSize = 200
        let controller = GalleryGridViewController(collectionViewLayout: layout)
        controller.displayPhotos = displayPhotos
        navController.viewControllers = [controller]
        self.navigationController!.present(navController, animated: true, completion: nil)
    }

    func shareUsing(route: ShareRoute) {

        if route == .Patchr {
            let controller = MessageEditViewController()
            let navController = AirNavigationController()
//            controller.inputShareEntity = self.entity
//            controller.inputShareSchema = Schema.ENTITY_PATCH
//            controller.inputShareId = self.entityId!
//            controller.inputMessageType = .Share
//            controller.inputState = .Sharing
            navController.viewControllers = [controller]
            self.present(navController, animated: true, completion: nil)
        }
        else if route == .AirDrop {
            BranchProvider.invite(entity: self.entity as! Patch, referrer: ZUserController.instance.currentUser) {
                response, error in

                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    let patch = response as! PatchItem
                    let excluded = [
                            UIActivityType.postToTwitter,
                            UIActivityType.postToFacebook,
                            UIActivityType.postToWeibo,
                            UIActivityType.message,
                            UIActivityType.mail,
                            UIActivityType.print,
                            UIActivityType.copyToPasteboard,
                            UIActivityType.assignToContact,
                            UIActivityType.saveToCameraRoll,
                            UIActivityType.addToReadingList,
                            UIActivityType.postToFlickr,
                            UIActivityType.postToVimeo,
                            UIActivityType.postToTencentWeibo
                    ]

                    let activityViewController = UIActivityViewController(
                            activityItems: [patch, NSURL.init(string: patch.shareUrl, relativeTo: nil)!],
                            applicationActivities: nil)

                    activityViewController.completionWithItemsHandler = {
                        activityType, completed, items, activityError in
                        if completed && activityType != nil {
                            Reporting.track("Sent Patch Invitation", properties: ["network": activityType! as AnyObject])
                        }
                    }

                    activityViewController.excludedActivityTypes = excluded

                    if UIDevice.current.userInterfaceIdiom == .phone {
                        self.present(activityViewController, animated: true, completion: nil)
                    }
                    else {
                        let popup: UIPopoverController = UIPopoverController(contentViewController: activityViewController)
                        popup.present(from: CGRect(x:self.view.frame.size.width / 2, y:self.view.frame.size.height / 4, width:0, height:0), in: self.view, permittedArrowDirections: UIPopoverArrowDirection.any, animated: true)
                    }
                }
            }
        }
        else if route == .Actions {
            BranchProvider.invite(entity: self.entity as! Patch, referrer: ZUserController.instance.currentUser) {
                response, error in

                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    let patch = response as! PatchItem
                    let excluded = [
                            UIActivityType.airDrop
                    ]

                    let activityViewController = UIActivityViewController(
                            activityItems: [patch, NSURL.init(string: patch.shareUrl, relativeTo: nil)!],
                            applicationActivities: nil)

                    activityViewController.completionWithItemsHandler = {
                        activityType, completed, items, activityError in
                        if completed && activityType != nil {
                            Reporting.track("Sent Patch Invitation", properties: ["network": activityType! as AnyObject])
                        }
                    }

                    activityViewController.excludedActivityTypes = excluded

                    if UIDevice.current.userInterfaceIdiom == .phone {
                        self.present(activityViewController, animated: true, completion: nil)
                    }
                    else {
                        let popup: UIPopoverController = UIPopoverController(contentViewController: activityViewController)
                        popup.present(from: CGRect(x:self.view.frame.size.width / 2, y:self.view.frame.size.height / 4, width:0, height:0), in: self.view, permittedArrowDirections: UIPopoverArrowDirection.any, animated: true)
                    }
                }
            }
        }
    }

    func showMessageBar() {
        self.view.insertSubview(self.messageBar, at: self.view.subviews.count)
        self.messageBar.anchorTopCenter(withTopPadding: 0, width: self.view.width(), height: 40)
        self.messageBarTop = self.messageBar.frame.origin.y
        UIView.animate(withDuration: 0.10,
                                   delay: 0,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: {
                                       self.messageBar.alpha = 1
                                   }) { _ in
            Animation.bounce(view: self.messageBar)
        }
    }

    func hideMessageBar() {
        UIView.animate(withDuration: 0.30,
                                   delay: 0,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: {
                                       self.messageBar.alpha = 0
                                   }) { _ in
            self.messageBar.removeFromSuperview()
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Properties
    *--------------------------------------------------------------------------------------------*/

    func isUserOwner() -> Bool {
        if let currentUser = ZUserController.instance.currentUser, let entity = self.entity {
            return currentUser.id_ == entity.creator?.entityId
        }
        return false
    }
}

extension PatchDetailViewController: MapViewDelegate {
    func locationForMap() -> CLLocation? {
        if let location = self.entity?.location {
            return location.cllocation
        }
        return nil
    }

    func locationChangedTo(location: CLLocation) {
    }

    func locationEditable() -> Bool {
        return false
    }

    var locationTitle: String? {
        get {
            return self.entity?.name
        }
    }

    var locationSubtitle: String? {
        get {
            if self.entity?.type != nil {
                return "\(self.entity!.type!.uppercased()) PATCH"
            }
            return "PATCH"
        }
    }

    var locationPhoto: AnyObject? {
        get {
            return self.entity?.photo
        }
    }
}

extension PatchDetailViewController {
    override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
        super.bindCellToEntity(cell: cell, entity: entity, location: location)
        cell.isHidden = self.disableCells
    }
}

extension PatchDetailViewController {
    /*
     * UITableViewDelegate
     */
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {

        guard self.entity != nil else {
            return
        }
        
        self.actionButton.center.y = self.actionButtonCenter.y + scrollView.contentOffset.y
        
        if self.messageBar.alpha > 0.0 {
            self.messageBar.frame.origin.y = scrollView.contentOffset.y + 64 // TODO: Fragile if status and navigation bar don't match this
        }

        if scrollView.contentSize.height > scrollView.height() {
            if (self.lastContentOffset > scrollView.contentOffset.y)
                    && self.lastContentOffset < (scrollView.contentSize.height - scrollView.frame.height) {
                showActionButton()
            }
            else if (self.lastContentOffset < scrollView.contentOffset.y
                    && scrollView.contentOffset.y > 0) {
                hideActionButton()
            }
        }

        self.lastContentOffset = scrollView.contentOffset.y

        let header = self.header as! PatchDetailView

        /* Parallax effect when user scrolls down */
        let offset = scrollView.contentOffset.y
        if offset >= self.originalScrollTop && offset <= 300 {
            let movement = self.originalScrollTop - scrollView.contentOffset.y
            let ratio: CGFloat = (movement <= 0) ? 0.50 : 1.0
            header.photo.frame.origin.y = self.originalRect!.origin.y + (-(movement) * ratio)
        }
        else {
            let movement = (originalScrollTop - scrollView.contentOffset.y) * 0.35
            if movement > 0 {
                header.photo.frame.origin.y = self.originalRect!.origin.y - (movement * 0.5)
                header.photo.frame.origin.x = self.originalRect!.origin.x - (movement * 0.5)
                header.photo.frame.size.width = self.originalRect!.size.width + movement
                header.photo.frame.size.height = self.originalRect!.size.height + movement
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
}

class PatchItem: NSObject, UIActivityItemSource {

    var entity: Patch
    var shareUrl: String

    init(entity: Patch, shareUrl: String) {
        self.entity = entity
        self.shareUrl = shareUrl
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        /* Called before the share actions are displayed */
        return ""
    }

    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivityType?, suggestedSize size: CGSize) -> UIImage? {
        /* Not currently called by any of the share extensions I could test. */
        return nil
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        let text = "\(ZUserController.instance.currentUser.name) has invited you to the \(self.entity.name) patch!"
        return text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        /*
         * Outlook: Doesn't call this.
         * Gmail constructs their own using the value from itemForActivityType
         * Apple email calls this.
         * Apple message calls this (I believe as an alternative if nothing provided via itemForActivityType).
         */
        if activityType == UIActivityType.mail {
            return "Invitation to the \(self.entity.name) patch"
        }
        return ""
    }
}

private enum ShareButtonFunction {
    case Share
    case ShareFacebook
    case ShareVia
}

private enum ActionButtonFunction {
    case Leave
    case Report
}

enum ContextAction: UInt {
    case None
    case BrowseUsersWatching
    case SharePatch
    case CreateMessage
    case JoinPatch
    case SubmitJoinRequest
    case CancelJoinRequest
}
