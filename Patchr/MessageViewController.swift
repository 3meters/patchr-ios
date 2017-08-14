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

    weak var sheetController: STPopupController!

	/* Only used for row sizing */
	var rowHeights: NSMutableDictionary = [:]
	var itemTemplate = MessageListCell()

	/*--------------------------------------------------------------------------------------------
	 * MARK: - Lifecycle
	 *--------------------------------------------------------------------------------------------*/
    
    init() {
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
		bind()
	}
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        textInputbar.textView.becomeFirstResponder()
//    }

	override func viewWillLayoutSubviews() {
		let viewWidth = min(Config.contentWidthMax, self.view.width())
		self.view.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: self.view.height())
		super.viewWillLayoutSubviews()
		self.tableView.fillSuperview()
	}

	deinit {
		Log.v("MessageViewController released: \(self.inputMessageId!)")
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

    func closeAction(sender: AnyObject) {
        self.close(animated: true)
    }
    
	func deleteCommentAction(message: FireMessage) {
		DeleteConfirmationAlert(
				title: "Confirm Delete",
				message: "Are you sure you want to delete this?",
				actionTitle: "Delete", cancelTitle: "Cancel", delegate: self) {
			doIt in
			if doIt {
				let channelId = message.channelId!
				let messageId = message.messageId!
                let commentId = message.id!
				Reporting.track("delete_comment")
                FireController.instance.deleteComment(commentId: commentId, messageId: messageId, channelId: channelId)
			}
		}
	}
    
    override func didPressRightButton(_ sender: Any!) {
        super.didPressRightButton(sender)
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
                showCommentActions(message: message, sourceView: cell.contentView)
            }
        }
    }
    
    func showCommentActions(sender: AnyObject?) {
        if let button = sender as? AirButtonBase {
            if let message = button.data as? FireMessage {
                Reporting.track("view_message_actions")
                showCommentActions(message: message, sourceView: button)
            }
        }
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

		self.authHandle = Auth.auth().addStateDidChangeListener() { [weak self] auth, user in
			guard let this = self else { return }
			if user == nil {
				this.unbind()
			}
		}
        
        self.shouldScrollToBottomAfterKeyboardShows = true

		self.tableView.estimatedRowHeight = 100                        // Zero turns off estimates
		self.tableView.rowHeight = UITableViewAutomaticDimension    // Actual height is handled in heightForRowAtIndexPath
		self.tableView.backgroundColor = Theme.colorBackgroundTable
		self.tableView.separatorInset = .zero
		self.tableView.tableFooterView = UIView()
		self.tableView.delegate = self
		self.tableView.register(MessageListCell.self, forCellReuseIdentifier: "cell")

		self.itemTemplate.template = true
        self.itemTemplate.commentsButton.removeFromSuperview()
        self.itemTemplate.reactionToolbar.removeFromSuperview()
        
        self.textView.placeholder = "Add comment"
        
		/* Navigation bar */
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
        self.navigationItem.leftBarButtonItems = [closeButton]
        self.navigationItem.title = "Comments"
        
        /* Trigger layout pass */
		self.textInputbar.contentInset = UIEdgeInsetsMake(5, 8, 5, 8)

		NotificationCenter.default.addObserver(self, selector: #selector(messageDidChange(notification:)), name: NSNotification.Name(rawValue: Events.MessageDidUpdate), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(userDidUpdate(notification:)), name: NSNotification.Name(rawValue: Events.UserDidUpdate), object: nil)
	}

	fileprivate func bind() {

		/* Only called once */

        let messageId = self.inputMessageId!
        let channelId = self.inputChannelId!
		Log.v("Binding to: \(messageId)")

		/* Primary list */
        
		let query = FireController.db.child("message-comments/\(channelId)/\(messageId)")
            .queryOrdered(byChild: "created_at")

		self.queryController = DataSourceController(name: "message_view")

		self.queryController.bind(to: self.tableView, query: query) { [weak self] scrollView, indexPath, data in

			/* If cell.prepareToReuse is called, userQuery observer is removed */
            let tableView = scrollView as! UITableView
			let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MessageListCell
			guard let this = self else { return cell }

			let snap = data as! DataSnapshot
			let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)

			guard message.createdBy != nil else {
				return cell
			}
            
			cell.userQuery = UserQuery(userId: message.createdBy!)
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
                    cell.commentsButton.removeFromSuperview()
                    cell.reactionToolbar.removeFromSuperview()
					cell.decorated = true
				}

                cell.bind(message: message) // Handles hide/show of actions button based on message.selected

				if message.creator != nil {
					cell.userPhotoControl.target = message.creator
					cell.userPhotoControl.addTarget(this, action: #selector(this.browseMemberAction(sender:)), for: .touchUpInside)
				}
			})
			return cell
		}

		self.queryController.delegate = self
	}

	func unbind() {
		if self.queryController != nil {
			self.queryController.unbind()
		}
	}
    
	func showCommentActions(message: FireMessage, sourceView: UIView?) {

		let userId = UserController.instance.userId!
        if message.createdBy != userId { return }
		let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

		let edit = UIAlertAction(title: "Edit comment", style: .default) { action in
            Reporting.track("view_comment_edit")
            self.editComment(comment: message)
		}
        
		let delete = UIAlertAction(title: "Delete comment", style: .destructive) { action in
			self.deleteCommentAction(message: message)
		}
        
		let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
			sheet.dismiss(animated: true, completion: nil)
		}

        sheet.addAction(edit)
        sheet.addAction(delete)
        sheet.addAction(cancel)

		if let presenter = sheet.popoverPresentationController, let sourceView = sourceView {
			presenter.sourceView = sourceView
			presenter.sourceRect = sourceView.bounds
		}

		present(sheet, animated: true, completion: nil)
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
}

extension MessageViewController {
    
    override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.view.setNeedsLayout()
        return true
    }
    
    override func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        self.view.setNeedsLayout()
        return true
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
}

extension MessageViewController: TTTAttributedLabelDelegate {
	func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
		UIApplication.shared.openURL(url)
	}
}
