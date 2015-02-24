//
//  WatchingTableViewViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-29.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MeTableViewViewController: QueryResultTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "Current user authored messages"
        query.limitValue = 25
        query.path = ""
        self.managedObjectContext.save(nil)
        self.query = query
        dataStore.loadMoreResultsFor(self.query, completion: { (results, error) -> Void in
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
        if let queryResult = object as? QueryResult {
            if let message = queryResult.entity_ as? Message {
                cell.textLabel?.text = "A message"
            } else {
                cell.textLabel?.text = "Unknown QueryResult entity type"
            }
        } else {
            cell.textLabel?.text = "Object \(String.fromCString(object_getClassName(object)))"
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
    }
    
    @IBAction func logoutButtonAction(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "com.3meters.patchr.ios.userId")
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "com.3meters.patchr.ios.sessionKey")
        NSUserDefaults.standardUserDefaults().synchronize()
        self.dataStore.proxibaseClient.signOut { (response, error) -> Void in
            if error != nil {
                NSLog("Error during logout \(error)")
            }
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            let destinationViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as UIViewController
            appDelegate.window!.setRootViewController(destinationViewController, animated: true)
        }
    }
    
}
