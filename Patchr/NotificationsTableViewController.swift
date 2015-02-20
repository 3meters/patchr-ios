//
//  NotificationsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NotificationsTableViewController: QueryResultTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "do/getNotifications"
        query.limitValue = 25
        query.path = "do/getNotifications"
        self.managedObjectContext.save(nil)
        self.query = query
        dataStore.loadMoreResultsFor(self.query, completion: { (results, error) -> Void in
            NSLog("Default query fetch for tableview")
        })
    }
    
    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        if let queryResult = object as? QueryResult {
            if let notification = queryResult.entity_ as? Notification {
                cell.textLabel?.text = notification.summary
            } else {
                cell.textLabel?.text = "Unknown QueryResult entity type"
            }
        } else {
            cell.textLabel?.text = "Object \(String.fromCString(object_getClassName(object)))"
        }
    }

}
