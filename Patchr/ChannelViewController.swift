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

class ChannelViewController: UIViewController, UITableViewDelegate {
    
    var channelQuery: ChannelQuery?
    var messagesQuery: FIRDatabaseQuery!
    var channel: FireChannel!
    
    var tableView: UITableView!
    var tableViewDataSource: FUITableViewDataSource!
    var cellReuseIdentifier: String!
    var headerView: ChannelDetailView!

    var originalRect: CGRect?
    var originalScrollTop = CGFloat(-64.0)
    var originalScrollInset: UIEdgeInsets!
    var lastContentOffset = CGFloat(0)

    var actionButton: AirRadialMenu!
    var actionButtonCenter: CGPoint!
    var actionButtonAnimating = false
    var messageBar = UILabel()
    var messageBarTop = CGFloat(0)
    
    var activity			= UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var progressOffsetY     = Float(-48)
    var progressOffsetX     = Float(8)
    
    var titleView: ChannelTitleView!

    /* Load more button displayed in table footer */
    var footerView			= UIView()
    var loadMoreButton		= UIButton(type: UIButtonType.roundedRect)
    var loadMoreActivity	= UIActivityIndicatorView(activityIndicatorStyle: .white)
    var loadMoreMessage		= "LOAD MORE"

    /* Only used for row sizing */
    var rowHeights			: NSMutableDictionary = [:]
    var itemTemplate		= MessageViewCell()
    var itemPadding			= UIEdgeInsetsMake(12, 12, 20, 12)

    /*--------------------------------------------------------------------------------------------
     * MARK: - Lifecycle
     *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UserController.instance.userId != nil && StateController.instance.groupId == nil {
            let controller = GroupPickerController()
            let wrapper = AirNavigationController()
            wrapper.viewControllers = [controller]
            self.present(wrapper, animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.actionButton != nil {
            showActionButton()
        }
        
        iRate.sharedInstance().promptIfAllCriteriaMet()
        reachabilityChanged()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
        
        self.tableView.fillSuperview()
        
        self.footerView.frame.size.height = CGFloat(48 + 16)
        self.loadMoreButton.anchorTopCenterFillingWidth(withLeftAndRightPadding: 8, topPadding: 8, height: 48)
        self.loadMoreActivity.anchorTopCenter(withTopPadding: 8, width: 48, height: 48)
        
        self.activity.anchorInCenter(withWidth: 20, height: 20)
        self.activity.frame.origin.y += CGFloat(self.progressOffsetY)
        self.activity.frame.origin.x += CGFloat(self.progressOffsetX)
        
        let viewHeight = (viewWidth * 0.625) + self.headerView.infoGroup.height()
        self.tableView.tableHeaderView?.bounds.size = CGSize(width: viewWidth, height: viewHeight)    // Triggers layoutSubviews on header
        
        if self.messageBar.alpha > 0.0 {
            self.messageBar.alignUnder(self.navigationController?.navigationBar, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 40)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        Log.w("Patchr received memory warning: clearing memory image cache")
        SDImageCache.shared().clearMemory()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.channelQuery?.remove()
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Events
     *--------------------------------------------------------------------------------------------*/

    func longPressAction(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            let point = sender.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: point) {
                let snap = self.tableViewDataSource.object(at: UInt(indexPath.row)) as! FIRDataSnapshot
                let message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key)
                showMessageActions(message: message!)
            }
        }
    }
    
    func memberAction(sender: AnyObject?) {
        if let photoView = sender as? PhotoView {
            if let user = photoView.target as? FireUser {
                let controller = MemberViewController()
                controller.inputUserId = user.id
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    func membersAction(sender: AnyObject) {
        let controller = UserTableViewController()
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func photoAction(sender: AnyObject?) {
        
        if let control = sender as? AirImageView,
            let container = sender?.superview as? BaseView {
            if control.image != nil {
                UIShared.showPhoto(image: control.image, animateFromView: control, viewController: self, entity: container.entity)
            }
        }
        
        if let recognizer = sender as? UITapGestureRecognizer,
            let control = recognizer.view as? AirImageView,
            let container = control.superview as? MessageViewCell {
            if control.image != nil {
                UIShared.showPhoto(image: control.image, animateFromView: control, viewController: self, message: container.message)
            }
        }
        
        if let control = sender as? UIButton,
            let container = sender?.superview as? BaseView {
            if control.imageView!.image != nil {
                UIShared.showPhoto(image: control.imageView!.image, animateFromView: control, viewController: self, entity: container.entity)
            }
        }
    }
    
    func photosAction(sender: AnyObject) {
        showPhotos()
    }

    func mapAction(sender: AnyObject) {
        let controller = PatchMapViewController()
        controller.locationDelegate = self
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func toggleAction(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
        UIApplication.shared.setStatusBarHidden(true, with: UIStatusBarAnimation.slide)
    }

    func addAction() {
        
        /* Has its own nav because we segue modally and it needs its own stack */
        let controller = MessageEditViewController()
        controller.inputChannelId = self.channel.id
        controller.mode = .insert
        let navController = AirNavigationController()
        navController.viewControllers = [controller]

        self.present(navController, animated: true, completion: nil)
    }

    func editAction() {

        let controller = ChannelEditViewController()
        let wrapper = AirNavigationController()
        controller.mode = .update
        controller.inputChannelId = self.channel.id
        controller.inputGroupId = self.channel.group
        wrapper.viewControllers = [controller]
        self.present(wrapper, animated: true, completion: nil)
    }
    
    func editMessageAction(message: FireMessage) {
        
        /* Has its own nav because we segue modally and it needs its own stack */
        let controller = MessageEditViewController()
        controller.inputMessageId = message.id
        controller.inputChannelId = self.channel.id
        controller.mode = .update
        let navController = AirNavigationController()
        navController.viewControllers = [controller]
        self.present(navController, animated: true, completion: nil)
        self.rowHeights.removeObject(forKey: message.id!)
    }
    
    func deleteMessageAction(message: FireMessage) {
        DeleteConfirmationAlert(
            title: "Confirm Delete",
            message: "Are you sure you want to delete this?",
            actionTitle: "Delete", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    FireController.instance.delete(messageId: message.id!, channelId: message.channel!)
                }
        }
    }
    
    func shareAction(sender: AnyObject?) { }

    func sideMenuAction(sender: AnyObject?) {
        self.slideMenuController()?.openRight()
        UIApplication.shared.setStatusBarHidden(true, with: UIStatusBarAnimation.slide)
    }

    func joinAction() { }

    func actionButtonTapped(gesture: UIGestureRecognizer) {
        addAction()
        Animation.bounce(view: self.actionButton)
    }
    
    func loadMoreAction(sender: AnyObject?) {
        if let button = self.footerView.viewWithTag(1) as? UIButton,
            let spinner = self.footerView.viewWithTag(2) as? UIActivityIndicatorView {
            button.isHidden = true
            spinner.isHidden = false
            spinner.startAnimating()
        }
        // todo: Go ask for another page
    }
    
    /*--------------------------------------------------------------------------------------------
    * MARK: - Notifications
    *--------------------------------------------------------------------------------------------*/

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
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    func initialize() {

        Reporting.screen("PatchDetail")
        
        self.headerView = ChannelDetailView()
        self.tableView = AirTableView(frame: self.view.frame, style: .plain)
        self.tableView.estimatedRowHeight = 100						// Zero turns off estimates
        self.tableView.rowHeight = UITableViewAutomaticDimension	// Actual height is handled in heightForRowAtIndexPath
        
        /* A bit of UI tweaking */
        self.cellReuseIdentifier = "message-cell"
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.separatorStyle = .none
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.allowsSelection = false
        self.tableView.delegate = self
        self.tableView.register(WrapperTableViewCell.self, forCellReuseIdentifier: self.cellReuseIdentifier)
        
        self.titleView = (Bundle.main.loadNibNamed("ChannelTitleView", owner: nil, options: nil)?.first as? ChannelTitleView)!
        
        /* Simple activity indicator (frame sizing) */
        self.activity.color = Theme.colorActivityIndicator
        self.activity.hidesWhenStopped = true
        
        /* Footer */
        self.loadMoreButton.tag = 1
        self.loadMoreButton.backgroundColor = Theme.colorBackgroundTile
        self.loadMoreButton.layer.cornerRadius = 8
        self.loadMoreButton.addTarget(self, action: #selector(ChannelViewController.loadMoreAction(sender:)), for: UIControlEvents.touchUpInside)
        self.loadMoreButton.setTitle(self.loadMoreMessage, for: .normal)
        self.footerView.addSubview(self.loadMoreButton)
        
        self.loadMoreActivity.tag = 2
        self.loadMoreActivity.color = Theme.colorActivityIndicator
        self.loadMoreActivity.isHidden = true
        
        self.footerView.frame.size.height = CGFloat(48 + 16)
        self.footerView.addSubview(self.loadMoreActivity)
        self.footerView.backgroundColor = Theme.colorBackgroundTileList

        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: ReachabilityChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(sender:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(sender:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

        self.progressOffsetY = 80
        self.loadMoreMessage = "LOAD MORE MESSAGES"

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
        self.actionButton.centerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(actionButtonTapped(gesture:))))
        self.actionButton!.transform = CGAffineTransform.identity
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.activity)
        self.view.insertSubview(self.actionButton, at: self.view.subviews.count)
        
        self.actionButton.anchorBottomRight(withRightPadding: 16, bottomPadding: 16, width: self.actionButton!.width(), height: self.actionButton!.height())
        self.actionButtonCenter = self.actionButton.center
    }
    
    func bind(groupId: String, channelId: String) {
        
        if self.tableView != nil && self.tableViewDataSource != nil {
            self.rowHeights.removeAllObjects()
            self.headerView.reset()
            self.tableView.dataSource = nil
            self.tableView.reloadData()
        }
        
        let userId = UserController.instance.userId
        let groupQuery = GroupQuery(groupId: groupId, userId: userId!)
        
        groupQuery.once(with: { group in
            if group != nil {
                let maxWidth = self.view.frame.size.width - CGFloat(36 + 36 + 36 + 30 + 16 + 72 + 24)
                self.titleView.bounds.size = CGSize(width: maxWidth, height: (self.navigationController?.navigationBar.height())!)
                
                self.titleView.title?.text = group!.title
                self.titleView.title?.sizeToFit()
                self.titleView.sizeToFit()
                
                self.navigationItem.titleView = self.titleView
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.showChannelActions(gesture:)))
                self.titleView.addGestureRecognizer(tap)
            }
        })
        
        self.channelQuery?.remove()
        self.channelQuery = ChannelQuery(groupId: groupId, channelId: channelId, userId: userId!)
        self.channelQuery!.observe(with: { channel in
            
            guard channel != nil else {
                /* The channel has been deleted from under us. */
                self.channelQuery?.remove()
                if self.tableView != nil && self.tableViewDataSource != nil {
                    self.rowHeights.removeAllObjects()
                    self.headerView.reset()
                    self.tableView.dataSource = nil
                    self.tableView.reloadData()
                }

                FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                    if firstChannelId != nil {
                        StateController.instance.setChannelId(channelId: firstChannelId)
                        MainController.instance.showChannel(groupId: groupId, channelId: StateController.instance.channelId!)
                    }
                }

                return
            }
            
            self.channel = channel
            self.drawNavBarButtons()
            
            /* We do this here so we have tableView sizing */
            if self.tableView.tableHeaderView == nil {
                let viewWidth = min(CONTENT_WIDTH_MAX, (self.tableView.width()))
                self.headerView.frame = CGRect(x:0, y:0, width: viewWidth, height: 100)
                self.headerView.bind(channel: self.channel)
                let viewHeight = self.headerView.height()
                self.headerView.frame = CGRect(x:0, y:0, width: viewWidth, height: viewHeight)
                self.headerView.photo.frame = CGRect(x: -24, y: -36, width:
                    (self.headerView.contentGroup.width())
                        + 48, height: (self.headerView.contentGroup.height()) + 72)
                self.originalRect = self.headerView.photo.frame
                self.originalScrollInset = self.tableView.contentInset
                self.tableView.tableHeaderView = self.headerView
                self.tableView.reloadData()
            }
            else {
                self.headerView.bind(channel: self.channel)
                self.tableView.tableHeaderView = self.headerView
            }
            
            let purpose = self.headerView.infoGroup
            self.tableView.contentInset.top = (self.originalScrollInset.top - (self.headerView.height() - (96 + purpose.height())))  //-168
        })
        
        self.messagesQuery = FireController.db.child("channel-messages/\(channelId)").queryOrdered(byChild: "created_at_desc")
        
        self.tableViewDataSource = FUITableViewDataSource(query: self.messagesQuery
            , view: self.tableView
            , populateCell: { [weak self] tableView, indexPath, snap in
                
                let cell = tableView.dequeueReusableCell(withIdentifier: (self?.cellReuseIdentifier)!, for: indexPath) as! WrapperTableViewCell
                let message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key)! as FireMessage
                
                if let messageView = cell.view as? MessageViewCell {
                    messageView.reset()
                }
                
                if message.createdBy == nil {
                    self?.bindMessageView(cell: cell, message: message)
                }
                else {
                    let userQuery = UserQuery(userId: message.createdBy!, groupId: groupId)
                    userQuery.once(with: { user in
                        message.creator = user
                        self?.bindMessageView(cell: cell, message: message)
                    })
                }
                return cell
            })
        
        self.tableView.dataSource = self.tableViewDataSource
    }
    
    func bindMessageView(cell: WrapperTableViewCell, message: FireMessage) {
        
        if cell.view == nil {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressAction(sender:)))
            recognizer.minimumPressDuration = TimeInterval(0.5)
            cell.addGestureRecognizer(recognizer)
            
            let view = MessageViewCell(frame: CGRect(x: 0, y: 0, width: self.view.width(), height: 40))
            if view.description_ != nil && (view.description_ is TTTAttributedLabel) {
                let label = view.description_ as! TTTAttributedLabel
                label.delegate = self
            }
            view.photo?.isUserInteractionEnabled = true
            view.photo?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.photoAction(sender:))))
            cell.injectView(view: view, padding: self.itemPadding)
            cell.layoutSubviews()   // Make sure padding has been applied
        }
        
        if let messageView = cell.view! as? MessageViewCell {
            messageView.bind(message: message)
            if message.creator != nil {
                messageView.userPhoto.target = message.creator
                messageView.userPhoto.addTarget(self, action: #selector(self.memberAction(sender:)), for: .touchUpInside)
            }
        }
    }

    func drawNavBarButtons() {
        
        self.titleView.subtitle?.text = "#\(self.channel.name!)"
        self.titleView.subtitle?.sizeToFit()
        self.titleView.sizeToFit()

        /* Navigation button */
        var button = UIButton(type: .custom)
        button.frame = CGRect(x:0, y:0, width:36, height:36)
        button.addTarget(self, action: #selector(PatchDetailViewController.toggleAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgNavigationLight"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 0, 8, 16);
        let navButton = UIBarButtonItem(customView: button)
        
        /* Gallery button */
        button = UIButton(type: .custom)
        button.frame = CGRect(x:0, y:0, width:36, height:36)
        button.addTarget(self, action: #selector(photosAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgGallery2Light"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6);
        let photosButton = UIBarButtonItem(customView: button)

        /* Menu button */
        button = UIButton(type: .custom)
        button.frame = CGRect(x:0, y:0, width:36, height:36)
        button.addTarget(self, action: #selector(sideMenuAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgOverflowVerticalLight"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        let moreButton = UIBarButtonItem(customView: button)
        
        self.navigationItem.setLeftBarButtonItems([navButton], animated: true)
        self.navigationItem.setRightBarButtonItems([moreButton, photosButton], animated: true)
    }
    
    func showMessageActions(message: FireMessage) {
        
        let userId = UserController.instance.userId
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

        let likes = message.getReaction(emoji: .thumbsup, userId: userId!)
        let likeTitle = likes ? "Remove like" : "Add like"
        let like = UIAlertAction(title: likeTitle, style: .default) { action in
            if likes {
                message.removeReaction(emoji: .thumbsup)
            }
            else {
                message.addReaction(emoji: .thumbsup)
            }
        }
        
        let edit = UIAlertAction(title: "Edit message", style: .default) { action in
            self.editMessageAction(message: message)
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
        else {
            sheet.addAction(like)
            sheet.addAction(cancel)
        }
        
        present(sheet, animated: true, completion: nil)
    }
    
    func showChannelActions(gesture: AnyObject?) {
        
        if self.channel != nil {
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            if isUserOwner() {
                let edit = UIAlertAction(title: "Edit channel", style: .default) { action in
                    self.editAction()
                }
                sheet.addAction(edit)
            }
            
            let muted = self.channel.muted
            let mutedTitle = muted! ? "Unmute channel" : "Mute channel"
            let mute = UIAlertAction(title: mutedTitle, style: .default) { action in
                self.channel.mute(on: !muted!)
            }
            
            let starred = self.channel.starred
            let starredTitle = starred! ? "Unstar channel" : "Star channel"
            let star = UIAlertAction(title: starredTitle, style: .default) { action in
                self.channel.star(on: !starred!)
                self.headerView.starButton.toggle(on: !starred!, animate: true)
            }
            
            let leave = UIAlertAction(title: "Leave channel", style: .default) { action in
                self.joinAction()
                Utils.delay(1.0) {
                    UIShared.Toast(message: "You have left this channel", controller: self, addToWindow: false)
                }
            }
            
            let addMembers = UIAlertAction(title: "Add members", style: .default) { action in
                UIShared.Toast(message: "Show invite ui")
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) {
                action in
                sheet.dismiss(animated: true, completion: nil)
            }
            
            sheet.addAction(star)
            sheet.addAction(mute)
            sheet.addAction(leave)
            sheet.addAction(addMembers)
            sheet.addAction(cancel)
            
            if let presenter = sheet.popoverPresentationController {
                presenter.sourceView = self.titleView
                presenter.sourceRect = self.titleView.bounds
            }
            
            present(sheet, animated: true, completion: nil)
        }
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

    func showPhotos() {

        /* Cherry pick display photos */
        var displayPhotos = [String: DisplayPhoto]()
        var remaining = self.tableViewDataSource.items.count
        
        for data in self.tableViewDataSource.items {
            let snap = data as! FIRDataSnapshot            
            if let message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key) {
                
                message.getCreator(with: { user in
                    
                    remaining -= 1
                    if (message.attachments?.first?.photo) != nil {
                        message.creator = user
                        let displayPhoto = DisplayPhoto.fromMessage(message: message)
                        displayPhotos[displayPhoto.entityId!] = displayPhoto
                    }
                    
                    if remaining <= 0 {
                        let navController = AirNavigationController()
                        let layout = NHBalancedFlowLayout()
                        layout.preferredRowSize = 200
                        let controller = GalleryGridViewController(collectionViewLayout: layout)
                        controller.displayPhotos = displayPhotos
                        navController.viewControllers = [controller]
                        self.navigationController!.present(navController, animated: true, completion: nil)
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
            }) { _ in
            Animation.bounce(view: self.messageBar)
        }
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
    
    func scrollToHeader(animated: Bool = true) {
        self.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: animated)
    }
    
    func scrollToFirstRow(animated: Bool = true) {
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    func scrollToLastRow(animated: Bool = true) {
        let itemCount = self.tableViewDataSource.items.count
        let indexPath = IndexPath(row: itemCount - 1, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /*
         * Using an estimate significantly improves table view load time but we can get
         * small scrolling glitches if actual height ends up different than estimated height.
         * So we try to provide the best estimate we can and still deliver it quickly.
         *
         * Note: Called once only for each row in fetchResultController when FRC is making a data pass in
         * response to managedContext.save.
         */
        let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
        var viewHeight = CGFloat(100)
        let snap = self.tableViewDataSource.object(at: UInt(indexPath.row)) as! FIRDataSnapshot
        
        if let message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key) {
            
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

    /*--------------------------------------------------------------------------------------------
    * MARK: - Properties
    *--------------------------------------------------------------------------------------------*/

    func isUserOwner() -> Bool {
        let userId = UserController.instance.userId
        return self.channel!.createdBy == userId
    }
}

extension ChannelViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.openURL(url)
    }
}

extension ChannelViewController {
    /*
     * UITableViewDelegate
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

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

        /* Parallax effect when user scrolls down */
        let offset = scrollView.contentOffset.y
        if self.originalRect != nil {
            if offset >= self.originalScrollTop && offset <= 300 {
                let movement = self.originalScrollTop - scrollView.contentOffset.y
                let ratio: CGFloat = (movement <= 0) ? 0.50 : 1.0
                if self.originalRect != nil {
                    self.headerView.photo.frame.origin.y = self.originalRect!.origin.y + (-(movement) * ratio)
                }
            }
            else {
                let movement = (originalScrollTop - scrollView.contentOffset.y) * 0.35
                if movement > 0 {
                    headerView.photo.frame.origin.y = self.originalRect!.origin.y - (movement * 0.5)
                    headerView.photo.frame.origin.x = self.originalRect!.origin.x - (movement * 0.5)
                    headerView.photo.frame.size.width = self.originalRect!.size.width + movement
                    headerView.photo.frame.size.height = self.originalRect!.size.height + movement
                }
            }
        }
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
        let text = "\(ZUserController.instance.currentUser.name) has invited you to the patch!"
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

extension ChannelViewController: MapViewDelegate {
    
    func locationForMap() -> CLLocation? {
        return nil
    }
    
    func locationChangedTo(location: CLLocation) {
    }
    
    func locationEditable() -> Bool {
        return false
    }
    
    var locationTitle: String? {
        get {
            return nil
        }
    }
    
    var locationSubtitle: String? {
        get {
            return nil
        }
    }
    
    var locationPhoto: AnyObject? {
        get {
            return nil
        }
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
