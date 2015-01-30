//
//  OwnerTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-29.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class OwnerTableViewController: QueryResultTableViewController {

    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        if let queryResult = object as? QueryResult {
            if let patch = queryResult.entity_ as? Patch {
                cell.textLabel?.text = "\(patch.name) (\(patch.category.name)) Lat:\(patch.location.latValue) Lng:\(patch.location.lngValue)"
            } else {
                cell.textLabel?.text = "Unknown QueryResult entity type"
            }
        } else {
            cell.textLabel?.text = "Object \(String.fromCString(object_getClassName(object)))"
        }
    }

}
