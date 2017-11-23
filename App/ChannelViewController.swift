//
//  ChanneliewController.swift
//

import UIKit
import AMScrollingNavbar
import MessageUI
import iRate
import IDMPhotoBrowser
import Localize_Swift
import NHBalancedFlowLayout
import Firebase
import FirebaseDatabaseUI
import TTTAttributedLabel
import STPopup
import BEMCheckBox
import PopupDialog
import StoreKit

class ChannelViewController: UICollectionViewController { // Sets itself as data source and delegate

	var inputChannelId: String?

	var channel: FireChannel!

	var authHandle: AuthStateDidChangeListenerHandle!
	var queryController: DataSourceController!
	var channelQuery: ChannelQuery?
	var unreadQuery: UnreadQuery?
	var unreadsChannelTotal = 0

	var container: ContainerController?
	var chromeBackground = UIView(frame: .zero)
	var headerView = ChannelDetailView()
	var actionButton: AirRadialMenu!
	weak var sheetController: STPopupController!

	var backButtonView: ChannelBackView!
	var backButton: UIBarButtonItem!
	var galleryButton: UIBarButtonItem!
	var editButton: UIBarButtonItem!
	var menuButton: UIBarButtonItem!

	var displayPhotos = [String: DisplayPhoto]()
	var displayPhotosSorted: [Any]!
	var lastContentOffset = CGFloat(0)
	var isChromeTranslucent = false
	var postingEnabled = false
	var selectedRow: Int?
    var headerHeight = CGFloat(0)

	/* Only used for row sizing */
	var itemHeights: NSMutableDictionary = [:]
	var itemTemplate = MessageListCell()

	fileprivate var sectionInsets: UIEdgeInsets?

	/*--------------------------------------------------------------------------------------------
	 * MARK: - Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	init(channelId: String?) {
		self.inputChannelId = channelId
		super.init(collectionViewLayout: UICollectionViewLayout())
	}

	required init?(coder decoder: NSCoder) {
		/* Needed because base protocol requires it and we are providing our own init */
		fatalError("NSCoding (storyboards) not supported")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		initialize()
        UIApplication.shared.statusBarStyle = .lightContent
		UIShared.styleChrome(navigationBar: (self.navigationController?.navigationBar)!, translucent: true)
		bind(channelId: self.inputChannelId!)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if self.channel != nil && self.postingEnabled && !(self.container?.actionButtonVisible)! {
			self.container?.setActionButton(button: self.actionButton)
			self.container?.showActionButton()
		}
        if #available(iOS 10.3, *) {
            if Utils.getUserActionsCount() >= Config.reviewRequestTriggerCount {
                Log.d("Patchr review requested")
                SKStoreReviewController.requestReview()
                Utils.resetUserActionsCount()
            }
        }
        else {
            iRate.sharedInstance().promptIfAllCriteriaMet()
        }
		if let link = MainController.instance.link {
			MainController.instance.link = nil
			MainController.instance.routeDeepLink(link: link, error: nil)
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if self.postingEnabled {
			self.container?.setActionButton(button: nil)
			self.container?.hideActionButton()
		}
		if self.isMovingFromParentViewController {
            UIShared.styleChrome(navigationBar: self.navigationController!.navigationBar, translucent: false)
			StateController.instance.clearChannel() // Only clears last channel default
		}
	}
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true)
        }
    }

	override func viewWillLayoutSubviews() {

		/* view -> contentView -> tableView -> headerView
		   view -> chromeBackground */

		self.view.fillSuperview()
        self.chromeBackground.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 64)
		let viewWidth = min(Config.contentWidthMax, self.view.width())
		self.collectionView?.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: self.view.height())
        updateHeaderView()
	}

	deinit {
		Log.v("ChannelViewController released: \(self.inputChannelId!)")
		unbind()
	}

	/*--------------------------------------------------------------------------------------------
	 * MARK: - Events
	 *--------------------------------------------------------------------------------------------*/

	@objc func actionButtonTapped(gesture: UIGestureRecognizer?) {
		let controller = MessageEditViewController()
		let wrapper = AirNavigationController(rootViewController: controller)
		controller.inputChannelId = StateController.instance.channelId!
		controller.mode = .insert
		self.present(wrapper, animated: true, completion: nil)
	}

	@objc func backgroundTapped(sender: AnyObject?) {
		if let controller = self.sheetController {
			controller.dismiss()
		}
	}

	@objc func backAction(sender: AnyObject?) {
		let _ = self.navigationController?.popViewController(animated: true)
	}

	@objc func browseCommentsAction(sender: AnyObject?) {
		if let control = sender as? CommentsButton {
			showComments(message: control.message)
		}
	}

	@objc func browseMemberAction(sender: AnyObject?) {
		if let photoControl = sender as? PhotoControl {
			if let user = photoControl.target as? FireUser {
				let controller = MemberViewController(userId: user.id)
				let wrapper = AirNavigationController(rootViewController: controller)
				Reporting.track("view_group_member")
				self.present(wrapper, animated: true, completion: nil)
			}
		}
	}

	@objc func browsePhotoAction(sender: AnyObject?) {
		if let recognizer = sender as? UITapGestureRecognizer,
		   let control = recognizer.view as? AirImageView,
		   let url = control.fromUrl {
			Reporting.track("view_photos")
			showPhotos(mode: .browse, fromView: control, initialUrl: url)
		}
	}

	@objc func editChannelAction(sender: AnyObject?) {
		Reporting.track("view_channel_edit")
		let controller = ChannelEditViewController()
		let wrapper = AirNavigationController(rootViewController: controller)
		controller.mode = .update
		controller.inputChannelId = self.channel.id
		self.present(wrapper, animated: true, completion: nil)
	}

	func leaveChannelAction(sender: AnyObject?) {

        deleteConfirmationAlert(
				title: "confirm".localized(),
				message: "channel_leave_message".localized(),
				actionTitle: "leave".localized(), cancelTitle: "cancel".localized(), delegate: self) { doIt in
			if doIt {
				let userId = UserController.instance.userId!
				Reporting.track("leave_channel")
				self.unbind()
				FireController.instance.deleteMembership(userId: userId, channelId: self.channel.id!, then: { [weak self] error, result in
					guard self != nil else { return }
					if error == nil {
						UIShared.toast(message: "channel_left_message".localized())
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

	@objc func longPressAction(sender: UILongPressGestureRecognizer) {
		if sender.state == UIGestureRecognizerState.began {
			let point = sender.location(in: self.collectionView)
			if let indexPath = self.collectionView?.indexPathForItem(at: point) {
				self.view.endEditing(true)
				let cell = self.collectionView?.cellForItem(at: indexPath) as! MessageListCell
				let snap = self.queryController.snapshot(at: indexPath.row)
				let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)
				Reporting.track("view_message_actions")
				showMessageActions(message: message, sourceView: cell.contentView)
			}
		}
	}

	@objc func openGalleryAction(sender: AnyObject?) {
		Reporting.track("view_photo_gallery")
		showPhotos(mode: .gallery)
	}

	/*--------------------------------------------------------------------------------------------
	* MARK: - Notifications
	*--------------------------------------------------------------------------------------------*/

	@objc func messageDidChange(notification: NSNotification) {
		if let userInfo = notification.userInfo, let messageId = userInfo["message_id"] as? String {
			self.itemHeights.removeObject(forKey: messageId)
		}
	}

	@objc func userDidUpdate(notification: NSNotification) {
		self.collectionView?.reloadData()
	}

	@objc func unreadChange(notification: NSNotification?) {
		/* Triggered when counter observer in user controller get a callback with changed count. */
		var badgeTotal = UserController.instance.unreads!
		if self.unreadsChannelTotal > 0 {
			badgeTotal -= self.unreadsChannelTotal
		}
		if badgeTotal > 0 {
			self.backButtonView.badge.text = "\(badgeTotal)"
			self.backButtonView.badgeIsHidden = false
		}
		else {
			self.backButtonView.badge.text = nil
			self.backButtonView.badgeIsHidden = true
		}
	}

	/*--------------------------------------------------------------------------------------------
	 * MARK: - Methods
	 *--------------------------------------------------------------------------------------------*/

	func initialize() {

		let viewWidth = min(Config.contentWidthMax, self.view.width())

        if #available(iOS 11.0, *) {
            self.collectionView!.contentInsetAdjustmentBehavior = .never
        }
        else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
		self.view.backgroundColor = Theme.colorBackgroundWindow
		self.headerHeight = viewWidth * 0.625
        self.sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

		updateHeaderView()

		self.container = MainController.instance.containerController
		if self.container != nil {
			configureActionButton()
		}
        
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.scrollingNavbarDelegate = self
        }

        self.chromeBackground.backgroundColor = Colors.accentColor
        self.view.addSubview(self.chromeBackground)
        self.view.sendSubview(toBack: self.chromeBackground)

		self.collectionView?.addSubview(self.headerView)
        
        let layout = UICollectionViewFlowLayout()
		layout.itemSize = CGSize(width: viewWidth, height: 100)
		layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = 0

		self.collectionView?.backgroundColor = Colors.gray95pcntColor
		self.collectionView?.collectionViewLayout = layout
		self.collectionView?.contentInset = UIEdgeInsets(top: self.headerHeight, left: 0, bottom: 0, right: 0)
		self.collectionView?.contentOffset = CGPoint(x: 0, y: -(self.headerHeight))
		self.collectionView?.register(MessageListCell.self, forCellWithReuseIdentifier: "cell")

		self.itemTemplate.template = true

		/* Back to channels button */

		self.backButtonView = ChannelBackView()
		self.backButtonView.frame = CGRect(x: 0, y: 0, width: 120, height: 36)
        self.backButtonView.buttonScrim.addTarget(self, action: #selector(backAction(sender:)), for: .touchUpInside)
		self.backButton = UIBarButtonItem(customView: self.backButtonView)

		if UserController.instance.unreads! > 0 {
			self.backButtonView.badge.text = "\(UserController.instance.unreads!)"
			self.backButtonView.badgeIsHidden = false
		}
		else {
			self.backButtonView.badge.text = nil
			self.backButtonView.badgeIsHidden = true
		}

		/* Edit button */
		var button = UIButton(type: .custom)
		button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
		button.addTarget(self, action: #selector(editChannelAction(sender:)), for: .touchUpInside)
		button.showsTouchWhenHighlighted = true
		button.setImage(#imageLiteral(resourceName:"imgEdit2Light"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
		button.imageEdgeInsets = UIEdgeInsetsMake(8, 0, 8, 16)
		self.editButton = UIBarButtonItem(customView: button)

		/* Gallery button */
		button = UIButton(type: .custom)
		button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
		button.addTarget(self, action: #selector(openGalleryAction(sender:)), for: .touchUpInside)
		button.showsTouchWhenHighlighted = true
		button.setImage(#imageLiteral(resourceName:"imgGallery2Light"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
		self.galleryButton = UIBarButtonItem(customView: button)

		/* Menu button */
		button = UIButton(type: .custom)
		button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
		button.addTarget(self, action: #selector(showChannelActions(sender:)), for: .touchUpInside)
		button.showsTouchWhenHighlighted = true
		button.setImage(UIImage(named: "imgOverflowVerticalLight"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
		button.imageEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 0)
		self.menuButton = UIBarButtonItem(customView: button)

		self.headerView.setPhotoButton.addTarget(self, action: #selector(editChannelAction(sender:)), for: .touchUpInside)

		self.navigationItem.hidesBackButton = true
		self.navigationItem.setLeftBarButton(self.backButton, animated: true)
		self.navigationItem.setRightBarButtonItems([self.menuButton, UI.spacerFixed, self.galleryButton], animated: true)

		NotificationCenter.default.addObserver(self, selector: #selector(messageDidChange(notification:)), name: NSNotification.Name(rawValue: Events.MessageDidUpdate), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(userDidUpdate(notification:)), name: NSNotification.Name(rawValue: Events.UserDidUpdate), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(bindLanguage), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(unreadChange(notification:)), name: NSNotification.Name(rawValue: Events.UnreadChange), object: nil)
		bindLanguage()
	}

	func bind(channelId: String) {

		/* Only called once */

		Log.v("Binding to: \(channelId)")

		let userId = UserController.instance.userId!

		var badgeTotal = UserController.instance.unreads!
		self.unreadQuery = UnreadQuery(level: .channel, userId: userId, channelId: channelId)
		self.unreadQuery!.observe(with: { [weak self] error, channelTotal in
			guard let this = self else { return }
			if channelTotal != nil {
				self?.unreadsChannelTotal = channelTotal!
				if channelTotal! > 0 {
					badgeTotal -= channelTotal!
				}
			}
			if badgeTotal > 0 {
				this.backButtonView.badge.text = "\(badgeTotal)"
				this.backButtonView.badgeIsHidden = false
			}
			else {
				this.backButtonView.badge.text = nil
				this.backButtonView.badgeIsHidden = true
			}
		})

		let query = FireController.db.child("channel-messages/\(channelId)").queryOrdered(byChild: "created_at_desc")
		self.queryController = DataSourceController(name: "channel_view")
		self.queryController.delegate = self
		self.queryController.bind(to: self.collectionView!, query: query) { [weak self] scrollView, indexPath, data in

			/* If cell.prepareToReuse is called, userQuery observer is removed */
			let collectionView = scrollView as! UICollectionView
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MessageListCell
			cell.reset()    // Releases previous data observers

			guard let this = self else { return cell }

			let snap = data as! DataSnapshot
			let userId = UserController.instance.userId!
			let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)

			guard message.createdBy != nil else {
				return cell
			}

			cell.inputUserQuery = UserQuery(userId: message.createdBy!)
			cell.inputUserQuery.once(with: { [weak this, weak cell] error, user in

				guard let this = this else { return }
				guard let cell = cell else { return }

				message.creator = user

				if user == nil {
					Log.v("Message \(message.id!) missing creator")
				}

				if !cell.decorated {

					let recognizer = UILongPressGestureRecognizer(target: this, action: #selector(this.longPressAction(sender:)))
					recognizer.minimumPressDuration = TimeInterval(0.2)
					cell.addGestureRecognizer(recognizer)

					if let label = cell.description_ as? TTTAttributedLabel {
						label.delegate = this
					}

					cell.imageView?.isUserInteractionEnabled = true
					cell.imageView?.addGestureRecognizer(UITapGestureRecognizer(target: this, action: #selector(this.browsePhotoAction(sender:))))
					cell.decorated = true
				}

                cell.bind(message: message) // Handles hide/show of actions button based on message.selected

				/* Unread handling */

				let messageId = message.id!

				cell.inputUnreadQuery = UnreadQuery(level: .message, userId: userId, channelId: channelId, messageId: messageId)
				cell.inputUnreadQuery!.observe(with: { [weak cell] error, total in
					guard let cell = cell else { return }
					if total != nil && total! > 0 {
						cell.isUnread = true
						FireController.instance.clearMessageUnread(messageId: messageId, channelId: channelId)
					}
				})

				if message.creator != nil {
					cell.userPhotoControl.target = message.creator
					cell.userPhotoControl.addTarget(this, action: #selector(this.browseMemberAction(sender:)), for: .touchUpInside)
				}

				/* Comments */
				cell.commentsButton.addTarget(this, action: #selector(this.browseCommentsAction(sender:)), for: .touchUpInside)
			})
			return cell
		}

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

			if this.channel.membership?.role == "reader" {
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
				if channel?.photo == nil {
					this.headerView.setPhotoButton.fadeIn()
				}
				else {
					this.headerView.setPhotoButton.fadeOut()
				}
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
				this.collectionView?.contentInset = UIEdgeInsets(top: this.headerHeight, left: 0, bottom: 0, right: 0)
				this.collectionView?.contentOffset = CGPoint(x: 0, y: -(this.headerHeight))
			}
			this.updateHeaderView()
		})

		Log.v("Observe query triggered for channel messages")
	}

	@objc func bindLanguage() {
		let button = self.backButton.customView as! ChannelBackView
		button.label.text = "channels".localized()
	}

	func unbind() {
		if self.queryController != nil {
			self.queryController.unbind()
		}
		self.channelQuery?.remove()
	}

	func isOwner() -> Bool {
		if let membership = self.channel.membership {
			return (membership.role == "owner" || self.channel.ownedBy == UserController.instance.userId)
		}
		return false
	}

	func updateHeaderView() {
		var headerRect = CGRect(x: 0, y: -self.headerHeight, width: self.collectionView!.width(), height: self.headerHeight)
		if self.collectionView!.contentOffset.y < -(self.headerHeight) {
			headerRect.origin.y = (self.collectionView!.contentOffset.y)
			headerRect.size.height = -(self.collectionView!.contentOffset.y)
		}
		self.headerView.frame = headerRect
	}

	func showMessageActions(message: FireMessage, sourceView: UIView?) {

		let userId = UserController.instance.userId!
		if message.createdBy != userId && !isOwner() { return }
		let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

		let edit = UIAlertAction(title: "edit_message".localized(), style: .default) { [weak self] action in

			guard let this = self else { return }
			Reporting.track("view_message_edit")
			let controller = MessageEditViewController()
			controller.inputMessageId = message.id!
			controller.inputChannelId = message.channelId!
			controller.mode = .update
			let wrapper = AirNavigationController(rootViewController: controller)
			this.present(wrapper, animated: true, completion: nil)
		}

		let move = UIAlertAction(title: "message_move_to".localized(), style: .default) { [weak self] action in
			guard let this = self else { return }
			let controller = ChannelPickerController()
			let popup = PopupDialog(viewController: controller, gestureDismissal: false) {
				guard let channel = controller.selectedChannel else { return }
				let fromChannelId = message.channelId!
				let toChannelId = channel.id!
				let channelTitle = channel.title!
				FireController.instance.moveMessage(message: message, fromChannelId: fromChannelId, toChannelId: toChannelId) { error in
					if error == nil {
						UIShared.toast(message: "message_moved".localizedFormat(channelTitle), duration: 2.0, controller: this, addToWindow: false)
						Log.v("Copy message to channel: \(toChannelId)")
						Reporting.track("move_message")
					}
				}
			}
			let cancel = DefaultButton(title: "cancel".localized().uppercased(), height: 48) {
				Log.v("Cancel copy")
			}
			cancel.buttonHeight = 48
			popup.addButton(cancel)
			controller.popup = popup
			this.present(popup, animated: true)
		}

		let delete = UIAlertAction(title: "message_delete".localized(), style: .destructive) { [weak self] action in
			guard let this = self else { return }
			this.deleteMessage(message: message)
		}

		let cancel = UIAlertAction(title: "cancel".localized(), style: .cancel) { action in
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

	@objc func showChannelActions(sender: AnyObject?) {

		Reporting.track("view_channel_actions")

		if self.channel != nil {

			let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
			let isOwner = self.isOwner()

			let statusAction = UIAlertAction(title: "leave".localized(), style: .default) { [weak self] action in
				guard let this = self else { return }
				this.leaveChannelAction(sender: nil)
			}

			var muteAction: UIAlertAction? = nil

			if let notifications = self.channel.membership?.notifications {
				let muted = (notifications == "none")
				let mutedTitle = muted ? "unmute".localized() : "mute".localized()
				muteAction = UIAlertAction(title: mutedTitle, style: .default) { [weak self] action in
					guard let this = self else { return }
					Reporting.track(muted ? "unmute_channel" : "mute_channel")
					this.channel.mute(on: muted)
				}
			}

			let browseMembersAction = UIAlertAction(title: "members".localized(), style: .default) { [weak self] action in
				guard let this = self else { return }
				let controller = MemberListController()
				controller.scope = .channel
				controller.manage = isOwner
				let wrapper = AirNavigationController(rootViewController: controller)
				this.present(wrapper, animated: true, completion: nil)
			}

			let inviteAction = UIAlertAction(title: "invite".localized(), style: .default) { [weak self] action in
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

			let profileAction = UIAlertAction(title: "profile_and_settings".localized(), style: .default) { [weak self] action in
				guard let this = self else { return }
				let wrapper = AirNavigationController(rootViewController: MemberViewController(userId: UserController.instance.userId!))
				this.present(wrapper, animated: true, completion: nil)
			}

			let cancel = UIAlertAction(title: "cancel".localized(), style: .cancel) { action in
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
		let controller = CommentListController()
		controller.inputMessageId = message.id!
		controller.inputChannelId = message.channelId!

		let backgroundView = UIView()
		backgroundView.backgroundColor = Colors.opacity25pcntBlack

		let popController = STPopupController(rootViewController: controller)
		popController.style = .formSheet
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

		if self.queryController.items.count == 0 {
			if mode == .gallery {
				UIShared.toast(message: "channel_no_photos".localized())
			}
			return
		}

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
							UIShared.toast(message: "channel_no_photos".localized())
							return
						}
						let layout = NHBalancedFlowLayout()
						layout.preferredRowSize = 150
						let controller = GalleryGridViewController(collectionViewLayout: layout)
						controller.displayPhotos = this.displayPhotos
						controller.inputTitle = "gallery_title".localized()
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
                        if let browser = PhotoBrowser(photos: this.displayPhotosSorted, animatedFrom: fromView) {
                            browser.mode = .gallery
                            browser.setInitialPageIndex(UInt(initialIndex))
                            browser.useWhiteBackgroundColor = true
                            browser.usePopAnimation = true
                            browser.scaleImage = (fromView as! UIImageView).image  // Used because final image might have different aspect ratio than initially
                            browser.disableVerticalSwipe = false
                            browser.autoHideInterface = false
                            browser.delegate = self
                            this.navigationController!.present(browser, animated: true, completion: nil)
                        }
					}
				}
			})
		}
	}

    func deleteMessage(message: FireMessage) {
        deleteConfirmationAlert(
				title: "channel_delete_title".localized(),
				message: "channel_delete_message".localized(),
				actionTitle: "delete".localized(), cancelTitle: "cancel".localized(), delegate: self) {
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
		self.actionButton.imageView.image = #imageLiteral(resourceName:"imgAddMessageLight")    // Default
		self.actionButton.imageView.tintColor = Colors.black
		self.actionButton.showBackground = false

		self.actionButton.centerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(actionButtonTapped(gesture:))))
	}
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return (self.navigationController?.navigationBar.isTranslucent)! ? .lightContent : .default
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
}

/*--------------------------------------------------------------------------------------------
 * MARK: - Delegates
 *--------------------------------------------------------------------------------------------*/

extension ChannelViewController: ScrollingNavigationControllerDelegate {
    
    func scrollingNavigationController(_ controller: ScrollingNavigationController, didChangeState state: NavigationBarState) {
        switch state {
        case .collapsed:
            Log.v("Navbar collapsed")
        case .expanded:
            Log.v("Navbar expanded")
        case .scrolling:
            Log.v("Navbar is moving")
        }
    }
}

extension ChannelViewController { // UIScrollViewDelegate

	override func scrollViewDidScroll(_ scrollView: UIScrollView) {

		if self.postingEnabled {
			if scrollView.contentSize.height > scrollView.height() {
				if (self.lastContentOffset > scrollView.contentOffset.y)
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
					, animations: { [weak self] in
                        guard let this = self else { return }
                        UIApplication.shared.statusBarStyle = .default
                        if let backButton = this.backButton?.customView as? ChannelBackView {
                            backButton.label.textColor = Colors.black
                            backButton.backImage.tintColor = Colors.black
                        }
                        if let wrapper = this.navigationController as? ScrollingNavigationController {
                            UIShared.styleChrome(navigationBar: wrapper.navigationBar, translucent: false)
                            this.isChromeTranslucent = false
                            wrapper.followScrollView(this.collectionView!, delay: -(Double(this.headerHeight)), followers: [this.chromeBackground])
                        }
                        
				}, completion: nil)
			}
		}
		else {
			if !self.isChromeTranslucent {
				UIView.animate(withDuration: 0.3
						, delay: 0
						, options: [.curveEaseInOut, .transitionCrossDissolve]
						, animations: { [weak self] in
					guard let this = self else { return }
					UIApplication.shared.statusBarStyle = .lightContent
					if let backButton = this.backButton?.customView as? ChannelBackView {
						backButton.label.textColor = Colors.white
						backButton.backImage.tintColor = Colors.white
					}
					if let wrapper = this.navigationController as? ScrollingNavigationController {
						UIShared.styleChrome(navigationBar: wrapper.navigationBar, translucent: true)
                        wrapper.stopFollowingScrollView()
						this.isChromeTranslucent = true
					}
				}, completion: nil)
			}
		}
		self.lastContentOffset = scrollView.contentOffset.y
		updateHeaderView()
	}
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true)
        }
        return true
    }
}

extension ChannelViewController: UICollectionViewDelegateFlowLayout { // UICollectionViewDelegate, UICollectionViewDataSource

	func collectionView(_ collectionView: UICollectionView
			, layout collectionViewLayout: UICollectionViewLayout
			, sizeForItemAt indexPath: IndexPath) -> CGSize {

		/*
		 * Using an estimate significantly improves table view load time but we can get
		 * small scrolling glitches if actual height ends up different than estimated height.
		 * So we try to provide the best estimate we can and still deliver it quickly.
		 *
		 * Note: Called once only for each row in fetchResultController when FRC is making a data pass in
		 * response to managedContext.save.
		 */
		var viewHeight = CGFloat(100)
		let viewWidth = min(Config.contentWidthMax, self.collectionView!.width())
		let snap = self.queryController.snapshots.snapshot(at: indexPath.row)
		let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)

		if message.id != nil {
			if let cachedHeight = self.itemHeights.object(forKey: message.id!) as? CGFloat {
				return CGSize(width: viewWidth, height: cachedHeight)
			}
		}

		self.itemTemplate.bounds.size.width = viewWidth
        self.itemTemplate.reset()
		self.itemTemplate.bind(message: message)
		self.itemTemplate.layoutIfNeeded()

		viewHeight = self.itemTemplate.height()

		if message.id != nil {
			self.itemHeights[message.id!] = viewHeight
		}

		return CGSize(width: viewWidth, height: viewHeight)
	}

	func collectionView(_ collectionView: UICollectionView
			, layout collectionViewLayout: UICollectionViewLayout
			, insetForSectionAt section: Int) -> UIEdgeInsets {
        var sectionInsets = self.sectionInsets
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            sectionInsets = layout.sectionInset
        }
		return sectionInsets!
    }
}

extension ChannelViewController: FUICollectionDelegate {

	func array(_ array: FUICollection, didChange object: Any, at index: UInt) {
		let indexPath = IndexPath(row: Int(index), section: 0)
		if let cell = self.collectionView?.cellForItem(at: indexPath) {
			if let snap = object as? DataSnapshot {
				let cell = cell as! MessageListCell
				self.itemHeights.removeObject(forKey: snap.key)
				let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)
				message.creator = cell.message?.creator
				cell.bind(message: message)
                self.collectionView?.collectionViewLayout.invalidateLayout()
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
