//
//  ChanneliewController.swift
//

import UIKit
import MessageUI
import iRate
import IDMPhotoBrowser
import NHBalancedFlowLayout
import ReachabilitySwift
import Firebase
import FirebaseDatabaseUI
import TTTAttributedLabel
import SlideMenuControllerSwift

class ChannelViewController: BaseSlackController, SlideMenuControllerDelegate {
    
    var inputChannelId: String?
    var inputGroupId: String?
    
    var queryChannel: ChannelQuery?
    var queryUnread: UnreadQuery?   // Used to know when channel unreads == 0 and should fix sort priority
    
    var headerView = ChannelDetailView()
    var unreads = [String: Bool]()
    var displayPhotos = [String: DisplayPhoto]()
    var displayPhotosArray : [DisplayPhoto]!

    var headerHeight: CGFloat!

    var messageBar = UILabel()
    var messageBarTop = CGFloat(0)
    var joinBar = UIView()
    var joinBarLabel = AirLabel()
    var joinBarButton = AirFeaturedButton()
    
    var titleView: ChannelTitleView!
    var navButton: UIBarButtonItem!
    var titleButton: UIBarButtonItem!
    
    var viewIsVisible = false

    /* Only used for row sizing */
    var rowHeights: NSMutableDictionary = [:]
    var itemTemplate = MessageViewCell()
    var itemPadding	= UIEdgeInsetsMake(12, 12, 12, 12)
    
    /* Observes typers for channel. If we see typers (but not this user), we 
       pass them to the typing indicator. Each user passed to the typing
       indicator has an attached timer that removes it after 8 seconds. */
    var typingRef: FIRDatabaseReference!
    var typingAddHandle: FIRDatabaseHandle!
    var typingRemoveHandle: FIRDatabaseHandle!
    var typingTask: DispatchWorkItem?
    var localTyping = false // Setting add/removes this user from channel typers
    var isTyping: Bool {
        get {
            return self.localTyping
        }
        set {
            self.localTyping = newValue
            if !self.textInputbar.isEditing {   // Only use indicator if not editing
                if let username = UserController.instance.user?.username {
                    let userId = UserController.instance.userId!
                    if self.localTyping {
                        self.typingRef.child(userId).setValue(username)
                    }
                    else {
                        self.typingRef.child(userId).removeValue()
                    }
                }
            }
        }
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Lifecycle
     *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        bind(groupId: self.inputGroupId!, channelId: self.inputChannelId!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.slideMenuController()?.delegate = self        
        if UserController.instance.userId != nil && StateController.instance.groupId == nil {
            let controller = GroupSwitcherController()
            let wrapper = AirNavigationController()
            wrapper.viewControllers = [controller]
            self.present(wrapper, animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewIsVisible = (self.slideMenuController() != nil && !self.slideMenuController()!.isLeftOpen())
        iRate.sharedInstance().promptIfAllCriteriaMet()
        reachabilityChanged()
        if let link = MainController.instance.link {
            MainController.instance.routeDeepLink(link: link, error: nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewIsVisible = false
        self.isTyping = false
    }
    
    override func viewWillLayoutSubviews() {
        
        let viewWidth = min(Config.contentWidthMax, self.view.width())
        self.view.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: self.view.height())
        
        super.viewWillLayoutSubviews()
        
        self.tableView.fillSuperview()
        
        if self.messageBar.alpha > 0.0 {
            self.messageBar.alignUnder(self.navigationController?.navigationBar, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 40)
        }
        
        if self.joinBar.alpha > 0.0 {
            self.joinBar.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 88)
            self.joinBarButton.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 8, bottomPadding: 8, height: 48)
            self.joinBarLabel.anchorTopCenterFillingWidth(withLeftAndRightPadding: 8, topPadding: 0, height: 32)
        }
        
        self.titleView.bounds.size.width = self.view.width() - 160
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        Log.w("Patchr received memory warning: clearing memory image cache")
        SDImageCache.shared().clearMemory()
    }
    
    deinit {
        Log.d("ChannelViewController released")
        if self.typingAddHandle != nil {
            self.typingRef.removeObserver(withHandle: self.typingAddHandle)
        }
        if self.typingRemoveHandle != nil {
            self.typingRef.removeObserver(withHandle: self.typingRemoveHandle)
        }
        self.queryChannel?.remove()
        self.queryUnread?.remove()
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Events
     *--------------------------------------------------------------------------------------------*/

    func openGalleryAction(sender: AnyObject) {
        showPhotos(mode: .gallery)
    }
    
    func openNavigationAction(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }
    
    func openMenuAction(sender: AnyObject?) {
        self.slideMenuController()?.openRight()
    }
    
    func browseMemberAction(sender: AnyObject?) {
        if let photoControl = sender as? PhotoControl {
            if let user = photoControl.target as? FireUser {
                let controller = MemberViewController()
                controller.inputUserId = user.id
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    func browsePhotoAction(sender: AnyObject?) {

        if let recognizer = sender as? UITapGestureRecognizer,
            let control = recognizer.view as? AirImageView,
            let url = control.fromUrl {
            showPhotos(mode: .browse, fromView: control, initialUrl: url)
        }
    }
    
    func deleteMessageAction(message: FireMessage) {
        DeleteConfirmationAlert(
            title: "Confirm Delete",
            message: "Are you sure you want to delete this?",
            actionTitle: "Delete", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    let groupId = self.channel.groupId!
                    let channelId = message.channelId!
                    let messageId = message.id!
                    FireController.instance.deleteMessage(messageId: messageId, channelId: channelId, groupId: groupId)
                }
        }
    }

    func editChannelAction() {
        let controller = ChannelEditViewController()
        let wrapper = AirNavigationController()
        controller.mode = .update
        controller.inputChannelId = self.channel.id
        controller.inputGroupId = self.channel.groupId
        wrapper.viewControllers = [controller]
        self.present(wrapper, animated: true, completion: nil)
    }
    
    func joinChannelAction(sender: AnyObject?) {
        let groupId = StateController.instance.groupId!
        let channelId = self.channel.id!
        let channelName = self.channel.name!
        let userId = UserController.instance.userId!
        FireController.instance.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName, then: { success in
            if success {
                UIShared.toast(message: "You have joined this channel")
                if UserDefaults.standard.bool(forKey: PerUserKey(key: Prefs.soundEffects)) {
                    AudioController.instance.play(sound: Sound.pop.rawValue)
                }
            }
        })
    }

    func leaveChannelAction(sender: AnyObject?) {
        
        if self.channel.visibility == "private" {
            DeleteConfirmationAlert(
                title: "Confirm",
                message: "Are you sure you want to leave this private channel? A new invitation is required to rejoin.",
                actionTitle: "Leave", cancelTitle: "Cancel", delegate: self) { doIt in
                    if doIt {
                        if let group = StateController.instance.group {
                            let userId = UserController.instance.userId!
                            let channelName = self.channel.name!
                            FireController.instance.removeUserFromChannel(userId: userId, groupId: group.id!, channelId: self.channel.id!, channelName: channelName, then: { success in
                                if success {
                                    /* Close and switch to accessible channel */
                                    self.dismiss(animated: true, completion: nil)
                                    UIShared.toast(message: "You have left this channel.")
                                    StateController.instance.clearChannel()
                                }
                            })
                        }
                    }
            }
        }
        else {
            if let group = StateController.instance.group {
                let userId = UserController.instance.userId!
                let channelName = self.channel.name!
                FireController.instance.removeUserFromChannel(userId: userId, groupId: group.id!, channelId: self.channel.id!, channelName: channelName, then: { success in
                    if success {
                        UIShared.toast(message: "You have left this channel.")
                        if UserDefaults.standard.bool(forKey: PerUserKey(key: Prefs.soundEffects)) {
                            AudioController.instance.play(sound: Sound.pop.rawValue)
                        }
                    }
                })
            }
        }
    }

    func longPressAction(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            let point = sender.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: point) {
                dismissKeyboard(true)
                let cell = self.tableView.cellForRow(at: indexPath) as! WrapperTableViewCell
                let snap = self.queryController.snapshot(at: indexPath.row)
                let message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key)
                showMessageActions(message: message!, sourceView: cell.view)
            }
        }
    }
    
    func leftWillOpen() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.LeftWillOpen), object: self, userInfo: nil)
    }
    
    func leftDidOpen() {
        self.viewIsVisible = false
    }
    
    func leftDidClose() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.LeftDidClose), object: self, userInfo: nil)
        self.viewIsVisible = (self.view.window != nil)
        if let wrapper = self.slideMenuController()?.leftViewController as? AirNavigationController {
            if wrapper.topViewController is GroupSwitcherController {
                wrapper.popViewController(animated: false)
            }
        }
    }
    
    override func showPhotoEdit() {
        super.showPhotoEdit()
    }
    
    override func didPressLeftButton(_ sender: Any!) {
        super.didPressLeftButton(sender)
    }
    
    override func didPressRightButton(_ sender: Any!) {
        super.didPressRightButton(sender)
    }
    
    override func textDidUpdate(_ animated: Bool) {
        super.textDidUpdate(animated)
        
        let typing = (self.textInputbar.textView.text != nil && self.textInputbar.textView.text != "")
        
        if self.typingTask != nil {
            self.typingTask!.cancel()
        }
        
        self.isTyping = typing
        
        if typing {
            self.typingTask = Utils.delay(8.0) {    // Safety net
                self.isTyping = false
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * MARK: - Notifications
    *--------------------------------------------------------------------------------------------*/

    override func viewDidBecomeActive(sender: NSNotification) {
        reachabilityChanged()
        Log.d(self.viewIsVisible
            ? "Channel view controller is active and visible"
            : "Channel view controller is active and not visible")
    }
    
    override func viewWillResignActive(sender: NSNotification) {
        Log.d("Channel view controller will resign active")
    }
    
    func messageDidChange(notification: NSNotification) {
        if let userInfo = notification.userInfo, let messageId = userInfo["message_id"] as? String {
            self.rowHeights.removeObject(forKey: messageId)
        }
    }
    
    func unreadChange(notification: NSNotification?) {
        
        self.navButton.badgeValue = "\(UserController.instance.unreads)"
        
        /* Turn on unread indicator if we already have the message */
        
        if let channelId = notification?.userInfo?["channel_id"] as? String,
            let messageId = notification?.userInfo?["message_id"] as? String,
            channelId == self.channel.id {
            
            var index = 0
            for data in self.queryController.items {
                let snap = data as! FIRDataSnapshot
                if snap.key == messageId {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                    return
                }
                index += 1
            }
            self.tableView.reloadData()
        }
    }

    func reachabilityChanged() {
        if ReachabilityManager.instance.isReachable() {
            hideMessageBar()
            if self.headerView.needsPhoto {
                self.headerView.displayPhoto()
            }
        }
        else {
            showMessageBar()
        }
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        Reporting.screen("PatchDetail")
        
        self.automaticallyAdjustsScrollViewInsets = false
        let viewWidth = min(Config.contentWidthMax, self.view.width())
        self.headerHeight = viewWidth * 0.625
        
        updateHeaderView()
        
        self.headerView.optionsButton.addTarget(self, action: #selector(showChannelActions(sender:)), for: .touchUpInside)
        self.tableView.addSubview(self.headerView)
        
        self.tableView.estimatedRowHeight = 100						// Zero turns off estimates
        self.tableView.rowHeight = UITableViewAutomaticDimension	// Actual height is handled in heightForRowAtIndexPath
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.separatorStyle = .none
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.allowsSelection = false
        self.tableView.delegate = self
        self.tableView.contentInset = UIEdgeInsets(top: self.headerHeight + 74, left: 0, bottom: 0, right: 0)
        self.tableView.contentOffset = CGPoint(x: 0, y: -(self.headerHeight + 74))
        self.tableView.register(WrapperTableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.titleView = (Bundle.main.loadNibNamed("ChannelTitleView", owner: nil, options: nil)?.first as? ChannelTitleView)!
        
        self.itemTemplate.template = true
        
        /* Navigation button */
        var button = UIButton(type: .custom)
        button.frame = CGRect(x:0, y:0, width:36, height:36)
        button.addTarget(self, action: #selector(openNavigationAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgNavigationLight"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 0, 8, 16)
        
        self.navButton = UIBarButtonItem(customView: button)
        self.navButton.shouldHideBadgeAtZero = true
        self.navButton.badgeOriginX = 12
        self.navButton.badgeBGColor = Theme.colorBackgroundBadge
        self.navButton.badgeValue = "\(UserController.instance.unreads)"
        
        /* Title */
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.showChannelActions(sender:)))
        self.titleView = (Bundle.main.loadNibNamed("ChannelTitleView", owner: nil, options: nil)?.first as? ChannelTitleView)!
        self.titleView.title?.text = nil
        self.titleView.subtitle?.text = nil
        self.titleView.addGestureRecognizer(tap)
        self.titleButton = UIBarButtonItem(customView: self.titleView)
        
        /* Gallery button */
        button = UIButton(type: .custom)
        button.frame = CGRect(x:0, y:0, width:36, height:36)
        button.addTarget(self, action: #selector(openGalleryAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgGallery2Light"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6);
        let photosButton = UIBarButtonItem(customView: button)
        
        /* Menu button */
        button = UIButton(type: .custom)
        button.frame = CGRect(x:0, y:0, width:36, height:36)
        button.addTarget(self, action: #selector(openMenuAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgOverflowVerticalLight"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 0);
        let moreButton = UIBarButtonItem(customView: button)
        
        self.navigationItem.setLeftBarButtonItems([self.navButton, spacerFixed, self.titleButton], animated: true)
        self.navigationItem.setRightBarButtonItems([moreButton, photosButton], animated: true)

        /* Message bar */
        self.messageBar.font = Theme.fontTextDisplay
        self.messageBar.text = "Connection is offline"
        self.messageBar.numberOfLines = 0
        self.messageBar.textAlignment = NSTextAlignment.center
        self.messageBar.textColor = Colors.white
        self.messageBar.layer.backgroundColor = Colors.accentColorFill.cgColor
        self.messageBar.alpha = 0.0
        
        /* Join bar */
        self.joinBar.backgroundColor = Colors.white
        self.joinBarLabel.textAlignment = .center
        self.joinBarLabel.textColor = Theme.colorTextSecondary
        self.joinBarLabel.font = Theme.fontComment
        self.joinBarButton.setTitle("Join Channel", for: .normal)
        self.joinBar.addSubview(self.joinBarLabel)
        self.joinBar.addSubview(self.joinBarButton)
        self.joinBarButton.addTarget(self, action: #selector(joinChannelAction(sender:)), for: .touchUpInside)
        
        self.typingIndicatorView?.interval = TimeInterval(8.0)
        self.typingIndicatorView?.textFont = Theme.fontTextList
        self.typingIndicatorView?.highlightFont = Theme.fontTextListBold
        self.typingIndicatorView?.textColor = Colors.accentColorTextLight
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: ReachabilityChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(messageDidChange(notification:)), name: NSNotification.Name(rawValue: Events.MessageDidUpdate), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unreadChange(notification:)), name: NSNotification.Name(rawValue: Events.UnreadChange), object: nil)
    }
    
    fileprivate func bind(groupId: String, channelId: String) {
        
        /* Only called once */
        
        Log.d("Binding to: \(channelId)")
        
        let userId = UserController.instance.userId!
        let username = UserController.instance.user!.username!
        
        /* Primary list */
        
        let query = FireController.db.child("group-messages/\(groupId)/\(channelId)")
            .queryOrdered(byChild: "created_at_desc")
        
        self.queryController = DataSourceController()
        
        self.queryController.bind(to: self.tableView, query: query) { [weak self] tableView, indexPath, data in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! WrapperTableViewCell
            
            if self != nil {
                
                let snap = data as! FIRDataSnapshot
                let userId = UserController.instance.userId!
                let message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key)! as FireMessage
                
                if let messageView = cell.view as? MessageViewCell {
                    messageView.reset()
                }
                
                guard message.createdBy != nil else {
                    return cell
                }
                
                UserQuery(userId: message.createdBy!, groupId: groupId).once(with: { error, user in
                    message.creator = user
                    
                    if cell.view == nil {
                        let recognizer = UILongPressGestureRecognizer(target: self!, action: #selector(self!.longPressAction(sender:)))
                        recognizer.minimumPressDuration = TimeInterval(0.2)
                        cell.addGestureRecognizer(recognizer)
                        
                        let view = MessageViewCell(frame: CGRect(x: 0, y: 0, width: self!.view.width(), height: 40))
                        if view.description_ != nil && (view.description_ is TTTAttributedLabel) {
                            let label = view.description_ as! TTTAttributedLabel
                            label.delegate = self
                        }
                        
                        view.photoView?.isUserInteractionEnabled = true
                        view.photoView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self!.browsePhotoAction(sender:))))
                        cell.injectView(view: view, padding: self!.itemPadding)
                        cell.layoutSubviews()   // Make sure padding has been applied
                    }
                    
                    if let messageView = cell.view! as? MessageViewCell {
                        
                        messageView.bind(message: message)
                        
                        if message.creator != nil {
                            messageView.userPhotoControl.target = message.creator
                            messageView.userPhotoControl.addTarget(self!, action: #selector(self!.browseMemberAction(sender:)), for: .touchUpInside)
                        }
                        
                        let messageId = message.id!
                        if self!.unreads[messageId] != nil {
                            messageView.unread.isHidden = false
                            self!.unreads.removeValue(forKey: messageId)
                        }
                        else {
                            let unreadPath = "unreads/\(userId)/\(groupId)/\(channelId)/\(messageId)"
                            FireController.db.child(unreadPath).observeSingleEvent(of: .value, with: { snap in
                                if !(snap.value is NSNull) {
                                    if !self!.viewIsVisible {
                                        self!.unreads[messageId] = true
                                    }
                                    messageView.unread.isHidden = false
                                    FireController.instance.clearMessageUnread(messageId: messageId, channelId: channelId, groupId: groupId)
                                }
                            })
                        }
                    }
                })
            }
            return cell
        }
        
        self.queryController.delegate = self
        
        /* Header */
        
        self.queryChannel = ChannelQuery(groupId: groupId, channelId: channelId, userId: userId)
        self.queryChannel!.observe(with: { [weak self] error, channel in
            
            guard channel != nil else {
                if error == nil {
                    /* The channel has been deleted from under us. */
                    self?.queryChannel?.remove()
                    FireController.instance.autoPickChannel(groupId: groupId) { channelId in
                        if channelId != nil {
                            StateController.instance.setChannelId(channelId: channelId!, groupId: groupId)
                            MainController.instance.showChannel(groupId: groupId, channelId: StateController.instance.channelId!)
                        }
                    }                    
                }
                return
            }
            
            self?.channel = channel
            self?.titleView.subtitle?.text = "#\((self?.channel.name!)!)"
            
            if channel?.joinedAt != nil {
                self?.hideJoinBar()
                self?.setTextInputbarHidden(false, animated: true)
                self?.textView.placeholder = "Message #\((self?.channel.name!)!)"
                
                self?.queryUnread = UnreadQuery(level: .channel, userId: userId, groupId: groupId, channelId: channelId)
                self?.queryUnread!.observe(with: { [weak self] error, total in
                    if self != nil, error == nil {
                        let total = total ?? 0
                        if total == 0 && self!.channel?.priority == 0 {
                            self!.channel?.clearUnreadSorting()
                        }
                    }
                })
            }
            else {
                self?.showJoinBar()
                self?.joinBarLabel.text = "This is a preview of #\((self?.channel.name!)!)"
                self?.setTextInputbarHidden(true, animated: true)
            }
            
            /* We do this here so we have tableView sizing */
            Log.d("Bind channel header")

            self?.headerView.bind(channel: self?.channel)
            self?.headerView.gestureRecognizers?.removeAll()
            let tap = UITapGestureRecognizer(target: self, action: #selector(self?.showChannelActions(sender:)))
            self?.headerView.addGestureRecognizer(tap)
            
            if self != nil && self!.channel.purpose != nil {
                let viewWidth = min(Config.contentWidthMax, self!.view.width())
                self!.headerView.purpose.bounds.size.width = viewWidth - 32
                self!.headerView.purpose.sizeToFit()
                let infoHeight = self!.headerView.purpose.height() + 24
                self!.headerHeight = (viewWidth * 0.625) + infoHeight
                self!.tableView.contentInset = UIEdgeInsets(top: self!.headerHeight + 74, left: 0, bottom: 0, right: 0)
                self!.tableView.contentOffset = CGPoint(x: 0, y: -(self!.headerHeight + 74))
                self!.updateHeaderView()
            }
        })

        /* Typing */
        
        self.typingRef = FireController.db.child("typing/\(groupId)/\(channelId)")
        self.typingAddHandle = self.typingRef.observe(.childAdded, with: { [weak self] snap in
            if self != nil {
                if let typerName = snap.value as? String {
                    if typerName != username {
                        self!.typingIndicatorView?.insertUsername(typerName)    // Auto removed in 8 secs
                    }
                }
            }
        })
        self.typingRemoveHandle = self.typingRef.observe(.childRemoved, with: { [weak self] snap in
            if self != nil {
                if let typerName = snap.value as? String {
                    if typerName != username {
                        self!.typingIndicatorView?.removeUsername(typerName)
                    }
                }
            }
        })
        self.typingRef.child(userId).onDisconnectRemoveValue()
        
        /* Title */
        
        FireController.db.child("groups/\(groupId)/title").observe(.value, with: { [weak self] snap in
            if let title = snap.value as? String {
                self?.titleView.title?.text = title
            }
        })
        
        Log.d("Observe query triggered for channel messages")
        
        if !MainController.instance.introPlayed {
            if UserDefaults.standard.bool(forKey: PerUserKey(key: Prefs.soundEffects)) {
                AudioController.instance.play(sound: Sound.greeting.rawValue)
            }
            MainController.instance.introPlayed = true
        }
    }
    
    func updateHeaderView() {
        var headerRect = CGRect(x: 0, y: -self.headerHeight, width: self.view.width(), height: self.headerHeight)
        if self.tableView.contentOffset.y < -(self.headerHeight + 74) {
            headerRect.origin.y = (self.tableView.contentOffset.y + 74)
            headerRect.size.height = -(self.tableView.contentOffset.y + 74)
        }
        self.headerView.frame = headerRect
    }
    
    func showMessageActions(message: FireMessage, sourceView: UIView?) {
        
        let userId = UserController.instance.userId!
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

        let likes = message.getReaction(emoji: .thumbsup, userId: userId)
        let likeTitle = likes ? "Remove like" : "Add like"
        let like = UIAlertAction(title: likeTitle, style: .default) { action in
            if self.channel?.joinedAt == nil {
                UIShared.toast(message: "Join this channel to like messages.")
                return
            }

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.MessageDidUpdate)
                , object: self, userInfo: ["message_id": message.id!])
            self.rowHeights.removeObject(forKey: message.id!)
            if likes {
                message.removeReaction(emoji: .thumbsup)
            }
            else {
                message.addReaction(emoji: .thumbsup)
            }
        }
        
        let edit = UIAlertAction(title: "Edit message", style: .default) { action in
            self.editMessage(message: message)
        }
        let delete = UIAlertAction(title: "Delete message", style: .destructive) { action in
            self.deleteMessageAction(message: message)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
            sheet.dismiss(animated: true, completion: nil)
        }
        
        if message.createdBy == userId {
            sheet.addAction(like)
            sheet.addAction(edit)
            sheet.addAction(delete)
            sheet.addAction(cancel)
        }
        else if self.channel.role == "owner" {
            sheet.addAction(like)
            sheet.addAction(delete)
            sheet.addAction(cancel)
        }
        else {
            sheet.addAction(like)
            sheet.addAction(cancel)
        }
        
        if let presenter = sheet.popoverPresentationController, let sourceView = sourceView {
            presenter.sourceView = sourceView
            presenter.sourceRect = sourceView.bounds
        }

        present(sheet, animated: true, completion: nil)
    }
    
    func showChannelActions(sender: AnyObject?) {
        
        if self.channel != nil {
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            let isMember = (self.channel.joinedAt != nil)
            let userId = UserController.instance.userId!
            let isOwner = (self.channel.role == "owner" || self.channel.ownedBy == userId)
            
            let statusTitle = isMember ? "Leave channel" : "Join channel"
            let statusAction = UIAlertAction(title: statusTitle, style: .default) { action in
                if isMember {
                    if isOwner {    // Check if only owner
                        let groupId = StateController.instance.groupId!
                        let channelId = self.channel.id!
                        FireController.instance.channelRoleCount(groupId: groupId, channelId: channelId, role: "owner") { count in
                            if count != nil && count! < 2 {
                                self.alert(title: "Only Owner", message: "Channels need at least one owner.")
                                return
                            }
                            self.leaveChannelAction(sender: nil)
                        }
                        return
                    }
                    self.leaveChannelAction(sender: nil)
                }
                else {
                    self.joinChannelAction(sender: nil)
                }
            }
            
            var muteAction: UIAlertAction? = nil
            var starAction: UIAlertAction? = nil
            
            if isMember || isOwner {
                if let muted = self.channel.muted {
                    let mutedTitle = muted ? "Unmute channel" : "Mute channel"
                    muteAction = UIAlertAction(title: mutedTitle, style: .default) { action in
                        self.channel.mute(on: !muted)
                    }
                }
                
                if let starred = self.channel.starred {
                    let starredTitle = starred ? "Unstar channel" : "Star channel"
                    starAction = UIAlertAction(title: starredTitle, style: .default) { action in
                        self.channel.star(on: !starred)
                        self.headerView.starButton.toggle(on: !starred, animate: true)
                    }
                }
            }

            let editAction = UIAlertAction(title: "Manage channel", style: .default) { action in
                self.editChannelAction()
            }
            
            let browseMembersAction = UIAlertAction(title: "Channel members", style: .default) { action in
                let controller = MemberListController()
                let wrapper = AirNavigationController(rootViewController: controller)
                controller.scope = .channel
                controller.target = .channel
                UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
            }

            let inviteAction = UIAlertAction(title: "Invite to channel", style: .default) { action in
                let controller = ContactPickerController()
                controller.role = "guests"
                controller.channels = [self.channel.id!: self.channel.name!]
                controller.inputGroupId = StateController.instance.groupId!
                controller.inputGroupTitle = StateController.instance.group.title
                let wrapper = AirNavigationController(rootViewController: controller)
                UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
            }

            let cancel = UIAlertAction(title: "Cancel", style: .cancel) {
                action in
                sheet.dismiss(animated: true, completion: nil)
            }
            
            if isOwner {
                if starAction != nil {
                    sheet.addAction(starAction!)
                }
                if muteAction != nil {
                    sheet.addAction(muteAction!)
                }
                sheet.addAction(browseMembersAction)
                sheet.addAction(inviteAction)
                if !self.channel!.general! {
                    sheet.addAction(statusAction)
                }
                sheet.addAction(editAction)         // Owners only
                sheet.addAction(cancel)
            }
            else if isMember {
                if starAction != nil {
                    sheet.addAction(starAction!)
                }
                if muteAction != nil {
                    sheet.addAction(muteAction!)
                }
                sheet.addAction(browseMembersAction)
                sheet.addAction(inviteAction)
                if !self.channel!.general! {
                    sheet.addAction(statusAction)
                }
                sheet.addAction(cancel)
            }
            else {
                sheet.addAction(browseMembersAction)
                if !self.channel!.general! {
                    sheet.addAction(statusAction)
                }
                sheet.addAction(cancel)
            }
            
            if let presenter = sheet.popoverPresentationController {
                presenter.sourceView = self.titleView
                presenter.sourceRect = self.titleView.bounds
            }
            
            present(sheet, animated: true, completion: nil)
        }
    }

    func showPhotos(mode: PhotoBrowserMode, fromView: UIView? = nil, initialUrl: URL? = nil) {

        /* Cherry pick display photos */
        var remaining = self.queryController.items.count
        self.displayPhotos.removeAll()
        
        for data in self.queryController.items {
            let snap = data as! FIRDataSnapshot
            if let message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key) {
                
                message.getCreator(with: { user in
                    
                    remaining -= 1
                    if (message.attachments?.values.first?.photo) != nil {
                        message.creator = user
                        let displayPhoto = DisplayPhoto.fromMessage(message: message)
                        self.displayPhotos[displayPhoto.entityId!] = displayPhoto
                    }
                    
                    if remaining <= 0 {
                        if mode == .gallery {
                            
                            if self.displayPhotos.count == 0 {
                                UIShared.toast(message: "This channel needs some photos!")
                                return
                            }
                            let layout = NHBalancedFlowLayout()
                            layout.preferredRowSize = 200
                            let controller = GalleryGridViewController(collectionViewLayout: layout)
                            controller.displayPhotos = self.displayPhotos
                            let wrapper = AirNavigationController(rootViewController: controller)
                            self.navigationController!.present(wrapper, animated: true, completion: nil)
                        }
                        else if mode == .browse {
                            
                            self.displayPhotosArray = Array(self.displayPhotos.values).sorted(by: { $0.createdDateValue! > $1.createdDateValue! })
                            var initialIndex = 0
                            if initialUrl != nil {
                                var index = 0
                                for displayPhoto in self.displayPhotosArray {
                                    if initialUrl?.path == displayPhoto.photoURL.path {
                                        initialIndex = index
                                        break
                                    }
                                    index += 1
                                }
                            }
                            let browser = (PhotoBrowser(photos: self.displayPhotosArray as [Any], animatedFrom: fromView))!
                            
                            browser.mode = .gallery
                            browser.setInitialPageIndex(UInt(initialIndex))
                            browser.useWhiteBackgroundColor = true
                            browser.usePopAnimation = true
                            browser.scaleImage = (fromView as! UIImageView).image  // Used because final image might have different aspect ratio than initially
                            browser.disableVerticalSwipe = false
                            browser.autoHideInterface = false
                            browser.delegate = self
                            
                            self.navigationController!.present(browser, animated:true, completion:nil)
                        }
                    }
                })
            }
        }
    }

    func shareUsing(route: ShareRoute) { }
    
    func showMessageBar() {
        self.view.insertSubview(self.messageBar, at: self.view.subviews.count)
        self.messageBar.alignUnder(self.navigationController?.navigationBar, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 40)
        self.messageBarTop = self.messageBar.frame.origin.y
        UIView.animate(
            withDuration: 0.10,
            delay: 0,
            options: UIViewAnimationOptions.curveEaseOut,
            animations: {
                self.messageBar.alpha = 1
            })
    }

    func hideMessageBar() {
        UIView.animate(
            withDuration: 0.30,
            delay: 0,
            options: UIViewAnimationOptions.curveEaseOut,
            animations: {
                self.messageBar.alpha = 0
            }) { _ in
            self.messageBar.removeFromSuperview()
        }
    }
    
    func showJoinBar() {
        self.view.insertSubview(self.joinBar, at: self.view.subviews.count)
        self.joinBar.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 88)
        UIView.animate(
            withDuration: 0.10,
            delay: 0,
            options: UIViewAnimationOptions.curveEaseOut,
            animations: {
                self.joinBar.alpha = 1
        })
    }
    
    func hideJoinBar() {
        UIView.animate(
            withDuration: 0.30,
            delay: 0,
            options: UIViewAnimationOptions.curveEaseOut,
            animations: {
                self.joinBar.alpha = 0
        }) { _ in
            self.joinBar.removeFromSuperview()
        }
    }
    
    func scrollToHeader(animated: Bool = true) {
        self.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: animated)
    }
    
    func scrollToFirstRow(animated: Bool = true) {
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    func scrollToLastRow(animated: Bool = true) {
        let itemCount = self.queryController.items.count
        if itemCount > 0 {
            let indexPath = IndexPath(row: itemCount - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /*
         * Using an estimate significantly improves table view load time but we can get
         * small scrolling glitches if actual height ends up different than estimated height.
         * So we try to provide the best estimate we can and still deliver it quickly.
         *
         * Note: Called once only for each row in fetchResultController when FRC is making a data pass in
         * response to managedContext.save.
         */
        let viewWidth = min(Config.contentWidthMax, self.tableView.width())
        var viewHeight = CGFloat(100)
        let snap = self.queryController.snapshots.snapshot(at: indexPath.row)
        
        if let message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key), message.channelId != nil {
            
            if message.id != nil {
                if let cachedHeight = self.rowHeights.object(forKey: message.id!) as? CGFloat {
                    return cachedHeight
                }
            }

            self.itemTemplate.bind(message: message)
            self.itemTemplate.bounds.size.width = viewWidth - (self.itemPadding.left + self.itemPadding.right)
            self.itemTemplate.sizeToFit()
            
            viewHeight = self.itemTemplate.height() + (self.itemPadding.top + self.itemPadding.bottom + 1)

            if message.id != nil {
                self.rowHeights[message.id!] = viewHeight
            }
        }
        
        return viewHeight
    }
}

extension ChannelViewController: FUICollectionDelegate {
    func array(_ array: FUICollection, didChange object: Any, at index: UInt) {
        if let snap = object as? FIRDataSnapshot {
            self.rowHeights.removeObject(forKey: snap.key)
        }
    }
}

extension ChannelViewController: IDMPhotoBrowserDelegate {
    
    func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, captionViewForPhotoAt index: UInt) -> IDMCaptionView! {
        let captionView = CaptionView(displayPhoto: self.displayPhotosArray![Int(index)])
        captionView?.alpha = 0
        return captionView
    }
    
    func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, didShowPhotoAt index: UInt) {
        let index = Int(index)
        if let browser = photoBrowser as? PhotoBrowser {
            let displayPhoto = self.displayPhotosArray![index]
            browser.likeButton.bind(displayPhoto: displayPhoto)
        }
    }
}

extension ChannelViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.openURL(url)
    }
}

extension ChannelViewController {
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        updateHeaderView()
    }
}

class ChannelItem: NSObject, UIActivityItemSource {

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        /* Called before the share actions are displayed */
        return ""
    }

    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivityType?, suggestedSize size: CGSize) -> UIImage? {
        /* Not currently called by any of the share extensions I could test. */
        return nil
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        let text = "\(UserController.instance.user!.profile!.fullName!) has invited you to the patch!"
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
            return "Invitation to the patch"
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

enum ShareRoute {
    case Patchr
    case Facebook
    case AirDrop
    case Actions
}
