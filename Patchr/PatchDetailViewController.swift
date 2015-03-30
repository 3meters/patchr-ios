//
//  PatchDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchDetailViewController: FetchedResultsTableViewController, TableViewCellDelegate, UIActionSheetDelegate {
    
    private let cellNibName = "MessageTableViewCell"
    
    @IBOutlet weak var patchImageView: UIImageView!
    @IBOutlet weak var patchNameLabel: UILabel!
    @IBOutlet weak var patchCategoryLabel: UILabel!
    @IBOutlet weak var watchButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfLikesButton: UIButton!
    @IBOutlet weak var numberOfWatchersButton: UIButton!
    @IBOutlet weak var editPatchButton: UIButton!
    @IBOutlet weak var contextButton: UIButton!
    
    var managedObjectContext: NSManagedObjectContext!
    var query : Query!
    var dataStore: DataStore!
    var patch: Patch!

    var likeLinkId: String? = nil
    var watchLinkId: String? = nil
    var watchLinkEnabled: Bool? = nil
    var watchLinkHasBeenQueried: Bool = false
    
    // Note: This result is only valid after refreshing the link status
    var patchMembershipStatus : PatchMembershipStatus {
        
        if !watchLinkHasBeenQueried { return .Unknown }
        
        if self.watchLinkId == nil { return .NonMember }
        
        if let enabled = self.watchLinkEnabled {
            
            if enabled {
                return .Member
            } else {
                return .Pending
            }
            
        } else {
            return .Pending
        }
    }
    
    private var selectedDetailImage: UIImage?
    private var messageDateFormatter: NSDateFormatter!
    private var offscreenCells: NSMutableDictionary = NSMutableDictionary()
    
    private lazy var fetchControllerDelegate: FetchControllerDelegate = {
        return FetchControllerDelegate(tableView: self.tableView, onUpdate: { [weak self] (cell, object) -> Void in
            return self?.configureCell(cell, object: object) ?? ()
        })
    }()
    
    internal lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: Message.entityName())
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: ServiceBaseAttributes.createdDate, ascending: false)
        ]
        fetchRequest.predicate = NSPredicate(format: "\(MessageRelationships.patch) == %@", self.patch)
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        controller.performFetch(nil)
        controller.delegate = self.fetchControllerDelegate
        
        return controller
    }()
    
    // Note: I tried to use 'inout linkID: String', but that didn't seem to work. The 'setter' closure
    // serves the purpose of setting the ID variable to the correct value after the query completes.
    
    private func refreshLinkValue(linkType: LinkType, linkButton: UIButton, linkID: String?, setter: (NSDictionary?) -> Void)
    {
        let proxibase = ProxibaseClient.sharedInstance
        
        proxibase.findLink(proxibase.userId!, toID: patch.id_, linkType: linkType) { response, error in
            if let serverError = ServerError(error)
            {
                // ServerError initializer logs the error. Not much else to do here.
            }
            else
            {
                let serverResponse = ServerResponse(response)
                self.watchLinkHasBeenQueried = true
                
                if serverResponse.resultCount == 1
                {
                    setter(serverResponse.resultObject)
                    linkButton.selected = true
                }
                else
                {
                    setter(nil)
                    linkButton.selected = false
                }
            }
        }
    }
    
    private func refreshLikeAndWatch()
    {
        refreshLinkValue(.Like, linkButton: self.likeButton, linkID: self.likeLinkId) {  (linkDictionary) -> Void in
            self.likeLinkId = linkDictionary?["_id"] as? String
            self.updatePatchDetailUI()
        }
        refreshLinkValue(.Watch, linkButton: self.watchButton, linkID: self.watchLinkId) { (linkDictionary) -> Void in
            self.watchLinkId = linkDictionary?["_id"] as? String
            self.watchLinkEnabled = linkDictionary?["enabled"] as? Bool
            self.updatePatchDetailUI()
        }
    }
    
    func updatePatchDetailUI() {
        
        self.navigationItem.title = patch.name
        self.patchNameLabel.text = patch.name
        self.patchCategoryLabel.text = patch.category?.name
        self.patchImageView.pa_setImageWithURL(patch.photo?.photoURL(), placeholder: UIImage(named: "PatchDefault"))
        
        let likesTitle = self.patch.numberOfLikes?.integerValue == 1 ? "\(self.patch.numberOfLikes) like" : "\(self.patch.numberOfLikes ?? 0) likes"
        self.numberOfLikesButton.setTitle(likesTitle, forState: UIControlState.Normal)
        
        let watchersTitle = "\(self.patch.numberOfWatchers ?? 0) watching"
        self.numberOfWatchersButton.setTitle(watchersTitle, forState: UIControlState.Normal)
        
        self.dataStore.withCurrentUser(refresh: false) { (user) -> Void in
            if self.patch.ownerId? == user.id_ {
                self.editPatchButton.alpha = 1
            }
        }
        
        switch self.patchMembershipStatus {
        case .Member:
            self.contextButton.setTitle("Add Message", forState: .Normal)
        case .Pending:
            self.contextButton.setTitle("Cancel Join Request", forState: .Normal)
        case .NonMember:
            if self.patch.visibilityValue == .Private {
                self.contextButton.setTitle("Request to Join", forState: .Normal)
            } else {
                self.contextButton.setTitle("Add Message", forState: .Normal)
            }
        case .Unknown:
            self.contextButton.setTitle("", forState: .Normal)
        }
        
        self.contextButton.enabled = self.patchMembershipStatus != .Unknown
        
        if self.patchMembershipStatus != .Unknown {
            self.watchButton.alpha = 1
            self.likeButton.alpha = self.patch.visibilityValue == PAVisibilityLevel.Public || self.patchMembershipStatus == .Member ? 1 : 0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleRemoteNotification:", name: PAApplicationDidReceiveRemoteNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: cellNibName, bundle: nil), forCellReuseIdentifier: "Cell")
        self.tableView.delaysContentTouches = false
        
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "Messages for patch"
        query.parameters = ["patchId" : patch.id_]
        self.managedObjectContext.save(nil)
        self.query = query
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "pullToRefreshAction:", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
        self.refreshControl?.beginRefreshing()
        self.pullToRefreshAction(self.refreshControl!)

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        self.messageDateFormatter = dateFormatter
        
        self.contextButton.enabled = false
        self.contextButton.setTitle("", forState: .Normal)
        
        self.likeButton.alpha = 0
        self.watchButton.alpha = 0
        self.editPatchButton.alpha = 0
        
        refreshLikeAndWatch()
        updatePatchDetailUI()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        // The cell width seems to incorrect occassionally
        if CGRectGetWidth(cell.bounds) != CGRectGetWidth(self.tableView.bounds) {
            cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell.frame))
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }
        
        let message = object as Message
        let messageCell = cell as MessageTableViewCell
        messageCell.delegate = self
        
        messageCell.messageBodyLabel.text = message.description_
        
        messageCell.messageImageView.image = nil
        if let photo = message.photo {
            messageCell.messageImageView.pa_setImageWithURL(photo.photoURL())
            let imageMarginTop : CGFloat = 10.0;
            messageCell.messageImageContainerHeight.constant = messageCell.messageImageView.frame.height + imageMarginTop
        } else {
            messageCell.messageImageContainerHeight.constant = 0;
        }
        
        if let creator = message.creator as? User {
            messageCell.userNameLabel.text = creator.name
            messageCell.userAvatarImageView.pa_setImageWithURL(creator.photo?.photoURL(), placeholder: UIImage(named: "UserAvatarDefault"))
        } else {
            messageCell.userNameLabel.text = nil
            messageCell.userAvatarImageView.image = nil
            NSLog("No creator for message!")
        }
        
        messageCell.likesLabel.text = "\(message.numberOfLikes?.integerValue ?? 0) Likes"
        messageCell.createdDateLabel.text = self.messageDateFormatter.stringFromDate(message.createdDate)
        messageCell.patchNameLabel.text = self.patch.name
    }
    
    private func toggleLinkState(linkValue: String?, ofType linkType: LinkType)
    {
        let proxibase = ProxibaseClient.sharedInstance
        if let linkID = linkValue
        {
            proxibase.deleteLink(linkID) { _, _ in
                self.refreshPatchAndMessages({ (error) -> Void in })
            }
        }
        else
        {
            proxibase.createLink(proxibase.userId!, toID: patch.id_, linkType: linkType) { _, _ in
                self.refreshPatchAndMessages({ (error) -> Void in })
            }
        }
    }
    
    @IBAction func watchAction(sender: AnyObject)
    {
        toggleLinkState(watchLinkId, ofType: .Watch)
    }
    
    @IBAction func likeAction(sender: AnyObject)
    {
        toggleLinkState(likeLinkId, ofType: .Like)
    }
    
    @IBAction func shareButtonAction(sender: UIBarButtonItem) {
        
        let patchURL = NSURL(string: "http://patchr.com/patch/\(self.patch.id_)") ?? NSURL(string: "http://patchr.com")!
        let shareText = "You've been invited to the \(self.patch.name) patch! \n\n\(patchURL.absoluteString!) \n\nGet the Patchr app at http://patchr.com"
        var activityItems : [AnyObject] = [shareText]
        
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func numberOfLikesButtonAction(sender: UIButton) {
        UIAlertView(title: "Not Implemented", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
        //self.performSegueWithIdentifier("LikeListSegue", sender: self)
    }
    
    @IBAction func numberOfWatchersButtonAction(sender: UIButton) {
        UIAlertView(title: "Not Implemented", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
        //self.performSegueWithIdentifier("WatchingListSegue", sender: self)
    }
    
    override func fetchedResultsControllerForViewController(viewController: UIViewController) -> NSFetchedResultsController {
        return self.fetchedResultsController
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == nil {
            return
        }
        
        switch segue.identifier! {
        case "ImageDetailSegue":
            if let imageDetailViewController = segue.destinationViewController as? ImageDetailViewController {
                imageDetailViewController.image = self.selectedDetailImage
                self.selectedDetailImage = nil
            }

        case "CreateMessageSegue" :
            if let navigationController = segue.destinationViewController as? UINavigationController {
                if let postMessageViewController = navigationController.topViewController as? PostMessageViewController {
                    // pass along the data store
                    postMessageViewController.dataStore = self.dataStore
                    postMessageViewController.receiverString = patch.name
                    postMessageViewController.patchID = patch.id_
                }
            }
        case "EditPatchSegue" :
            if let navigationController = segue.destinationViewController as? UINavigationController {
                if let editPatchViewController = navigationController.topViewController as? CreateEditPatchViewController {
                    // pass along the patch to edit.
                    editPatchViewController.patch = patch
                }
            }
        case "LikeListSegue", "WatchingListSegue" :
            if let userListViewController = segue.destinationViewController as? UserTableViewController {
                userListViewController.managedObjectContext = self.managedObjectContext
                userListViewController.dataStore = self.dataStore
                userListViewController.patchId = self.patch.id_
                userListViewController.filter = segue.identifier == "LikeListSegue" ? .Likers : .Watchers
            }
        default: ()
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let canDelete = true; // TODO: determine if current user has delete permission for message
        let sheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: canDelete ? "Delete" : nil)
        sheet.addButtonWithTitle("Like")
        sheet.addButtonWithTitle("Share")
        sheet.addButtonWithTitle("Report Abuse")
        sheet.showFromTabBar(self.tabBarController?.tabBar)
        sheet.willDismissBlock = { (actionSheet, index) -> Void in
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        sheet.tapBlock = { (actionSheet, index) -> Void in
            if index == actionSheet.cancelButtonIndex {
                
            } else if index == actionSheet.destructiveButtonIndex {
                NSLog("Destructive button")
                UIAlertView(title: "Not implemented", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
            } else {
                // Switching on the button title is less than ideal, but there seems to be issues with 
                // using the firstOtherButtonIndex property. Once iOS 7 support is dropped, move to UIAlertController
                let buttonTitle = actionSheet.buttonTitleAtIndex(index)
                switch buttonTitle {
                case "Report Abuse":
                    UIAlertView(title: "Not implemented", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
                case "Like":
                    UIAlertView(title: "Not implemented", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
                case "Share":
                    UIAlertView(title: "Not implemented", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
                default:
                    UIAlertView(title: "Not implemented", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
                    NSLog("No action configured for button with title: \(buttonTitle)")
                }
            }
            
        }
    }
    
    // TODO: This is duplicated in NotificationTableViewController
    // https://github.com/smileyborg/TableViewCellWithAutoLayout
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let reuseIdentifier = "Cell"
        var cell = self.offscreenCells.objectForKey(reuseIdentifier) as? UITableViewCell
        if cell == nil {
            let nibObjects = NSBundle.mainBundle().loadNibNamed(cellNibName, owner: self, options: nil)
            cell = nibObjects[0] as? UITableViewCell
            self.offscreenCells.setObject(cell!, forKey: reuseIdentifier)
        }
        
        let object: AnyObject = self.fetchedResultsController.objectAtIndexPath(indexPath)
        self.configureCell(cell!, object: object)
        cell?.setNeedsUpdateConstraints()
        cell?.updateConstraintsIfNeeded()
        cell?.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell!.frame))
        cell?.setNeedsLayout()
        cell?.layoutIfNeeded()
        var height = cell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        height += 1
        return height
    }
    
    // MARK: TableViewCellDelegate
    
    func tableViewCell(cell: UITableViewCell, didTapOnView view: UIView) {
        let messageCell = cell as MessageTableViewCell
        if view == messageCell.messageImageView && messageCell.messageImageView.image != nil {
            self.selectedDetailImage = messageCell.messageImageView.image
            self.performSegueWithIdentifier("ImageDetailSegue", sender: view)
        }
    }

    @IBAction func unwindFromCreateMessage(segue: UIStoryboardSegue) {
        // Refresh results when unwinding from Message screen to pickup any changes.
        self.refreshPatchAndMessages { (error) -> Void in }
    }
    
    @IBAction func unwindFromCreatePatch(segue: UIStoryboardSegue) {
        // Refresh results when unwinding from Patch edit/create screen to pickup any changes.
        self.refreshPatchAndMessages { (error) -> Void in }
    }
    
    func pullToRefreshAction(sender: AnyObject?) -> Void {
        self.refreshPatchAndMessages { (error) -> Void in
            // Delay seems to be necessary to avoid visual glitch with UIRefreshControl
            delay(0.1, { () -> () in
                self.refreshControl?.endRefreshing()
                return
            })
        }
    }
    
    // Refreshes the query and likes/watches, and calls updatePatchDetailUI before completion
    func refreshPatchAndMessages(completion:(error: NSError?) -> Void) {
        self.refreshLikeAndWatch()
        self.dataStore.refreshResultsFor(self.query, completion: { (_, error) -> Void in
            self.updatePatchDetailUI()
            completion(error: error)
        })
    }
    
    @IBAction func contextButtonAction(sender: UIButton) {
        switch self.patchMembershipStatus {
        case .Member:
            self.performSegueWithIdentifier("CreateMessageSegue", sender: self)
        case .Pending:
            let proxibase = ProxibaseClient.sharedInstance
            if self.watchLinkId != nil {
                proxibase.deleteLink(self.watchLinkId!) { _, _ in
                    self.refreshLikeAndWatch()
                }
            }
        case .NonMember:
            if self.patch.visibilityValue == .Public {
                self.performSegueWithIdentifier("CreateMessageSegue", sender: self)
            } else {
                let proxibase = ProxibaseClient.sharedInstance
                proxibase.createLink(proxibase.userId!, toID: patch.id_, linkType: .Watch) { _, _ in
                    self.refreshLikeAndWatch()
                }
            }
        case .Unknown: () // No-op
        }
    }
    
    
    // MARK: Private Internal
    
    func handleRemoteNotification(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            
            let parentId = userInfo["parentId"] as? String
            let targetId = userInfo["targetId"] as? String
            
            let impactedByNotification = self.patch?.id_ == parentId || self.patch?.id_ == targetId
            
            // Only refresh notifications if view has already been loaded
            // and the notification is related to this Patch
            if self.isViewLoaded() && impactedByNotification {
                self.refreshControl?.beginRefreshing()
                self.pullToRefreshAction(self.refreshControl)
                self.refreshLikeAndWatch()
            }
        }
    }
}

enum PatchMembershipStatus : String {
    case Member = "Member"
    case Pending = "Pending"
    case NonMember = "NonMember"
    case Unknown = "Unknown"
}
