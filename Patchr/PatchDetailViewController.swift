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
    
    private var selectedDetailImage: UIImage?
    private var messageDateFormatter: NSDateFormatter!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "MessageTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        // TODO consolidate this workaround across the table view controllers
        // iOS 7 doesn't support the new style self-sizing cells
        // http://stackoverflow.com/a/26283017/2247399
        if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 {
            self.tableView.rowHeight = UITableViewAutomaticDimension;
        } else {
            // iOS 7
            self.tableView.rowHeight = 100
        }
        
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "Messages for patch"
        query.parameters = ["patchId" : patch.id_]
        self.managedObjectContext.save(nil)
        self.query = query
        dataStore.refreshResultsFor(self.query, completion: { (results, error) -> Void in
            
        })
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        self.messageDateFormatter = dateFormatter
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.patchImageView.setImageWithURL(patch.photo?.photoURL())
        self.patchNameLabel.text = patch.name
        self.patchCategoryLabel.text = patch.category?.name
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.tableView.reloadData()
    }
    
    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        let message = object as Message
        let messageCell = cell as MessageTableViewCell
        messageCell.delegate = self
        messageCell.messageBodyLabel.text = message.description_
        
        messageCell.messageImageView.image = nil
        if let photo = message.photo {
            messageCell.messageImageView.setImageWithURL(photo.photoURL())
            messageCell.messageImageViewMaxHeightConstraint.constant = 10000
        } else {
            messageCell.messageImageViewMaxHeightConstraint.constant = 0
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
    
    @IBAction func watchAction(sender: AnyObject)
    {
        println("watch")
    }
    
    @IBAction func likeAction(sender: AnyObject)
    {
        println("like")
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
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let message = self.fetchedResultsController.objectAtIndexPath(indexPath) as Message
        if message.photo != nil {
            return 274
        } else {
            return 122.5
        }
    }
    
    // MARK: NotificationTableViewCellDelegate
    
    func tableViewCell(cell: MessageTableViewCell, didTapOnView view: UIView) {
        if view == cell.messageImageView && cell.messageImageView.image != nil {
            self.selectedDetailImage = cell.messageImageView.image
            self.performSegueWithIdentifier("ImageDetailSegue", sender: view)
        }
    }

    @IBAction func unwindFromCreateMessage(segue: UIStoryboardSegue) {
        dataStore.refreshResultsFor(self.query, completion: { (results, error) -> Void in })
    }
    
    @IBAction func unwindFromCreatePatch(segue: UIStoryboardSegue) {}
}
