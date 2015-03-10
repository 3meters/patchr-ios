//
//  WatchingTableViewViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-29.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MeTableViewViewController: QueryResultTableViewController {
    @IBOutlet weak var currentUserNameField: UILabel!
    @IBOutlet weak var currentUserProfilePhoto: UIImageView!
    @IBOutlet weak var currentUserEmailField: UILabel!
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
        dataStore.withCurrentUser(completion: { user in
            self.currentUserNameField.text = user.name
            self.currentUserEmailField.text = user.email

            if let thePhoto = user.photo
            {
                self.currentUserProfilePhoto.setImageWithURL(thePhoto.photoURL())
            }
        })
        
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "Comments by current user"
        self.managedObjectContext.save(nil)
        self.query = query
        dataStore.refreshResultsFor(self.query, completion: { (results, error) -> Void in
            NSLog("Default query fetch for tableview")
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.clearsSelectionOnViewWillAppear = false;
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow() {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: animated)
        }
    }
    
    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        let queryResult = object as QueryResult
        let message = queryResult.entity_ as Message
        cell.textLabel?.text = message.description_
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
    }
    
    @IBAction func logoutButtonAction(sender: AnyObject) {

        ProxibaseClient.sharedInstance.signOut { (response, error) -> Void in
            if error != nil {
                NSLog("Error during logout \(error)")
            }
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            let destinationViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as UIViewController
            appDelegate.window!.setRootViewController(destinationViewController, animated: true)
        }
    }
    
}
