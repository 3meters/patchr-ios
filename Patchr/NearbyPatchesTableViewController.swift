//
//  NearbyPatchesTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-28.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NearbyPatchesTableViewController: QueryResultTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "patches/near"
        query.limitValue = 25
        query.path = "patches/near"
        self.managedObjectContext.save(nil)
        self.query = query
        self.dataStore.loadMoreResultsFor(self.query, completion: { (results, error) -> Void in
            NSLog("Default query fetch for tableview")
        })
    }

    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        if let queryResult = object as? QueryResult {
            if let patch = queryResult.entity_ as? Patch {
                cell.textLabel?.text = "\(patch.name) (\(patch.category.name)) Likes:\(patch.numberOfLikes) Watchers:\(patch.numberOfWatchers) Messages:\(patch.numberOfMessages) Lat:\(patch.location.latValue) Lng:\(patch.location.lngValue)"
            } else {
                cell.textLabel?.text = "Unknown QueryResult entity type"
            }
        } else {
            cell.textLabel?.text = "Object \(String.fromCString(object_getClassName(object)))"
        }
    }
}
