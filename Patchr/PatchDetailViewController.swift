//
//  PatchDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchDetailViewController: FetchedResultsTableViewController {
    
    @IBOutlet weak var patchImageView: UIImageView!
    @IBOutlet weak var patchNameLabel: UILabel!
    @IBOutlet weak var patchCategoryLabel: UILabel!
    @IBOutlet weak var watchButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    
    var managedObjectContext: NSManagedObjectContext!
    var query : Query!
    var dataStore: DataStore!
    var patch: Patch!
    
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
        self.tableView.registerNib(UINib(nibName: "NotificationTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        // TODO consolidate this workaround across the table view controllers
        // iOS 7 doesn't support the new style self-sizing cells
        // http://stackoverflow.com/a/26283017/2247399
        if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 {
            self.tableView.rowHeight = UITableViewAutomaticDimension;
            self.tableView.estimatedRowHeight = 100.0;
        } else {
            // iOS 7
            self.tableView.rowHeight = 100
        }
        
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "Messages for patch"
        query.parameters = ["patchId" : patch.id_]
        self.managedObjectContext.save(nil)
        self.query = query
        dataStore.loadMoreResultsFor(self.query, completion: { (results, error) -> Void in
            
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.patchImageView.setImageWithURL(patch.photo?.photoURL())
        self.patchNameLabel.text = patch.name
        self.patchCategoryLabel.text = patch.category?.name
    }
    
    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        let message = object as Message
        let notificationCell = cell as NotificationTableViewCell
        notificationCell.summaryLabel.text = message.description_
        
        notificationCell.notificationImageView.image = nil
        if let photo = message.photo {
            notificationCell.notificationImageMaxHeightConstraint.constant = 10000
            notificationCell.notificationImageView.setImageWithURL(photo.photoURL())
        } else {
            notificationCell.notificationImageMaxHeightConstraint.constant = 0
        }
        
        notificationCell.avatarImageView.image = nil;
        if let creator = message.creator as? User {
            if let creatorPhotoURL = creator.photo?.photoURL() {
                notificationCell.avatarImageView.setImageWithURL(creatorPhotoURL)
            } else {
                notificationCell.avatarImageView.image = UIImage(named: "Placeholder other user profile")
            }
        }
        
        notificationCell.dateLabel.text = message.createdDate.description
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

    @IBAction func unwindFromCreateMessage(segue: UIStoryboardSegue) {}
    @IBAction func unwindFromCreatePatch(segue: UIStoryboardSegue) {}
}
