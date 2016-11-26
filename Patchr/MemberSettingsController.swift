//
//  NotificationSettingsViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD

class MemberSettingsController: UITableViewController {
    
    var inputUser: FireUser!
    
    var progress: AirProgress?

    /* Role */
    var roleOwnerCell = AirTableViewCell()
    var roleAdminCell = AirTableViewCell()
    var roleMemberCell = AirTableViewCell()
    var roleGuestCell = AirTableViewCell()
    
    /* Group membership */
    var removeFromGroupCell = AirTableViewCell()
    var removeFromGroupButton = AirLinkButton()
    
    var presented: Bool {
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
            || self.tabBarController?.presentingViewController is UITabBarController
    }

    var roleValue: String? = nil

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.bounds.size.width)
        self.tableView.bounds.size.width = viewWidth
        self.removeFromGroupButton.fillSuperview()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func closeAction(sender: AnyObject?) {
        if self.presented {
            self.dismiss(animated: true, completion: nil)
        }
        else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        let userTitle = self.inputUser!.profile?.fullName ?? self.inputUser!.username!
        self.navigationItem.title = userTitle

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.tableView.rowHeight = 48
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0

        self.roleOwnerCell.textLabel?.text = "Owner"
        self.roleAdminCell.textLabel?.text = "Admin"
        self.roleMemberCell.textLabel?.text = "Member"
        self.roleGuestCell.textLabel?.text = "Guest"
        
        self.roleOwnerCell.selectionStyle = .none
        self.roleAdminCell.selectionStyle = .none
        self.roleMemberCell.selectionStyle = .none
        self.roleGuestCell.selectionStyle = .none
        
        self.roleOwnerCell.accessoryType = self.inputUser.role == "owner" ? .checkmark : .none
        self.roleAdminCell.accessoryType = self.inputUser.role == "admin" ? .checkmark : .none
        self.roleMemberCell.accessoryType = self.inputUser.role == "member" ? .checkmark : .none
        self.roleGuestCell.accessoryType = self.inputUser.role == "guest" ? .checkmark : .none
        
        let groupTitle = StateController.instance.group.title!
        self.removeFromGroupCell.contentView.addSubview(self.removeFromGroupButton)
        self.removeFromGroupCell.accessoryType = .none
        
        self.removeFromGroupButton.setTitle("Remove from \(groupTitle) ".uppercased(), for: .normal)        
        self.removeFromGroupButton.addTarget(self, action: #selector(removeFromGroupAction(sender:)), for: .touchUpInside)
    }
    
    func removeFromGroupAction(sender: AnyObject?) {
        
        let userTitle = self.inputUser!.profile?.fullName ?? self.inputUser!.username!

        DeleteConfirmationAlert(
            title: "Confirm",
            message: "Are you sure you want to remove \(userTitle) from this group?",
            actionTitle: "Remove", cancelTitle: "Cancel", delegate: self) { doIt in
                if doIt {
                    self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                    self.progress!.mode = MBProgressHUDMode.indeterminate
                    self.progress!.styleAs(progressStyle: .ActivityWithText)
                    self.progress!.minShowTime = 0.5
                    self.progress!.labelText = "Removing..."
                    self.progress!.removeFromSuperViewOnHide = true
                    self.progress!.show(true)
                    
                    if let group = StateController.instance.group {
                        FireController.instance.removeUserFromGroup(groupId: group.id!, then: { success in
                            self.progress?.hide(true)
                            if success {
                                self.closeAction(sender: nil)
                            }
                        })
                    }
                }
        }
    }
}

extension MemberSettingsController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            let groupId = StateController.instance.groupId!
            let userId = self.inputUser.id!
            let memberGroupsPath = "member-groups/\(userId)/\(groupId)/role"
            let groupMembersPath = "group-members/\(groupId)/\(userId)/role"
            
            let selectedCell = tableView.cellForRow(at: indexPath)
            
            self.roleOwnerCell.accessoryType = .none
            self.roleAdminCell.accessoryType = .none
            self.roleMemberCell.accessoryType = .none
            self.roleGuestCell.accessoryType = .none
            
            selectedCell!.accessoryType = .checkmark
            
            let updates: [String: Any] = [
                groupMembersPath: (selectedCell?.textLabel!.text!.lowercased())!,
                memberGroupsPath: (selectedCell?.textLabel!.text!.lowercased())!
            ]
            FireController.db.updateChildValues(updates)
        }
    }

    override func numberOfSections(in: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0: return 4
            case 1: return 1
            default: fatalError("Unknown number of sections")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section) {
            case 0:
                switch (indexPath.row) {
                    case 0: return self.roleOwnerCell
                    case 1: return self.roleAdminCell
                    case 2: return self.roleMemberCell
                    case 3: return self.roleGuestCell
                    default: fatalError("Unknown row in section 0")
                }
            case 1:
                switch (indexPath.row) {
                    case 0: return self.removeFromGroupCell
                    default: fatalError("Unknown row in section 1")
                }
            default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
            case 0: return "Group role".uppercased()
            case 1: return nil
            default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
}
