//
//  ChanneliewController.swift
//

import UIKit
import MessageUI
import IDMPhotoBrowser
import NHBalancedFlowLayout
import Firebase
import FirebaseDatabaseUI
import TTTAttributedLabel
import STPopup
import SlackTextViewController
import BEMCheckBox

class CommentListController: BaseSlackController {

    weak var sheetController: STPopupController!

	/* Only used for row sizing */
	var rowHeights: NSMutableDictionary = [:]
	var itemTemplate = CommentListCell()

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
    
	override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewWidth = min(Config.contentWidthMax, UIScreen.main.bounds.size.width)
        self.view.bounds.size.width = viewWidth
	}

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.view.setNeedsLayout()
    }
    
	deinit {
		Log.v("CommentListController released: \(self.inputMessageId!)")
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
    
	@objc func browseMemberAction(sender: AnyObject?) {
		if let photoControl = sender as? PhotoControl {
			if let user = photoControl.target as? FireUser {
                let controller = MemberViewController(userId: user.id)
                let wrapper = AirNavigationController(rootViewController: controller)
				Reporting.track("view_group_member")
                UIViewController.topController?.present(wrapper, animated: true, completion: nil)
			}
		}
	}

    @objc func closeAction(sender: AnyObject) {
        self.close(animated: true)
    }
    
    override func didPressRightButton(_ sender: Any!) {
        super.didPressRightButton(sender)
        Utils.incrementUserActions()
    }
    
	/*--------------------------------------------------------------------------------------------
	* MARK: - Notifications
	*--------------------------------------------------------------------------------------------*/

	@objc func userDidUpdate(notification: NSNotification) {
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
        
        self.tableView.register(CommentListCell.self, forCellReuseIdentifier: "cell")
		self.tableView.estimatedRowHeight = 100                        // Zero turns off estimates
		self.tableView.rowHeight = UITableViewAutomaticDimension    // Actual height is handled in heightForRowAtIndexPath
		self.tableView.backgroundColor = Theme.colorBackgroundTable
		self.tableView.separatorInset = .zero
		self.tableView.tableFooterView = UIView()
        self.tableView.allowsSelection = false
		self.tableView.delegate = self

		self.itemTemplate.template = true
        self.itemTemplate.commentsButton.removeFromSuperview()
        self.itemTemplate.reactionToolbar.removeFromSuperview()
        
        self.textView.placeholder = "comment_placeholder".localized()
        
		/* Navigation bar */
        if self.presented {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
            self.navigationItem.title = "comments".localized()
        }
        
        /* Trigger layout pass */
		self.textInputbar.contentInset = UIEdgeInsetsMake(5, 8, 5, 8)

		NotificationCenter.default.addObserver(self, selector: #selector(userDidUpdate(notification:)), name: NSNotification.Name(rawValue: Events.UserDidUpdate), object: nil)
	}

	fileprivate func bind() {

		/* Only called once */

        let userId = UserController.instance.userId!
        let messageId = self.inputMessageId!
        let channelId = self.inputChannelId!
		Log.v("Binding to: \(messageId)")

		/* Primary list */
        
		let query = FireController.db.child("channel-messages/\(channelId)/\(messageId)/comments").queryOrdered(byChild: "created_at")
		self.queryController = DataSourceController(name: "message_view")
		self.queryController.bind(to: self.tableView, query: query) { [weak self] scrollView, indexPath, data in

			/* If cell.prepareToReuse is called, userQuery observer is removed */
            let tableView = scrollView as! UITableView
			let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CommentListCell
            cell.reset()
			guard self != nil else { return cell }

			let snap = data as! DataSnapshot
			let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)

			cell.inputUserQuery = UserQuery(userId: message.createdBy!)
			cell.inputUserQuery.once(with: { [weak self, weak cell] error, user in
				guard let this = self, let cell = cell else { return }
                if error != nil {
                    Log.w("Permission denied")
                    return
                }

				message.creator = user

				if !cell.decorated {
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
        self.view.setNeedsLayout()
		self.queryController.delegate = self
	}

	func unbind() {
		if self.queryController != nil {
			self.queryController.unbind()
		}
	}
    
	func scrollToFirstRow(animated: Bool = true) {
		let indexPath = IndexPath(row: 0, section: 0)
		self.tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
	}

	func scrollToLastRow(animated: Bool = true) {
		let itemCount = self.queryController.items.count
		if itemCount > 0 {
			let indexPath = IndexPath(row: itemCount - 1, section: 0)
			self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
		}
	}
}

extension CommentListController {

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

extension CommentListController {
    
    override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.view.setNeedsLayout()
        return true
    }
    
    override func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        self.view.setNeedsLayout()
        return true
    }
}

extension CommentListController: FUICollectionDelegate {

	func array(_ array: FUICollection, didChange object: Any, at index: UInt) {
		let indexPath = IndexPath(row: Int(index), section: 0)
		if let cell = self.tableView.cellForRow(at: indexPath) {
			if let snap = object as? DataSnapshot {
				let cell = cell as! CommentListCell
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
		scrollToLastRow(animated: false)
	}
}

extension CommentListController: TTTAttributedLabelDelegate {

	func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
		UIApplication.shared.openURL(url)
	}
}
