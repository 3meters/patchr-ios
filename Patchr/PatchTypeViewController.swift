//
//  PatchTypeViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

class PatchTypeViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate
{
    lazy var categoryList:[String] = ProxibaseClient.sharedInstance.categories.values.array.map { $0["id"] as String}
    
    var hostView: CreatePatchViewController? = nil
    var selectedType: String! = nil // set to the 'id' of the selected category
    
    // MARK: UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return ProxibaseClient.sharedInstance.categories.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("PatchTypeCell") as UITableViewCell
        let categoryID = categoryList[indexPath.row]
        let categoryDict:NSDictionary = ProxibaseClient.sharedInstance.categories[categoryID]!
        let cellString = categoryDict["name"] as String
        
        cell.textLabel?.text = cellString
        cell.accessoryType = (cellString == selectedType) ? .Checkmark : .None
        return cell
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.selectRowAtIndexPath(NSIndexPath(forRow:0, inSection:0), animated: true, scrollPosition: .None)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let textLabel = cell?.textLabel
        let text = textLabel?.text
        self.selectedType = text!
        
        self.selectedType = categoryList[indexPath.row]
        
        self.performSegueWithIdentifier("PatchTypeUnwind", sender: nil)
    }
    
    // prepareForSegue called when we leave this view
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let hostView = hostView
        {
            hostView.patchType = selectedType
        }
    }

}
