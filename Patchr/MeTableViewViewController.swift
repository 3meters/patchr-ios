//
//  WatchingTableViewViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-29.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MeTableViewViewController: QueryResultTableViewController, TableViewCellDelegate, UITextFieldDelegate {
    
    private let cellNibName = "MessageTableViewCell"
    
    @IBOutlet weak var currentUserNameField: UILabel!
    @IBOutlet weak var currentUserProfilePhoto: UIImageView!
    @IBOutlet weak var currentUserEmailField: UILabel!
    
    private var selectedDetailImage: UIImage?
    private var messageDateFormatter: NSDateFormatter!
    private var offscreenCells: NSMutableDictionary = NSMutableDictionary()
    
    private var _query: Query!
    override func query() -> Query {
        if self._query == nil {
            let query = Query.insertInManagedObjectContext(self.managedObjectContext) as! Query
            query.name = "Comments by current user"
            self.managedObjectContext.save(nil)
            self._query = query
        }
        return self._query
    }
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: cellNibName, bundle: nil), forCellReuseIdentifier: "Cell")
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        self.messageDateFormatter = dateFormatter
        
        self.currentUserNameField.text = nil
        self.currentUserEmailField.text = nil
        
        dataStore.withCurrentUser(completion: { user in
            self.currentUserNameField.text = user.name
            self.currentUserEmailField.text = user.email

            if let thePhoto = user.photo
            {
                self.currentUserProfilePhoto.pa_setImageWithURL(thePhoto.photoURL(), placeholder: UIImage(named: "UserAvatarDefault"))
            }
        })
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
        default: ()
        }
    }
    
    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        // The cell width seems to incorrect occassionally
        if CGRectGetWidth(cell.bounds) != CGRectGetWidth(self.tableView.bounds) {
            cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell.frame))
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }
        
        let queryResult = object as! QueryResult
        let message = queryResult.result as! Message
        let messageCell = cell as! MessageTableViewCell
        messageCell.delegate = self
        
        messageCell.patchNameLabel.text = message.type == "share" ? "Shared by" : ""
        messageCell.messageBodyLabel.text = message.description_
        
        messageCell.messageImageView.image = nil
        if let photo = message.photo {
            messageCell.messageImageView.pa_setImageWithURL(photo.photoURL())
            let imageMarginTop : CGFloat = 10.0;
            messageCell.messageImageContainerHeight.constant = messageCell.messageImageView.frame.height + imageMarginTop
        } else {
            messageCell.messageImageContainerHeight.constant = 0;
        }
        
        messageCell.userAvatarImageView.image = nil
        messageCell.userNameLabel.text = nil
        self.dataStore.withCurrentUser(refresh: false) { (user) -> Void in
            messageCell.userNameLabel.text = user.name
            messageCell.userAvatarImageView.pa_setImageWithURL(user.photo?.photoURL(), placeholder: UIImage(named: "UserAvatarDefault"))
        }
        
        messageCell.likesLabel.text = "\(message.numberOfLikes?.integerValue ?? 0) Likes"
        messageCell.createdDateLabel.text = self.messageDateFormatter.stringFromDate(message.createdDate)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
    }
    
    @IBAction func logoutButtonAction(sender: AnyObject) {

        ProxibaseClient.sharedInstance.signOut { (response, error) -> Void in
            if error != nil {
                NSLog("Error during logout \(error)")
            }
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let destinationViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as! UIViewController
            appDelegate.window!.setRootViewController(destinationViewController, animated: true)
        }
    }
    
    @IBAction func watchingButtonAction(sender: UIButton) {
        UIAlertView(title: "Not Implemented", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
    }
    
    @IBAction func ownerButtonAction(sender: UIButton) {
        UIAlertView(title: "Not Implemented", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
    }
    
    // MARK: TableViewCellDelegate
    
    func tableViewCell(cell: UITableViewCell, didTapOnView view: UIView) {
        let messageCell = cell as! MessageTableViewCell
        if view == messageCell.messageImageView && messageCell.messageImageView.image != nil {
            self.selectedDetailImage = messageCell.messageImageView.image
            self.performSegueWithIdentifier("ImageDetailSegue", sender: view)
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
    
}
