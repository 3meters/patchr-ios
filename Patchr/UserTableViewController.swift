//
//  UserTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

enum UserTableFilter {
    case Likers
    case Watchers
}

class UserTableViewController: QueryResultTableViewController {
    
    var patchId: String!
    var filter: UserTableFilter = .Watchers
    
    private var _query: Query!
    override func query() -> Query {
        if self._query == nil {
            let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
            
            switch self.filter {
            case .Likers:
                query.name = "Likers for patch"
            case .Watchers:
                query.name = "Watchers for patch"
            }
            
            query.parameters = ["patchId" : self.patchId]
            
            self.managedObjectContext.save(nil)
            self._query = query
        }
        return self._query
    }
   
}
