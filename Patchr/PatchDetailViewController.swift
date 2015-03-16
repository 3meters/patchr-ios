//
//  PatchDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchDetailViewController: FetchedResultsTableViewController, MessageTableViewCellDelegate {
    
    @IBOutlet weak var patchImageView: UIImageView!
    @IBOutlet weak var patchNameLabel: UILabel!
    @IBOutlet weak var patchCategoryLabel: UILabel!
    @IBOutlet weak var watchButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    
    var managedObjectContext: NSManagedObjectContext!
    var query : Query!
    var dataStore: DataStore!
    var patch: Patch!

    var likeLink: String? = nil
    var watchLink: String? = nil
    
    private var selectedDetailImage: UIImage?
    private var messageDateFormatter: NSDateFormatter!
    private var offscreenCells: NSMutableDictionary!
    
    private lazy var fetchControllerDelegate: FetchControllerDelegate = {
        return FetchControllerDelegate(tableView: self.tableView, onUpdate: self.configureCell)
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
    
    private func refreshLinkValue(linkType: LinkType, linkButton: UIButton, linkID: String?, titles:(String, String), setter: (String?) -> Void)
    {
        let linkIDValue: String? = linkID
        let proxibase = ProxibaseClient.sharedInstance
        let lt = linkType.rawValue
        
        proxibase.findLink(proxibase.userId!, toID: patch.id_, linkType: linkType) { response, error in
            dispatch_async(dispatch_get_main_queue())
            {
                if let serverError = ServerError(error)
                {
                    // ServerError initializer logs the error. Not much else to do here.
                }
                else
                {
                    let serverResponse = ServerResponse(response)
                    
                    if serverResponse.resultCount > 0
                    {
                        setter(serverResponse.resultID)
                        linkButton.setTitle(titles.1, forState: .Normal)
                    }
                    else
                    {
                        setter(nil)
                        linkButton.setTitle(titles.0, forState: .Normal)
                    }
                }
            }
        }
    }
    
    private func refreshLikeAndWatch()
    {
        refreshLinkValue(.Like, linkButton: self.likeButton, linkID: self.likeLink, titles: ("Like","Unlike")) { newValue in self.likeLink = newValue }
        refreshLinkValue(.Watch, linkButton: self.watchButton, linkID: self.watchLink, titles: ("Watch", "Unwatch")) { newValue in self.watchLink = newValue }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "MessageTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "Messages for patch"
        query.parameters = ["patchId" : patch.id_]
        self.managedObjectContext.save(nil)
        self.query = query
        dataStore.refreshResultsFor(self.query, completion: { (results, error) -> Void in
            
        })
        refreshLikeAndWatch()
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        self.messageDateFormatter = dateFormatter
        
        self.offscreenCells = NSMutableDictionary()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.patchImageView.setImageWithURL(patch.photo?.photoURL())
        self.patchNameLabel.text = patch.name
        self.patchCategoryLabel.text = patch.category?.name
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.tableView.reloadData() // NOTE: seems to be necessary to prevent a stange tableview jump bug on push transition
    }
    
    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        
        let message = object as Message
        let messageCell = cell as MessageTableViewCell
        messageCell.delegate = self
        
        messageCell.messageBodyLabel.text = message.description_
        
        messageCell.messageImageView.image = nil
        if let photo = message.photo {
            messageCell.messageImageView.setImageWithURL(photo.photoURL())
//            messageCell.messageImageViewMaxHeightConstraint.constant = 10000
        } else {
//            messageCell.messageImageViewMaxHeightConstraint.constant = 0
        }
        
        messageCell.userAvatarImageView.image = nil
        messageCell.userNameLabel.text = nil
        if let creator = message.creator as? User {
            messageCell.userNameLabel.text = creator.name
            if let creatorPhotoURL = creator.photo?.photoURL() {
                messageCell.userAvatarImageView.setImageWithURL(creatorPhotoURL)
            } else {
                messageCell.userAvatarImageView.image = UIImage(named: "Placeholder other user profile")
            }
        }
        
        messageCell.likesLabel.text = nil
        if message.numberOfLikes?.integerValue > 0 {
            messageCell.likesLabel.text = "\(message.numberOfLikes?.integerValue) Likes"
        }
        
        messageCell.createdDateLabel.text = self.messageDateFormatter.stringFromDate(message.createdDate)
    }
    
    private func toggleLinkState(linkValue: String?, ofType linkType: LinkType)
    {
        let proxibase = ProxibaseClient.sharedInstance
        if let linkID = linkValue
        {
            proxibase.deleteLink(linkID) { _, _ in
                self.refreshLikeAndWatch()
            }
        }
        else
        {
            proxibase.createLink(proxibase.userId!, toID: patch.id_, linkType: linkType) { _, _ in
                dispatch_async(dispatch_get_main_queue()){
                    self.refreshLikeAndWatch()
                }
            }
        }
    }
    
    @IBAction func watchAction(sender: AnyObject)
    {
        toggleLinkState(watchLink, ofType: .Watch)
    }
    
    @IBAction func likeAction(sender: AnyObject)
    {
        toggleLinkState(likeLink, ofType: .Like)
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
        default: ()
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // TODO show action sheet with options for messages
    }
    
    // https://github.com/smileyborg/TableViewCellWithAutoLayout
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let reuseIdentifier = "Cell"
        var cell = self.offscreenCells.objectForKey(reuseIdentifier) as? UITableViewCell
        if cell == nil {
            let nibObjects = NSBundle.mainBundle().loadNibNamed("MessageTableViewCell", owner: self, options: nil)
            cell = nibObjects[0] as? UITableViewCell
            self.offscreenCells.setObject(cell!, forKey: reuseIdentifier)
            cell?.setTranslatesAutoresizingMaskIntoConstraints(false)
        }
        
        let message = self.fetchedResultsController.objectAtIndexPath(indexPath) as Message
        self.configureCell(cell!, object: message)
        cell?.setNeedsUpdateConstraints()
        cell?.updateConstraintsIfNeeded()
        cell?.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: 311)
        cell?.setNeedsLayout()
        cell?.layoutIfNeeded()
        var height = cell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        height += 1
        return height
    }
    
    // MARK: NotificationTableViewCellDelegate
    
    func tableViewCell(cell: MessageTableViewCell, didTapOnView view: UIView) {
        if view == cell.messageImageView && cell.messageImageView.image != nil {
            self.selectedDetailImage = cell.messageImageView.image
            self.performSegueWithIdentifier("ImageDetailSegue", sender: view)
        }
    }

    @IBAction func unwindFromCreateMessage(segue: UIStoryboardSegue) {
        // Refresh results when unwinding from Patch edit/create screen to pickup any changes.
        dataStore.refreshResultsFor(self.query, completion: { (results, error) -> Void in })
    }
    
    @IBAction func unwindFromCreatePatch(segue: UIStoryboardSegue) {}
}
