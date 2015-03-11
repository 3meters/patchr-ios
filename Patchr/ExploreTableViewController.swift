//
//  MostPopularTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-29.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class ExploreTableViewController: PatchTableViewController {
    
    private var _query: Query!
    override func query() -> Query {
        if self._query == nil {
            let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
            query.name = "Explore patches"
            self._query = query
            self.managedObjectContext.save(nil)
        }
        return self._query
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchDisplayController?.searchResultsTableView.rowHeight = self.tableView.rowHeight
        self.searchDisplayController?.searchResultsTableView.estimatedRowHeight = self.tableView.estimatedRowHeight
        
        // Sets search bar under nav bar initially
        self.tableView.contentOffset = CGPointMake(0, self.searchDisplayController?.searchBar.frame.size.height ?? 0)
    }
}
