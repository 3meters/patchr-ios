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
import STPopup
import SlackTextViewController
import BEMCheckBox

class MessageViewController: BaseSlackController {

	var inputChannelId: String?

	var channelQuery: ChannelQuery?

	var headerView = ChannelDetailView()
    var actionButton: AirRadialMenu!
	var unreads = [String: Bool]()
	var displayPhotos = [String: DisplayPhoto]()
	var displayPhotosSorted: [Any]!
    var lastContentOffset = CGFloat(0)
    var isChromeTranslucent = false
    var statusBarStyle: UIStatusBarStyle = .lightContent

    var selectedRow: Int?

	var headerHeight = CGFloat(0)

	weak var sheetController: STPopupController!

	var titleView: ChannelTitleView!
	var navButton: UIBarButtonItem!
	var titleButton: UIBarButtonItem!

	/* Only used for row sizing */
	var rowHeights: NSMutableDictionary = [:]
	var itemTemplate = MessageListCell()

	/* Observes typers for channel. If we see typers (but not this user), we
	   pass them to the typing indicator. Each user passed to the typing
	   indicator has an attached timer that removes it after 8 seconds. */
	var typingRef: DatabaseReference!
	var typingAddHandle: DatabaseHandle!
	var typingRemoveHandle: DatabaseHandle!

	var typingTask: DispatchWorkItem?
	var localTyping = false
	// Setting add/removes this user from channel typers
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
						self.typingRef?.child(userId).setValue(username)
					}
					else {
						self.typingRef?.child(userId).removeValue()
					}
				}
			}
		}
	}

	/*--------------------------------------------------------------------------------------------
	 * MARK: - Lifecycle
	 *--------------------------------------------------------------------------------------------*/
    
    init(channelId: String?) {
        self.inputChannelId = channelId
        super.init(nibName: nil, bundle: nil) // Must call designated inititializer for view controller base class
    }
    
    required init?(coder decoder: NSCoder) {
        /* Needed because base protocol requires it and we are providing our own init */
        fatalError("NSCoding (storyboards) not supported")
    }
    
    override init?(tableViewStyle style: UITableViewStyle) {
        super.init(tableViewStyle: style)
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()
		initialize()
        self.setTextInputbarHidden(true, animated: false)
        UIShared.styleChrome(navigationBar: (self.navigationController?.navigationBar)!, translucent: true)
        if let navigationController = self.navigationController as? AirNavigationController {
            navigationController.statusBarView.backgroundColor = Colors.clear
        }
		bind(channelId: self.inputChannelId!)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
        
        if self.tabBar != nil {
            if self.actionButton != nil {
                self.tabBar?.setActionButton(button: self.actionButton)
                self.tabBar?.showActionButton()
            }
        }
        
		iRate.sharedInstance().promptIfAllCriteriaMet()
		if let link = MainController.instance.link {
			MainController.instance.link = nil
			MainController.instance.routeDeepLink(link: link, error: nil)
		}
        
        if self.unreads.count > 0 {
            let channelId = StateController.instance.channelId!
            for messageId in self.unreads.keys {
                FireController.instance.clearMessageUnread(messageId: messageId, channelId: channelId)
            }
        }
	}
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParentViewController {
            UIShared.styleChrome(navigationBar: self.navigationController!.navigationBar, translucent: false)
            self.tabBar?.hideActionButton()
            StateController.instance.clearChannel() // Only clears last channel default
        }
    }

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		self.isTyping = false
        if self.tabBar != nil {
            self.tabBar?.setActionButton(button: nil)
        }
	}

	override func viewWillLayoutSubviews() {

		let viewWidth = min(Config.contentWidthMax, self.view.width())
		self.view.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: self.view.height())

		super.viewWillLayoutSubviews()

		self.tableView.fillSuperview()
		self.titleView?.bounds.size.width = self.view.width() - 160
		self.navigationController?.navigationBar.setNeedsLayout()
	}

	deinit {
		Log.v("MessageViewController released: \(self.inputChannelId!)")
		unbind()
	}

	/*--------------------------------------------------------------------------------------------
	 * MARK: - Events
	 *--------------------------------------------------------------------------------------------*/

	func backgroundTapped(sender: AnyObject?) {
		if let controller = self.sheetController {
			controller.dismiss()
		}
	}

	func openGalleryAction(sender: AnyObject) {
		Reporting.track("view_photo_gallery")
		showPhotos(mode: .gallery)
	}

    func actionButtonTapped(gesture: UIGestureRecognizer) {
        let controller = MessageEditViewController()
        let wrapper = AirNavigationController()
        controller.inputChannelId = StateController.instance.channelId!
        controller.mode = .insert
        wrapper.viewControllers = [controller]
        UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
    }

	func browseMemberAction(sender: AnyObject?) {
		if let photoControl = sender as? PhotoControl {
			if let user = photoControl.target as? FireUser {
                let controller = MemberViewController(userId: user.id)
                let wrapper = AirNavigationController(rootViewController: controller)
				Reporting.track("view_group_member")
                UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
			}
		}
	}

	func browsePhotoAction(sender: AnyObject?) {
		if let recognizer = sender as? UITapGestureRecognizer,
            let control = recognizer.view as? AirImageView,
            let url = control.fromUrl {
            Reporting.track("view_photos")
            let point = recognizer.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: point) {
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                self.tableView(self.tableView, didSelectRowAt: indexPath)
            }
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
				let channelId = message.channelId!
				let messageId = message.id!
				Reporting.track("delete_message")
				FireController.instance.deleteMessage(messageId: messageId, channelId: channelId)
			}
		}
	}

	func editChannelAction() {
		let controller = ChannelEditViewController()
		let wrapper = AirNavigationController()
		controller.mode = .update
		controller.inputChannelId = self.channel.id
		wrapper.viewControllers = [controller]
		Reporting.track("view_channel_edit")
		self.present(wrapper, animated: true, completion: nil)
	}

	func leaveChannelAction(sender: AnyObject?) {
        
        DeleteConfirmationAlert(
            title: "Confirm",
            message: "Are you sure you want to leave this channel? A new invitation may be required to rejoin.",
            actionTitle: "Leave", cancelTitle: "Cancel", delegate: self) { doIt in
                if doIt {
                    let userId = UserController.instance.userId!
                    Reporting.track("leave_channel")
                    FireController.instance.removeUserFromChannel(userId: userId, channelId: self.channel.id!, then: { [weak self] error, result in
                        guard self != nil else { return }
                        if error == nil {
                            UIShared.toast(message: "You have left this channel.")
                            StateController.instance.clearChannel() // Only clears last channel default
                            if UserDefaults.standard.bool(forKey: PerUserKey(key: Prefs.soundEffects)) {
                                AudioController.instance.play(sound: Sound.pop.rawValue)
                            }
                        }
                    })
                }
        }
        
	}
    
    func showActions(sender: AnyObject?) {
        if let button = sender as? AirButtonBase {
            if let message = button.data as? FireMessage {
                Reporting.track("view_message_actions")
                showMessageActions(message: message, sourceView: button)
            }
        }
    }

	func longPressAction(sender: UILongPressGestureRecognizer) {
		if sender.state == UIGestureRecognizerState.began {
			let point = sender.location(in: self.tableView)
			if let indexPath = self.tableView.indexPathForRow(at: point) {
                self.view.endEditing(true)
				dismissKeyboard(true)
				let cell = self.tableView.cellForRow(at: indexPath) as! MessageListCell
				let snap = self.queryController.snapshot(at: indexPath.row)
				let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)
				Reporting.track("view_message_actions")
				showMessageActions(message: message, sourceView: cell.contentView)
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
    
    override func didChangeKeyboardStatus(_ status: SLKKeyboardStatus) {
        if status == .willHide {
            self.tabBar?.showActionButton()
            self.setTextInputbarHidden(true, animated: false)
        }
        else if status == .willShow {
            self.tabBar?.hideActionButton()
            self.setTextInputbarHidden(false, animated: false)
        }
    }

	override func textDidUpdate(_ animated: Bool) {
		super.textDidUpdate(animated)

		let typing = (self.textInputbar.textView.text != nil && self.textInputbar.textView.text != "")

		if self.typingTask != nil {
			self.typingTask!.cancel()
		}

		self.isTyping = typing

		if typing {
			self.typingTask = Utils.delay(Double(Config.typingInterval)) {    // Safety net
				self.isTyping = false
			}
		}
	}

	/*--------------------------------------------------------------------------------------------
	* MARK: - Notifications
	*--------------------------------------------------------------------------------------------*/

	override func viewDidBecomeActive(sender: NSNotification) {
        Log.d("Channel view controller will become active")
	}

	override func viewWillResignActive(sender: NSNotification) {
		Log.d("Channel view controller will resign active")
	}

	func messageDidChange(notification: NSNotification) {
		if let userInfo = notification.userInfo, let messageId = userInfo["message_id"] as? String {
			self.rowHeights.removeObject(forKey: messageId)
		}
	}

	func userDidUpdate(notification: NSNotification) {
		self.tableView.reloadData()
	}

	/*--------------------------------------------------------------------------------------------
	 * MARK: - Methods
	 *--------------------------------------------------------------------------------------------*/

	override func initialize() {
		super.initialize()

		self.authHandle = Auth.auth().addStateDidChangeListener() { [weak self] auth, user in
			guard let this = self else { return }
			if user == nil {
				this.unbind()
			}
		}

		self.automaticallyAdjustsScrollViewInsets = false
		let viewWidth = min(Config.contentWidthMax, self.view.width())

		self.headerHeight = viewWidth * 0.625

		updateHeaderView()
        
        self.tabBar = self.tabBarController as? TabBarController
        if self.tabBar != nil {
            configureActionButton()
        }

		self.tableView.addSubview(self.headerView)

		self.tableView.estimatedRowHeight = 100                        // Zero turns off estimates
		self.tableView.rowHeight = UITableViewAutomaticDimension    // Actual height is handled in heightForRowAtIndexPath
		self.tableView.backgroundColor = Theme.colorBackgroundTable
		self.tableView.separatorInset = UIEdgeInsets.zero
		self.tableView.tableFooterView = UIView()
		self.tableView.delegate = self
		self.tableView.contentInset = UIEdgeInsets(top: self.headerHeight, left: 0, bottom: 0, right: 0)
		self.tableView.contentOffset = CGPoint(x: 0, y: -(self.headerHeight))
		self.tableView.register(MessageListCell.self, forCellReuseIdentifier: "cell")

		self.itemTemplate.template = true
        
		/* Navigation button */
        self.navigationController?.navigationBar.backItem?.title = "Channels"

		/* Title */
		self.titleView = (Bundle.main.loadNibNamed("ChannelTitleView", owner: nil, options: nil)?.first as? ChannelTitleView)!
		self.titleView.title?.text = nil
		self.titleButton = UIBarButtonItem(customView: self.titleView)

		/* Gallery button */
		var button = UIButton(type: .custom)
		button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
		button.addTarget(self, action: #selector(openGalleryAction(sender:)), for: .touchUpInside)
		button.showsTouchWhenHighlighted = true
		button.setImage(UIImage(named: "imgGallery2Light"), for: .normal)
		button.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
		let photosButton = UIBarButtonItem(customView: button)

		/* Menu button */
		button = UIButton(type: .custom)
		button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
		button.addTarget(self, action: #selector(showChannelActions(sender:)), for: .touchUpInside)
		button.showsTouchWhenHighlighted = true
		button.setImage(UIImage(named: "imgOverflowVerticalLight"), for: .normal)
		button.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
		let moreButton = UIBarButtonItem(customView: button)

		self.navigationItem.setRightBarButtonItems([moreButton, UI.spacerFixed, UI.spacerFixed, photosButton], animated: true)

		self.typingIndicatorView?.interval = TimeInterval(Config.typingInterval)
		self.typingIndicatorView?.textFont = Theme.fontTextList
		self.typingIndicatorView?.highlightFont = Theme.fontTextListBold
		self.typingIndicatorView?.textColor = Colors.white
		self.typingIndicatorView?.backgroundColor = Colors.accentColorFill

		self.textInputbar.contentInset = UIEdgeInsetsMake(5, 0, 5, 8)   // Here because it triggers layout pass

		NotificationCenter.default.addObserver(self, selector: #selector(messageDidChange(notification:)), name: NSNotification.Name(rawValue: Events.MessageDidUpdate), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(userDidUpdate(notification:)), name: NSNotification.Name(rawValue: Events.UserDidUpdate), object: nil)
	}

	fileprivate func bind(channelId: String) {

		/* Only called once */

		Log.v("Binding to: \(channelId)")

		let userId = UserController.instance.userId!
		let username = UserController.instance.user!.username!

		/* Primary list */

		let query = FireController.db.child("channel-messages/\(channelId)")
				.queryOrdered(byChild: "created_at_desc")

		self.queryController = DataSourceController(name: "channel_view")

		self.queryController.bind(to: self.tableView, query: query) { [weak self] scrollView, indexPath, data in

			/* If cell.prepareToReuse is called, userQuery observer is removed */
            let tableView = scrollView as! UITableView
			let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MessageListCell
			guard let this = self else { return cell }

			let snap = data as! DataSnapshot
			let userId = UserController.instance.userId!
			let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)

			guard message.createdBy != nil else {
				return cell
			}
            
			cell.userQuery = UserQuery(userId: message.createdBy!, channelId: channelId)
			cell.userQuery.once(with: { [weak this, weak cell] error, user in

				guard let this = this else { return }
				guard let cell = cell else { return }

				message.creator = user

				if !cell.decorated {

					let recognizer = UILongPressGestureRecognizer(target: this, action: #selector(this.longPressAction(sender:)))
					recognizer.minimumPressDuration = TimeInterval(0.2)
					cell.addGestureRecognizer(recognizer)

					if let label = cell.description_ as? TTTAttributedLabel {
						label.delegate = this
					}
                    
					cell.photoView?.isUserInteractionEnabled = true
					cell.photoView?.addGestureRecognizer(UITapGestureRecognizer(target: this, action: #selector(this.browsePhotoAction(sender:))))
                    cell.actionsButton.addTarget(this, action: #selector(this.showActions(sender:)), for: .touchUpInside)
					cell.decorated = true
				}

                cell.bind(message: message) // Handles hide/show of actions button based on message.selected

				if message.creator != nil {
					cell.userPhotoControl.target = message.creator
					cell.userPhotoControl.addTarget(this, action: #selector(this.browseMemberAction(sender:)), for: .touchUpInside)
				}
                
				/* Unread handling */

				let messageId = message.id!
				if this.unreads[messageId] != nil {
					cell.unread.isHidden = false
				}
				else {
					cell.unreadQuery = UnreadQuery(level: .message, userId: userId, channelId: channelId, messageId: messageId)
					cell.unreadQuery!.observe(with: { [weak this, weak cell] error, total in
						guard let this = this else { return }
						guard let cell = cell else { return }
						if total != nil && total! > 0 {
							cell.unread.isHidden = false
							this.unreads[messageId] = true // Cache it
                            FireController.instance.clearMessageUnread(messageId: messageId, channelId: channelId)
						}
					})
				}
			})
			return cell
		}

		self.queryController.delegate = self

		/* Header */

		self.channelQuery = ChannelQuery(channelId: channelId, userId: userId)
		self.channelQuery!.observe(with: { [weak self] error, channel in

			guard let this = self else { return }
			guard channel != nil else {
				if error != nil {
					// We don't have a current group
					MainController.instance.showChannelsGrid()
				}
				return
			}

			this.channel = channel
			this.titleView.title?.text = "\(this.channel.title!)"
			this.navigationController?.navigationBar.setNeedsLayout()

            this.textView.placeholder = "Post to \(this.channel.name!)"
            
			/* We do this here so we have tableView sizing */
			Log.v("Bind channel header")

			this.headerView.bind(channel: this.channel)

			if this.channel.purpose != nil {

//				let viewWidth = min(Config.contentWidthMax, this.view.width())
//				this.headerView.purposeLabel.bounds.size.width = viewWidth - 32
//				this.headerView.purposeLabel.sizeToFit()
//				this.headerView.purposeLabel.anchorTopLeft(withLeftPadding: 12
//						, topPadding: 12
//						, width: this.headerView.purposeLabel.width()
//						, height: this.headerView.purposeLabel.height())
//
//				let infoHeight = this.headerView.purposeLabel.height() + 24
//				this.headerHeight = (viewWidth * 0.625) + infoHeight
//
//				this.tableView.contentInset = UIEdgeInsets(top: this.headerHeight + 74, left: 0, bottom: 0, right: 0)
//				this.tableView.contentOffset = CGPoint(x: 0, y: -(this.headerHeight + 74))
//				this.updateHeaderView()
			}
		})

		/* Typing */

		self.typingRef = FireController.db.child("typing/\(channelId)")
		self.typingAddHandle = self.typingRef.observe(.childAdded, with: { [weak self] snap in
			guard let this = self else { return }
			if let typerName = snap.value as? String {
				if typerName != username {
					this.typingIndicatorView?.insertUsername(typerName)    // Auto removed in 8 secs
				}
			}
		})
		self.typingRemoveHandle = self.typingRef.observe(.childRemoved, with: { [weak self] snap in
			guard let this = self else { return }
			if let typerName = snap.value as? String {
				if typerName != username {
					this.typingIndicatorView?.removeUsername(typerName)
				}
			}
		})

		self.typingRef.child(userId).onDisconnectRemoveValue()

		Log.v("Observe query triggered for channel messages")

		if !MainController.instance.introPlayed {
			if UserDefaults.standard.bool(forKey: PerUserKey(key: Prefs.soundEffects)) {
				AudioController.instance.play(sound: Sound.greeting.rawValue)
			}
			MainController.instance.introPlayed = true
		}
	}

	func unbind() {

		if self.typingAddHandle != nil {
			self.typingRef.removeObserver(withHandle: self.typingAddHandle)
		}
		if self.typingRemoveHandle != nil {
			self.typingRef.removeObserver(withHandle: self.typingRemoveHandle)
		}
		if self.queryController != nil {
			self.queryController.unbind()
		}
		self.channelQuery?.remove()
	}
    
	func updateHeaderView() {
		var headerRect = CGRect(x: 0, y: -self.headerHeight, width: self.view.width(), height: self.headerHeight)
		if self.tableView.contentOffset.y < -(self.headerHeight) {
			headerRect.origin.y = (self.tableView.contentOffset.y)
			headerRect.size.height = -(self.tableView.contentOffset.y)
		}
		self.headerView.frame = headerRect
	}

	func showMessageActions(message: FireMessage, sourceView: UIView?) {

		let userId = UserController.instance.userId!
		let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

		let like = UIAlertAction(title: "Add reaction", style: .default) { action in

			if self.channel?.joinedAt == nil {
				UIShared.toast(message: "Join this channel to add reactions.")
				return
			}
			Reporting.track("view_reaction_picker")
			let layout = UICollectionViewFlowLayout()
			let controller = ReactionPickerController(collectionViewLayout: layout)
			controller.inputMessage = message
			controller.contentSizeInPopup = CGSize(width: Config.screenWidth, height: 192)

			if let topController = UIViewController.topMostViewController() {
				let popController = STPopupController(rootViewController: controller)
				let backgroundView = UIView()
				backgroundView.backgroundColor = Colors.opacity25pcntBlack
				popController.style = .bottomSheet
				popController.backgroundView = backgroundView
				popController.hidesCloseButton = true
				self.sheetController = popController
				let tap = UITapGestureRecognizer(target: self, action: #selector(self.backgroundTapped(sender:)))
				self.sheetController.backgroundView?.addGestureRecognizer(tap)
				self.sheetController.present(in: topController)
			}
		}

		let edit = UIAlertAction(title: "Edit message", style: .default) { action in
            
            Reporting.track("view_message_edit")
            let controller = MessageEditViewController()
            let wrapper = AirNavigationController()
            controller.inputMessageId = message.id!
            controller.inputChannelId = message.channelId!
            controller.mode = .update
            wrapper.viewControllers = [controller]
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
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

		Reporting.track("view_channel_actions")

		if self.channel != nil {
            
			let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
			let isOwner = (self.channel.role == "owner")
			let isReader = (self.channel.role == "reader")

			let statusAction = UIAlertAction(title: "Leave channel", style: .default) { [weak self] action in
				guard let this = self else { return }
                this.leaveChannelAction(sender: nil)
			}

			var muteAction: UIAlertAction? = nil
            
            if let notifications = self.channel.notifications {
                let muted = (notifications == "none")
                let mutedTitle = muted ? "Unmute channel" : "Mute channel"
                muteAction = UIAlertAction(title: mutedTitle, style: .default) { [weak self] action in
                    guard let this = self else { return }
                    Reporting.track(muted ? "unmute_channel" : "mute_channel")
                    this.channel.mute(on: muted)
                }
            }

			let editAction = UIAlertAction(title: "Manage channel", style: .default) { [weak self] action in
				guard let this = self else { return }
				this.editChannelAction()
			}

			let browseMembersAction = UIAlertAction(title: "Channel members", style: .default) { action in
				let controller = MemberListController()
				let wrapper = AirNavigationController(rootViewController: controller)
				controller.scope = .channel
				controller.target = .channel
				UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
			}

			let inviteAction = UIAlertAction(title: "Invite to channel", style: .default) { [weak self] action in
				guard let this = self else { return }
				Reporting.track("view_channel_invite")
				let controller = ChannelInviteController()
				controller.flow = .none
				controller.inputChannelId = this.channel.id!
				controller.inputChannelTitle = this.channel.title!
				let wrapper = AirNavigationController(rootViewController: controller)
				UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
			}
            
            let profileAction = UIAlertAction(title: "Profile and settings", style: .default) { action in
                let wrapper = AirNavigationController(rootViewController: MemberViewController(userId: UserController.instance.userId!))
                UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
            }

			let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
				sheet.dismiss(animated: true, completion: nil)
			}

			if isOwner {
				if muteAction != nil {
					sheet.addAction(muteAction!)
				}
				sheet.addAction(browseMembersAction)
				sheet.addAction(inviteAction)
				if !self.channel!.general! { // Can't leave the general channel
					sheet.addAction(statusAction)
				}
				sheet.addAction(editAction) // Owners only
                sheet.addAction(profileAction)
				sheet.addAction(cancel)
			}
			else if isReader {
				if muteAction != nil {
					sheet.addAction(muteAction!)
				}
				sheet.addAction(browseMembersAction)
				if !self.channel!.general! { // Can't leave the general channel
					sheet.addAction(statusAction)
				}
                sheet.addAction(profileAction)
				sheet.addAction(cancel)
			}
			else {
				if muteAction != nil {
					sheet.addAction(muteAction!)
				}
				sheet.addAction(browseMembersAction)
				sheet.addAction(inviteAction)
				if !self.channel!.general! { // Can't leave the general channel
					sheet.addAction(statusAction)
				}
                sheet.addAction(profileAction)
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
		self.displayPhotosSorted?.removeAll()

		for data in self.queryController.items {
			let snap = data as! DataSnapshot
			let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)

			message.getCreator(with: { [weak self] user in

				guard let this = self else { return }

				remaining -= 1
				if (message.attachments?.values.first?.photo) != nil {
					message.creator = user
					let displayPhoto = DisplayPhoto(from: message)
					this.displayPhotos[message.id!] = displayPhoto
				}

				if remaining <= 0 {
					if mode == .gallery {

						if this.displayPhotos.count == 0 {
							UIShared.toast(message: "This channel needs some photos!")
							return
						}
						let layout = NHBalancedFlowLayout()
						layout.preferredRowSize = 150
						let controller = GalleryGridViewController(collectionViewLayout: layout)
						controller.displayPhotos = this.displayPhotos
						controller.inputTitle = "Channel gallery"
						let wrapper = AirNavigationController(rootViewController: controller)
						this.navigationController!.present(wrapper, animated: true, completion: nil)
					}
					else if mode == .browse {

						this.displayPhotosSorted = Array(this.displayPhotos.values).sorted(by: {
							$0.createdDateValue! > $1.createdDateValue!
						})
						var initialIndex = 0
						if initialUrl != nil {
							var index = 0
							for displayPhoto in this.displayPhotosSorted {
                                let photoUrl = (displayPhoto as! DisplayPhoto).photoURL
								if initialUrl!.absoluteString == photoUrl!.absoluteString {
									initialIndex = index
									break
								}
								index += 1
							}
						}
						let browser = PhotoBrowser(photos: this.displayPhotosSorted, animatedFrom: fromView)
						browser?.mode = .gallery
						browser?.setInitialPageIndex(UInt(initialIndex))
						browser?.useWhiteBackgroundColor = true
						browser?.usePopAnimation = true
						browser?.scaleImage = (fromView as! UIImageView).image  // Used because final image might have different aspect ratio than initially
						browser?.disableVerticalSwipe = false
						browser?.autoHideInterface = false
						browser?.delegate = self

						this.navigationController!.present(browser!, animated: true, completion: nil)
					}
				}
			})
		}
	}
    
    func configureActionButton() {
        
        /* Action button */
        self.actionButton = AirRadialMenu(attachedToView: self.tabBar!.view)
        self.actionButton.bounds.size = CGSize(width: 56, height: 56)
        self.actionButton.autoresizingMask = [.flexibleRightMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleTopMargin]
        self.actionButton.centerView.gestureRecognizers?.forEach(self.actionButton.centerView.removeGestureRecognizer) /* Remove default tap regcognizer */
        self.actionButton.imageInsets = UIEdgeInsetsMake(14, 14, 14, 14)
        self.actionButton.imageView.image = UIImage(named: "imgAddLight")	// Default
        self.actionButton.showBackground = false
        
        self.actionButton.centerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(actionButtonTapped(gesture:))))
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
}

extension MessageViewController {
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        if scrollView.contentSize.height > scrollView.height() {
            if(self.lastContentOffset > scrollView.contentOffset.y)
                && self.lastContentOffset < (scrollView.contentSize.height - scrollView.frame.height) {
                self.tabBar?.showActionButton()
            }
            else if (self.lastContentOffset < scrollView.contentOffset.y
                && scrollView.contentOffset.y >= -(self.headerHeight - 10)) {
                self.tabBar?.hideActionButton()
            }
        }
        if scrollView.contentOffset.y >= -(self.chromeHeight) {
            if self.isChromeTranslucent {
                UIView.animate(withDuration: 0.3
                    , delay: 0
                    , options: [.curveEaseInOut, .transitionCrossDissolve]
                    , animations: {
                        UIShared.styleChrome(navigationBar: self.navigationController!.navigationBar, translucent: false)
                        self.isChromeTranslucent = false
                }, completion: nil)
            }
        }
        else {
            if !self.isChromeTranslucent {
                UIView.animate(withDuration: 0.3
                    , delay: 0
                    , options: [.curveEaseInOut, .transitionCrossDissolve]
                    , animations: {
                        UIShared.styleChrome(navigationBar: self.navigationController!.navigationBar, translucent: true)
                        self.isChromeTranslucent = true
                }, completion: nil)
            }
        }
        self.lastContentOffset = scrollView.contentOffset.y
        updateHeaderView()
    }
}

extension MessageViewController {

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		/*
		 * Using an estimate significantly improves table view load time but we can get
		 * small scrolling glitches if actual height ends up different than estimated height.
		 * So we try to provide the best estimate we can and still deliver it quickly.
		 *
		 * Note: Called once only for each row in fetchResultController when FRC is making a data pass in
		 * response to managedContext.save.
		 */
		var viewHeight = CGFloat(100)
		let viewWidth = min(Config.contentWidthMax, self.tableView.width())
		let snap = self.queryController.snapshots.snapshot(at: indexPath.row)
		let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)

		if message.id != nil {
			if let cachedHeight = self.rowHeights.object(forKey: message.id!) as? CGFloat {
				return cachedHeight
			}
		}

		self.itemTemplate.bounds.size.width = viewWidth
		self.itemTemplate.bind(message: message)
		self.itemTemplate.layoutIfNeeded()

		viewHeight = self.itemTemplate.height() + 1

		if message.id != nil {
			self.rowHeights[message.id!] = viewHeight
		}

		return viewHeight
	}
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        for visibleCell in tableView.visibleCells {
//            if let cell = visibleCell as? MessageListCell {
//                cell.actionsButton.isHidden = true
//            }
//        }
//        if let cell = self.tableView.cellForRow(at: indexPath) as? MessageListCell {
//            cell.actionsButton.isHidden = false
//        }
    }
}

extension MessageViewController: FUICollectionDelegate {

	func array(_ array: FUICollection, didChange object: Any, at index: UInt) {
		let indexPath = IndexPath(row: Int(index), section: 0)
		if let cell = self.tableView.cellForRow(at: indexPath) {
			if let snap = object as? DataSnapshot {
				let cell = cell as! MessageListCell
				self.rowHeights.removeObject(forKey: snap.key)
				let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)
				message.creator = cell.message?.creator
				cell.bind(message: message)
				self.tableView.beginUpdates() // Triggers reset of row heights
				self.tableView.endUpdates()
			}
		}
	}

	func arrayDidEndUpdates(_ collection: FUICollection) {
		if ReachabilityManager.instance.isReachableViaWiFi() {
            Log.v("Prefetching message photos")
			var urls = [URL]()
			for data in self.queryController.items {
				let snap = data as! DataSnapshot
				let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)
				if let photo = message.attachments?.values.first?.photo {
					let url = ImageProxy.url(photo: photo, category: SizeCategory.standard)
					urls.append(url)
				}
			}
			SDWebImagePrefetcher.shared().prefetchURLs(urls) // method starts by clears any ongoing prefetch
			SDWebImagePrefetcher.shared().delegate = self
		}
	}
}

extension MessageViewController: SDWebImagePrefetcherDelegate {
	func imagePrefetcher(_ imagePrefetcher: SDWebImagePrefetcher, didFinishWithTotalCount totalCount: UInt, skippedCount: UInt) {
		Log.v("Channel view prefetch complete: total: \(totalCount), skipped: \(skippedCount)")
	}
}

extension MessageViewController: IDMPhotoBrowserDelegate {

	func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, captionViewForPhotoAt index: UInt) -> IDMCaptionView! {
		let captionView = CaptionView(displayPhoto: self.displayPhotosSorted![Int(index)] as! DisplayPhoto)
		captionView?.alpha = 0
		return captionView
	}

	func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, didShowPhotoAt index: UInt) {
		let index = Int(index)
		if let browser = photoBrowser as? PhotoBrowser {
			let displayPhoto = self.displayPhotosSorted![index] as! DisplayPhoto
			browser.reactionToolbar.alwaysShowAddButton = true
			browser.reactionToolbar.bind(message: displayPhoto.message!)
		}
	}
}

extension MessageViewController: TTTAttributedLabelDelegate {

	func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
		UIApplication.shared.openURL(url)
	}
}
