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
import Firebase
import FirebaseDatabaseUI

class ChannelViewController: UIViewController, UITableViewDelegate {
    
    var inputGroupId: String!
    var inputChannelId: String!
    
    var channelRef: FIRDatabaseReference!
    var channelHandle: UInt!
    var messagesQuery: FIRDatabaseQuery!
    var channel: FireChannel!
    
    var tableView: UITableView!
    var tableViewDataSource: FirebaseTableViewDataSource!
    var headerView: ChannelDetailView!
    
    var originalRect: CGRect?
    var originalScrollTop = CGFloat(-64.0)
    var lastContentOffset = CGFloat(0)

    var actionButton: AirRadialMenu!
    var actionButtonCenter: CGPoint!
    var actionButtonAnimating = false
    var messageBar = UILabel()
    var messageBarTop = CGFloat(0)
    
    var activity			= UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var progressOffsetY     = Float(-48)
    var progressOffsetX     = Float(8)

    /* Load more button displayed in table footer */
    var footerView			= UIView()
    var loadMoreButton		= UIButton(type: UIButtonType.roundedRect)
    var loadMoreActivity	= UIActivityIndicatorView(activityIndicatorStyle: .white)
    var loadMoreMessage		= "LOAD MORE"

    /* Only used for row sizing */
    var rowHeights			: NSMutableDictionary = [:]
    var itemTemplate		= MessageViewCell()
    var itemPadding			= UIEdgeInsetsMake(12, 12, 20, 12)
    
    let photoTapGesture = UITapGestureRecognizer(target: self, action: #selector(photoAction(sender:)))
    let messageLongPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(sender:)))

    /*--------------------------------------------------------------------------------------------
     * MARK: - Lifecycle
     *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.channelHandle = self.channelRef.observe(.value, with: { snap in
            self.channel = FireChannel(dict: snap.value as! [String: Any], id: snap.key)
            self.bind()
        })
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
        self.activity.stopAnimating()
        self.channelRef.removeObserver(withHandle: self.channelHandle)
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        Log.w("Patchr received memory warning: clearing memory image cache")
        SDImageCache.shared().clearMemory()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Events
     *--------------------------------------------------------------------------------------------*/

    func longPressAction(sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point) {
            UIShared.Toast(message: "Long press row: \(indexPath.row)")
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
        controller.inputToString = self.channel?.name
        controller.inputPatchId = self.inputGroupId
        controller.inputState = .Creating

        let navController = AirNavigationController()
        navController.viewControllers = [controller]

        self.present(navController, animated: true, completion: nil)
    }

    func editAction() {

        let controller = PatchEditViewController()
        let navController = AirNavigationController()
        navController.viewControllers = [controller]

        self.present(navController, animated: true, completion: nil)
    }
    
    func muteAction() { }

    func shareAction(sender: AnyObject?) { }

    func moreAction(sender: AnyObject?) {

        if self.channel != nil {
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

            if isUserOwner() {
                let edit = UIAlertAction(title: "Edit channel", style: .default) {
                    action in
                    self.editAction()
                }
                sheet.addAction(edit)
            }

            let mute = UIAlertAction(title: "Mute patch", style: .default) { action in
                self.muteAction()
            }

            sheet.addAction(mute)

            let leave = UIAlertAction(title: "Leave patch", style: .default) { action in
                self.joinAction(sender: sender)
                Utils.delay(1.0) {
                    UIShared.Toast(message: "You have left this patch", controller: self, addToWindow: false)
                }
            }
            
            sheet.addAction(leave)

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

    func joinAction(sender: AnyObject?) { }

    func actionButtonTapped(gester: UIGestureRecognizer) {
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
        
        self.channelRef = FIRDatabase.database().reference().child("group-channels/\(self.inputGroupId!)/\(self.inputChannelId!)")
        self.messagesQuery = FIRDatabase.database().reference().child("channel-messages/\(self.inputChannelId!)").queryOrdered(byChild: "timestamp")
        
        self.headerView = ChannelDetailView()
        self.tableView = AirTableView(frame: self.view.frame, style: .plain)
        self.tableView.estimatedRowHeight = 100						// Zero turns off estimates
        self.tableView.rowHeight = UITableViewAutomaticDimension	// Actual height is handled in heightForRowAtIndexPath
        
        /* A bit of UI tweaking */
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.separatorStyle = .none
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.delegate = self
        
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

        NotificationCenter.default.addObserver(self, selector: #selector(ChannelViewController.reachabilityChanged), name: ReachabilityChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChannelViewController.applicationDidEnterBackground(sender:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChannelViewController.applicationWillEnterForeground(sender:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

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
        self.actionButton.centerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(actionButtonTapped(gester:))))
        self.actionButton!.transform = CGAffineTransform.identity
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.activity)
        self.view.insertSubview(self.actionButton, at: self.view.subviews.count)
        
        self.actionButton.anchorBottomRight(withRightPadding: 16, bottomPadding: 16, width: self.actionButton!.width(), height: self.actionButton!.height())
        self.actionButtonCenter = self.actionButton.center
    }

    func bind() {

        self.drawNavBarButtons()
        
        /* We do this here so we have tableView sizing */
        if self.tableView.tableHeaderView == nil {
            let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
            self.headerView.frame = CGRect(x:0, y:0, width: viewWidth, height: 100)
            self.headerView.bind(channel: channel)
            let viewHeight = self.headerView.height()
            self.headerView.frame = CGRect(x:0, y:0, width: viewWidth, height: viewHeight)
            self.headerView.photo.frame = CGRect(x: -24, y: -36, width: self.headerView.contentGroup.width() + 48, height: self.headerView.contentGroup.height() + 72)
            self.originalRect = self.headerView.photo.frame
            self.tableView.tableHeaderView = self.headerView
            self.tableView.reloadData()
        }
        else {
            self.headerView.bind(channel: self.channel)
        }
        
        if self.tableViewDataSource == nil {
            
            self.tableViewDataSource = FirebaseTableViewDataSource(query: self.messagesQuery
                , cellClass: WrapperTableViewCell.self
                , cellReuseIdentifier: "MessageViewCell"
                , view: self.tableView)
            
            self.tableViewDataSource.populateCell { (cell, data) in
                
                let snap = data as! FIRDataSnapshot
                let cell = cell as! WrapperTableViewCell
                let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key)! as FireMessage
                
                if message.createdBy == nil {
                    self.bindMessageView(cell: cell, message: message)
                }
                else {
                    let userRef = FIRDatabase.database().reference().child("users/\(message.createdBy!)")
                    userRef.observeSingleEvent(of: .value, with: { snap in
                        if let user = FireUser(dict: snap.value as! [String: Any], id: snap.key) {
                            message.creator = user
                            self.bindMessageView(cell: cell, message: message)
                        }
                    })
                }
            }
            
            self.tableView.dataSource = self.tableViewDataSource
        }
    }
    
    func bindMessageView(cell: WrapperTableViewCell, message: FireMessage) {
        if cell.view == nil {
            cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.longPressAction(sender:))))
            
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
        
        let messageView = cell.view! as! MessageViewCell
        messageView.bind(message: message)
        if message.creator != nil {
            messageView.userPhoto.target = message.creator
            messageView.userPhoto.addTarget(self, action: #selector(self.memberAction(sender:)), for: .touchUpInside)
        }
    }

    func drawNavBarButtons() {

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
        button.setImage(UIImage(named: "imgOverflowLight"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        let moreButton = UIBarButtonItem(customView: button)
        
        /* Dropdown button */
        button = UIButton(type: .custom)
        button.frame = CGRect(x:0, y:0, width:30, height:30)
        button.addTarget(self, action: #selector(moreAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgDropdown3Light"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 6, 16);
        let dropdownButton = UIBarButtonItem(customView: button)

        /* Title button - last for sizing purposes */
        button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(moreAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setTitleColor(Colors.black, for: .normal)
        button.titleLabel!.font = Theme.fontTextBold
        button.setTitle("#\(channel.name!)", for: .normal)
        button.sizeToFit()
        let maxWidth = self.view.frame.size.width - CGFloat(36 + 36 + 36 + 30 + 16 + 72)
        if button.frame.size.width > maxWidth {
            button.frame.size.width = maxWidth
        }
        let titleButton = UIBarButtonItem(customView: button)

        self.navigationItem.setLeftBarButtonItems([navButton, Utils.spacer, titleButton, dropdownButton, Utils.spacer], animated: true)
        self.navigationItem.setRightBarButtonItems([moreButton, photosButton], animated: true)
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
            if let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key) {
                
                let userRef = FIRDatabase.database().reference().child("users/\(message.createdBy!)")
                userRef.observeSingleEvent(of: .value, with: { snap in
                    remaining -= 1
                    let user = FireUser(dict: snap.value as! [String: Any], id: snap.key)
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
    
    func scrollToFirstRow(animated: Bool = true) {
        self.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: animated)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath) as! MessageViewCell
//        let controller = MessageDetailViewController()
//        self.navigationController?.pushViewController(controller, animated: true)
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
        
        if let message = FireMessage(dict: snap.value as! [String: Any], id: snap.key) {
            
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
        let userId = UserController.instance.fireUserId
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

        //self.actionButton.center.y = self.actionButtonCenter.y + scrollView.contentOffset.y
        
        if self.messageBar.alpha > 0.0 {
            self.messageBar.frame.origin.y = scrollView.contentOffset.y + 64 // todo: Fragile if status and navigation bar don't match this
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

        /* Parallax effect when user scrolls down */
        let offset = scrollView.contentOffset.y
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

class ChannelItem: NSObject, UIActivityItemSource {

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
        let text = "\(UserController.instance.currentUser.name) has invited you to the \(self.entity.name) patch!"
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
