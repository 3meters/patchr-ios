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

class UserTableViewController: QueryResultTableViewController, UserTableViewCellDelegate {
    
    private let cellNibName = "UserTableViewCell"
    
    var patch: Patch!
    var filter: UserTableFilter = .Watchers
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: cellNibName, bundle: nil), forCellReuseIdentifier: "Cell")
        self.tableView.delaysContentTouches = false
        
        switch self.filter {
        case .Watchers:
            self.navigationItem.title = "Watchers"
        case .Likers:
            self.navigationItem.title = "Likers"
        }
    }
    
    private var _query: Query!
    override func query() -> Query {
        if self._query == nil {
            let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
            
            switch self.filter {
            case .Likers:
                query.name = DataStoreQueryName.LikersLinksForPatch.rawValue
            case .Watchers:
                query.name = DataStoreQueryName.WatchersLinksForPatch.rawValue
            }
            
            query.parameters = ["patchId" : self.patch.id_]
            
            self.managedObjectContext.save(nil)
            self._query = query
        }
        return self._query
    }
    
    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        
        let queryResult = object as QueryResult
        let userCell = cell as UserTableViewCell
        userCell.delegate = self
        
        let link = queryResult.result as PALink
        self.dataStore.withUser(link.fromId, refresh: true) { (user) -> Void in
            if user != nil {
                
                userCell.usernameLabel.text = user!.name
                userCell.locationLabel.text = user!.area
                userCell.ownerLabel.text = user!.id_ == self.patch.creatorId ? "Owner" : nil
                userCell.avatarImageView.pa_setImageWithURL(user!.photo?.photoURL(), placeholder: UIImage(named: "UserAvatarDefault"))
                userCell.approvedSwitch.on = link.enabledValue
                
                userCell.usernameLabel.hidden = userCell.usernameLabel.text == nil
                userCell.locationLabel.hidden = userCell.locationLabel.text == nil
                userCell.ownerLabel.hidden = userCell.ownerLabel.text == nil
                
                // Private patch owner controls controls
                if self.filter == .Watchers && self.patch.visibilityValue == PAVisibilityLevel.Private {
                    
                    self.dataStore.withCurrentUser(refresh: false, completion: { (currentUser) -> Void in
                        
                        var hideCellAdminControls : Bool = true
                        
                        if currentUser.id_ == self.patch.creatorId {
                            
                            if user!.id_ != currentUser.id_ {
                                // Only show admin controls if current user is patch owner AND 
                                // the cell is not the current user's cell
                                hideCellAdminControls = false
                            }
                            
                        }
                        
                        userCell.removeButton.hidden = hideCellAdminControls
                        userCell.approvedLabel.text = hideCellAdminControls ? nil : "Approved:"
                        userCell.approvedLabel.hidden = hideCellAdminControls
                        userCell.approvedSwitch.hidden = hideCellAdminControls
                    })
                }
                
            }
        }
    }
    
    // MARK: UserTableViewCellDelegate
    
    func userTableViewCell(userTableViewCell: UserTableViewCell, approvalSwitchValueChanged approvalSwitch: UISwitch) {
        if let indexPath = self.tableView.indexPathForCell(userTableViewCell) {
            if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryResult {
                if let link = queryResult.result as? PALink {
                    approvalSwitch.enabled = false
                    let linkEnabled = approvalSwitch.on
                    ProxibaseClient.sharedInstance.updateLink(link.id_, enabled: linkEnabled, completion: { (response, error) -> Void in
                        if error != nil {
                            SCLAlertView().showError(self, title:"Error", subTitle: error!.localizedDescription , closeButtonTitle: "OK", duration: 0.0)
                            // Toggle the switch since it failed
                            approvalSwitch.on = !linkEnabled
                        } else {
                            link.enabledValue = linkEnabled
                            self.managedObjectContext.save(nil)
                        }
                        approvalSwitch.enabled = true
                    })
                }
            }
        }
    }
    
    func userTableViewCell(userTableViewCell: UserTableViewCell, removeButtonTapped removeButton: UIButton) {
        if let indexPath = self.tableView.indexPathForCell(userTableViewCell) {
            if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryResult {
                if let link = queryResult.result as? PALink {
                    ProxibaseClient.sharedInstance.deleteLink(link.id_, completion: { (response, error) -> Void in
                        if error != nil {
                            SCLAlertView().showError(self, title:"Error", subTitle: error!.localizedDescription , closeButtonTitle: "OK", duration: 0.0)
                        } else {
                            self.managedObjectContext.deleteObject(link)
                            self.managedObjectContext.deleteObject(queryResult)
                            self.managedObjectContext.save(nil)
                        }
                    })
                }
            }
        }
    }
   
}
