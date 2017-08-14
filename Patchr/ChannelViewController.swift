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
import BEMCheckBox
import PopupDialog

class ChannelViewController: BaseTableController {

	var inputChannelId: String?

	var channelQuery: ChannelQuery?
    var channel: FireChannel!

    var container: ContainerController?
	var headerView = ChannelDetailView()
    var actionButton: AirRadialMenu!
	var unreads = [String: Bool]()
	var displayPhotos = [String: DisplayPhoto]()
	var displayPhotosSorted: [Any]!
    var lastContentOffset = CGFloat(0)
    var isChromeTranslucent = false
    var postingEnabled = false

    var selectedRow: Int?

	var headerHeight = CGFloat(0)

	weak var sheetController: STPopupController!

	var backButton: UIBarButtonItem!
    var galleryButton: UIBarButtonItem!
    var editButton: UIBarButtonItem!
    var menuButton: UIBarButtonItem!

	/* Only used for row sizing */
	var rowHeights: NSMutableDictionary = [:]
	var itemTemplate = MessageListCell()

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
    
	override func viewDidLoad() {
		super.viewDidLoad()
		initialize()
        UIShared.styleChrome(navigationBar: (self.navigationController?.navigationBar)!, translucent: true)
        if let navigationController = self.navigationController as? AirNavigationController {
            navigationController.statusBarView.backgroundColor = Colors.clear
        }
		bind(channelId: self.inputChannelId!)
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
    
        if self.channel != nil && self.postingEnabled && !(self.container?.actionButtonVisible)! {
            self.container?.setActionButton(button: self.actionButton)
            self.container?.showActionButton()
        }
        
		iRate.sharedInstance().promptIfAllCriteriaMet()
		if let link = MainController.instance.link {
			MainController.instance.link = nil
			MainController.instance.routeDeepLink(link: link, error: nil)
		}
        
        if self.unreads.count > 0, let channelId = StateController.instance.channelId {
            for messageId in self.unreads.keys {
                FireController.instance.clearMessageUnread(messageId: messageId, channelId: channelId)
            }
        }
	}
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = .default

        if self.postingEnabled {
            self.container?.setActionButton(button: nil)
            self.container?.hideActionButton()
        }
        if self.isMovingFromParentViewController {
            UIShared.styleChrome(navigationBar: self.navigationController!.navigationBar, translucent: false)
            StateController.instance.clearChannel() // Only clears last channel default
        }
    }

	override func viewWillLayoutSubviews() {
        self.view.fillSuperview()
		super.viewWillLayoutSubviews()
		self.tableView.fillSuperview()
	}

	deinit {
		Log.v("ChannelViewController released: \(self.inputChannelId!)")
		unbind()
	}

	/*--------------------------------------------------------------------------------------------
	 * MARK: - Events
	 *--------------------------------------------------------------------------------------------*/

    func actionButtonTapped(gesture: UIGestureRecognizer?) {
        let controller = MessageEditViewController()
        let wrapper = AirNavigationController(rootViewController: controller)
        controller.inputChannelId = StateController.instance.channelId!
        controller.mode = .insert
        self.present(wrapper, animated: true, completion: nil)
    }
    
	func backgroundTapped(sender: AnyObject?) {
		if let controller = self.sheetController {
			controller.dismiss()
		}
	}

    func backAction(sender: AnyObject?) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func browseCommentsAction(sender: AnyObject?) {
        if let control = sender as? CommentsButton {
            showComments(message: control.message)
        }
    }

	func browseMemberAction(sender: AnyObject?) {
		if let photoControl = sender as? PhotoControl {
			if let user = photoControl.target as? FireUser {
                let controller = MemberViewController(userId: user.id)
                let wrapper = AirNavigationController(rootViewController: controller)
				Reporting.track("view_group_member")
                self.present(wrapper, animated: true, completion: nil)
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

    func editChannelAction(sender: AnyObject?) {
		let controller = ChannelEditViewController()
		let wrapper = AirNavigationController(rootViewController: controller)
		controller.mode = .update
		controller.inputChannelId = self.channel.id
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
                            self?.close()
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
                self.view.endEditing(true)
				let cell = self.tableView.cellForRow(at: indexPath) as! MessageListCell
				let snap = self.queryController.snapshot(at: indexPath.row)
				let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)
				Reporting.track("view_message_actions")
				showMessageActions(message: message, sourceView: cell.contentView)
			}
		}
	}

    func openGalleryAction(sender: AnyObject?) {
        Reporting.track("view_photo_gallery")
        showPhotos(mode: .gallery)
    }

	/*--------------------------------------------------------------------------------------------
	* MARK: - Notifications
	*--------------------------------------------------------------------------------------------*/

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

		self.automaticallyAdjustsScrollViewInsets = false
		let viewWidth = min(Config.contentWidthMax, self.view.width())

		self.headerHeight = viewWidth * 0.625

		updateHeaderView()
        
        self.container = MainController.instance.containerController
        if self.container != nil {
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
        
        self.view.addSubview(self.tableView)

		self.itemTemplate.template = true
        
        /* Back to channels button */
        var button = UIButton(type: .custom)
        button.setImage(#imageLiteral(resourceName: "imgArrowLeftLight"), for: .normal)
        button.setTitle("Channels", for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 0, 8, 100)
        button.titleEdgeInsets = UIEdgeInsetsMake(0, -36, 0, 0)
        button.frame = CGRect(x: 0, y: 0, width: 120, height: 36)
        button.addTarget(self, action: #selector(backAction(sender:)), for: .touchUpInside)
        self.backButton = UIBarButtonItem(customView: button)

        /* Edit button */
        button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        button.addTarget(self, action: #selector(editChannelAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(#imageLiteral(resourceName: "imgEdit2Light"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 0, 8, 16)
        self.editButton = UIBarButtonItem(customView: button)
        
		/* Gallery button */
		button = UIButton(type: .custom)
		button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
		button.addTarget(self, action: #selector(openGalleryAction(sender:)), for: .touchUpInside)
		button.showsTouchWhenHighlighted = true
		button.setImage(#imageLiteral(resourceName: "imgGallery2Light"), for: .normal)
		button.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
		self.galleryButton = UIBarButtonItem(customView: button)

		/* Menu button */
		button = UIButton(type: .custom)
		button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
		button.addTarget(self, action: #selector(showChannelActions(sender:)), for: .touchUpInside)
		button.showsTouchWhenHighlighted = true
		button.setImage(UIImage(named: "imgOverflowVerticalLight"), for: .normal)
		button.imageEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 0)
		self.menuButton = UIBarButtonItem(customView: button)
        
        self.navigationItem.hidesBackButton = true
        self.navigationItem.setLeftBarButton(backButton, animated: true)
		self.navigationItem.setRightBarButtonItems([self.menuButton, UI.spacerFixed, self.galleryButton], animated: true)

		NotificationCenter.default.addObserver(self, selector: #selector(messageDidChange(notification:)), name: NSNotification.Name(rawValue: Events.MessageDidUpdate), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(userDidUpdate(notification:)), name: NSNotification.Name(rawValue: Events.UserDidUpdate), object: nil)
	}

	fileprivate func bind(channelId: String) {

		/* Only called once */

		Log.v("Binding to: \(channelId)")
		let userId = UserController.instance.userId!
		let query = FireController.db.child("channel-messages/\(channelId)").queryOrdered(byChild: "created_at_desc")
		self.queryController = DataSourceController(name: "channel_view")
		self.queryController.bind(to: self.tableView, query: query) { [weak self] scrollView, indexPath, data in

			/* If cell.prepareToReuse is called, userQuery observer is removed */
            let tableView = scrollView as! UITableView
			let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MessageListCell
			guard let this = self else { return cell }

            cell.reset()    // Releases previous data observers
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
                
                /* Comments */
                cell.commentsButton.addTarget(this, action: #selector(this.browseCommentsAction(sender:)), for: .touchUpInside)
                
			})
			return cell
		}

		self.queryController.delegate = self

		/* Header */

		self.channelQuery = ChannelQuery(channelId: channelId, userId: userId)
		self.channelQuery!.observe(with: { [weak self] error, channel in

			guard let this = self else { return }
			guard channel != nil else {
                this.backAction(sender: nil)
				return
			}

			this.channel = channel
			this.navigationController?.navigationBar.setNeedsLayout()
            
            if this.channel.role == "reader" {
                this.postingEnabled = false
            }
            else {
                this.postingEnabled = true
                this.container?.setActionButton(button: this.actionButton)
                this.container?.showActionButton()
            }
            
            /* Add edit button */
            if this.isOwner() {
                this.navigationItem.setRightBarButtonItems([this.menuButton, UI.spacerFixed, this.galleryButton, UI.spacerFixed, this.editButton], animated: true)
            }
            
			/* We do this here so we have tableView sizing */
			Log.v("Bind channel header")

			this.headerView.bind(channel: this.channel)

			if this.channel.purpose != nil {
				let viewWidth = min(Config.contentWidthMax, this.view.width())
				this.headerView.purposeLabel.bounds.size.width = viewWidth - 32
				this.headerView.purposeLabel.sizeToFit()
				this.headerView.purposeLabel.anchorTopLeft(withLeftPadding: 12
						, topPadding: 12
						, width: this.headerView.purposeLabel.width()
						, height: this.headerView.purposeLabel.height())

				let infoHeight = this.headerView.purposeLabel.height() + 24
				this.headerHeight = (viewWidth * 0.625) + infoHeight
                this.tableView.contentInset = UIEdgeInsets(top: this.headerHeight, left: 0, bottom: 0, right: 0)
                this.tableView.contentOffset = CGPoint(x: 0, y: -(this.headerHeight))
				this.updateHeaderView()
			}
		})

		Log.v("Observe query triggered for channel messages")
	}

	func unbind() {
		if self.queryController != nil {
			self.queryController.unbind()
		}
		self.channelQuery?.remove()
	}
    
    func isOwner() -> Bool {
        return (self.channel.role == "owner" || self.channel.ownedBy == UserController.instance.userId)
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
        if message.createdBy != userId && !isOwner() { return }
		let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
		let edit = UIAlertAction(title: "Edit message", style: .default) { [weak self] action in
            
            guard let this = self else { return }
            Reporting.track("view_message_edit")
            let controller = MessageEditViewController()
            controller.inputMessageId = message.id!
            controller.inputChannelId = message.channelId!
            controller.mode = .update
            let wrapper = AirNavigationController(rootViewController: controller)
            this.present(wrapper, animated: true, completion: nil)
		}
        
        let move = UIAlertAction(title: "Move to", style: .default) { [weak self] action in
            guard let this = self else { return }
            let controller = ChannelPickerController()
            let popup = PopupDialog(viewController: controller, gestureDismissal: false) {
                guard let channel = controller.selectedChannel else { return }
                let fromChannelId = message.channelId!
                let toChannelId = channel.id!
                FireController.instance.moveMessage(message: message, fromChannelId: fromChannelId, toChannelId: toChannelId)
                { error in
                    if error == nil {
                        UIShared.toast(message: "Message moved to: \(channel.title!)", duration: 2.0, controller: self, addToWindow: false)
                        Log.v("Copy message to channel: \(channel.id!)")
                        Reporting.track("move_message")
                    }
                }
            }
            let cancel = DefaultButton(title: "Cancel".uppercased(), height: 48) {
                Log.v("Cancel copy")
            }
            cancel.buttonHeight = 48
            popup.addButton(cancel)
            controller.popup = popup
            this.present(popup, animated: true)
        }
        
		let delete = UIAlertAction(title: "Delete message", style: .destructive) { [weak self] action in
            guard let this = self else { return }
			this.deleteMessage(message: message)
		}
        
		let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
			sheet.dismiss(animated: true, completion: nil)
		}

		if message.createdBy == userId {
			sheet.addAction(edit)
            sheet.addAction(move)
			sheet.addAction(delete)
			sheet.addAction(cancel)
		}
		else if isOwner() {
			sheet.addAction(delete)
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
			let isOwner = self.isOwner()
            
			let statusAction = UIAlertAction(title: "Leave", style: .default) { [weak self] action in
				guard let this = self else { return }
                this.leaveChannelAction(sender: nil)
			}

			var muteAction: UIAlertAction? = nil
            
            if let notifications = self.channel.notifications {
                let muted = (notifications == "none")
                let mutedTitle = muted ? "Unmute" : "Mute"
                muteAction = UIAlertAction(title: mutedTitle, style: .default) { [weak self] action in
                    guard let this = self else { return }
                    Reporting.track(muted ? "unmute_channel" : "mute_channel")
                    this.channel.mute(on: muted)
                }
            }

			let browseMembersAction = UIAlertAction(title: "Members", style: .default) { [weak self] action in
                guard let this = self else { return }
				let controller = MemberListController()
                controller.scope = .channel
                controller.manage = isOwner
				let wrapper = AirNavigationController(rootViewController: controller)
                this.present(wrapper, animated: true, completion: nil)
			}

			let inviteAction = UIAlertAction(title: "Invite", style: .default) { [weak self] action in
				guard let this = self else { return }
				Reporting.track("view_channel_invite")
				let controller = InviteViewController()
				controller.flow = .none
                controller.inputCode = this.channel.code!
				controller.inputChannelId = this.channel.id!
				controller.inputChannelTitle = this.channel.title!
				let wrapper = AirNavigationController(rootViewController: controller)
				this.present(wrapper, animated: true, completion: nil)
			}
            
            let profileAction = UIAlertAction(title: "Profile and settings", style: .default) { [weak self] action in
                guard let this = self else { return }
                let wrapper = AirNavigationController(rootViewController: MemberViewController(userId: UserController.instance.userId!))
                this.present(wrapper, animated: true, completion: nil)
            }

			let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
				sheet.dismiss(animated: true, completion: nil)
			}

			if isOwner {
				sheet.addAction(muteAction!)
				sheet.addAction(browseMembersAction)
                sheet.addAction(inviteAction) // Onwers only
                if self.channel.ownedBy != UserController.instance.userId {
                    sheet.addAction(statusAction)
                }
                sheet.addAction(profileAction)
				sheet.addAction(cancel)
			}
            else {  // Editor or reader
				sheet.addAction(muteAction!)
				sheet.addAction(browseMembersAction)
                sheet.addAction(statusAction)
                sheet.addAction(profileAction)
				sheet.addAction(cancel)
			}

			if let presenter = sheet.popoverPresentationController {
				presenter.sourceView = self.menuButton.customView
				presenter.sourceRect = (self.menuButton.customView?.bounds)!
			}

			present(sheet, animated: true, completion: nil)
		}
	}
    
    func showComments(message: FireMessage) {
        Reporting.track("view_comment_list")
        let controller = MessageViewController()
        controller.inputMessageId = message.id!
        controller.inputChannelId = message.channelId!
        controller.contentSizeInPopup = CGSize(width: Config.screenWidth, height: Config.screenHeight * 0.40 )
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = Colors.opacity25pcntBlack
        
        let popController = STPopupController(rootViewController: controller)
        popController.style = .bottomSheet
        popController.backgroundView = backgroundView
        popController.hidesCloseButton = true
        
        self.sheetController = popController
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.backgroundTapped(sender:)))
        self.sheetController.backgroundView?.addGestureRecognizer(tap)
        self.sheetController.present(in: self)
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

    func deleteMessage(message: FireMessage) {
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

    func configureActionButton() {
        
        /* Action button */
        self.actionButton = AirRadialMenu(attachedToView: self.container!.view)
        self.actionButton.bounds.size = CGSize(width: 56, height: 56)
        self.actionButton.autoresizingMask = [.flexibleRightMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleTopMargin]
        self.actionButton.centerView.gestureRecognizers?.forEach(self.actionButton.centerView.removeGestureRecognizer) /* Remove default tap regcognizer */
        self.actionButton.imageInsets = UIEdgeInsetsMake(18, 20, 18, 16)
        self.actionButton.imageView.image = #imageLiteral(resourceName: "imgAddMessageLight")	// Default
        self.actionButton.imageView.tintColor = Colors.black
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

extension ChannelViewController {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if self.postingEnabled {
            if scrollView.contentSize.height > scrollView.height() {
                if(self.lastContentOffset > scrollView.contentOffset.y)
                    && self.lastContentOffset < (scrollView.contentSize.height - scrollView.frame.height) {
                    self.container?.showActionButton()
                }
                else if (self.lastContentOffset < scrollView.contentOffset.y
                    && scrollView.contentOffset.y >= -(self.headerHeight - 10)) {
                    self.container?.hideActionButton()
                }
            }
        }
        
        if scrollView.contentOffset.y >= -(self.chromeHeight) {
            if self.isChromeTranslucent {
                UIView.animate(withDuration: 0.3
                    , delay: 0
                    , options: [.curveEaseInOut, .transitionCrossDissolve]
                    , animations: {
                        UIApplication.shared.statusBarStyle = .default
                        if let backButton = self.backButton?.customView as? UIButton {
                            backButton.tintColor = Colors.black
                            backButton.setTitleColor(Colors.black, for: .normal)
                        }
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
                        UIApplication.shared.statusBarStyle = .lightContent
                        if let backButton = self.backButton?.customView as? UIButton {
                            backButton.tintColor = Colors.white
                            backButton.setTitleColor(Colors.white, for: .normal)
                        }
                        UIShared.styleChrome(navigationBar: self.navigationController!.navigationBar, translucent: true)
                        self.isChromeTranslucent = true
                }, completion: nil)
            }
        }
        self.lastContentOffset = scrollView.contentOffset.y
        updateHeaderView()
    }
}

extension ChannelViewController: UITableViewDelegate {

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

extension ChannelViewController: FUICollectionDelegate {

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

extension ChannelViewController: SDWebImagePrefetcherDelegate {
	func imagePrefetcher(_ imagePrefetcher: SDWebImagePrefetcher, didFinishWithTotalCount totalCount: UInt, skippedCount: UInt) {
		Log.v("Channel view prefetch complete: total: \(totalCount), skipped: \(skippedCount)")
	}
}

extension ChannelViewController: IDMPhotoBrowserDelegate {

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

extension ChannelViewController: TTTAttributedLabelDelegate {

	func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
		UIApplication.shared.openURL(url)
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
