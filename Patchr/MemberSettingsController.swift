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
    var channelsBefore: [String: Any] = [:]
    var channelsAfter: [String: Any] = [:]

    var roleOwnerCell = AirTableViewCell()
    var roleMemberCell = AirTableViewCell()
    var roleGuestCell = AirTableViewCell()
    var guestChannelsCell = AirTableViewCell()
    var removeFromGroupCell = AirTableViewCell()
    var removeFromGroupButton = AirLinkButton()
    
    var roleValue: String? = nil

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
        bind()
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

    func doneAction(sender: AnyObject?) {
        update()
        closeAction(sender: nil)
    }

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
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 48
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0

        self.roleOwnerCell.textLabel?.text = "Owner"
        self.roleMemberCell.textLabel?.text = "Member"
        self.roleGuestCell.textLabel?.text = "Guest"
        
        self.roleOwnerCell.selectionStyle = .none
        self.roleMemberCell.selectionStyle = .none
        self.roleGuestCell.selectionStyle = .none
        
        self.guestChannelsCell.textLabel?.numberOfLines = 0
        self.guestChannelsCell.textLabel?.text = nil
        self.guestChannelsCell.textLabel?.lineBreakMode = .byWordWrapping
        self.guestChannelsCell.bounds = CGRect(x: 0, y: 0, width: self.view.width(), height: 9999)
        
        let groupTitle = StateController.instance.group.title!
        self.removeFromGroupCell.contentView.addSubview(self.removeFromGroupButton)
        self.removeFromGroupCell.accessoryType = .none
        self.removeFromGroupButton.setTitle("Remove from \(groupTitle) ".uppercased(), for: .normal)        
        self.removeFromGroupButton.addTarget(self, action: #selector(removeFromGroupAction(sender:)), for: .touchUpInside)
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
        self.navigationItem.leftBarButtonItems = [closeButton]
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [doneButton]
    }
    
    func bind() {
        self.roleValue = self.inputUser.role
        self.roleOwnerCell.accessoryType = self.roleValue == "owner" ? .checkmark : .none
        self.roleMemberCell.accessoryType = self.roleValue == "member" ? .checkmark : .none
        self.roleGuestCell.accessoryType = self.roleValue == "guest" ? .checkmark : .none
        
        let groupId = StateController.instance.groupId!
        let userId = self.inputUser.id!
        FireController.db.child("member-channels/\(userId)/\(groupId)")
            .observeSingleEvent(of: .value, with: { snap in
                if !(snap.value is NSNull) {
                    let channels = snap.value as! [String: Any]
                    for channelId in channels.keys {
                        FireController.db.child("group-channels/\(groupId)/\(channelId)")
                            .observeSingleEvent(of: .value, with: { snap in
                                if let channel = snap.value as? [String: Any] {
                                    self.channelsBefore[channelId] = channel["name"]
                                    self.channelsAfter[channelId] = channel["name"]
                                    self.tableView.reloadData()
                                }
                        })
                    }
                }
        })
    }
    
    func bindChannels() {
        var channelsLabel = ""
        for channelName in self.channelsAfter.values {
            if !channelsLabel.isEmpty {
                channelsLabel += "\r\n"
            }
            channelsLabel += "\(channelName)"
        }
        self.guestChannelsCell.textLabel?.text = channelsLabel
        self.guestChannelsCell.bounds = CGRect(x: 0, y: 0, width: self.view.width(), height: 9999)
        self.guestChannelsCell.setNeedsLayout()
        self.guestChannelsCell.layoutIfNeeded()
    }
    
    func update() {
        
        let groupId = StateController.instance.groupId!
        let userId = self.inputUser.id!
        
        if self.roleValue != self.inputUser.role {
            
            let role = self.roleValue!
            let memberGroupsPath = "member-groups/\(userId)/\(groupId)/role"
            let groupMembersPath = "group-members/\(groupId)/\(userId)/role"
            
            let updates: [String: Any] = [
                groupMembersPath: role,
                memberGroupsPath: role
            ]
            
            FireController.db.updateChildValues(updates)
            
            /* Switching to full member */
            if self.inputUser.role == "guest" {
                FireController.db.child("groups/\(groupId)/default_channels")
                    .observeSingleEvent(of: .value, with: { snap in
                    if let channelIds = snap.value as? [String] {
                        for channelId in channelIds {
                            if self.channelsAfter[channelId] == nil {
                                FireController.instance.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: nil)
                            }
                        }
                    }
                })
            }
        }
            
        /* Find channel removals */
        for channelId in self.channelsBefore.keys {
            if self.channelsAfter[channelId] == nil {
                let channelName = self.channelsBefore[channelId] as! String
                FireController.instance.removeUserFromChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName)
            }
        }
        
        /* Find channel additions */
        for channelId in self.channelsAfter.keys {
            if self.channelsBefore[channelId] == nil {
                let channelName = self.channelsAfter[channelId] as! String
                FireController.instance.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName)
            }
        }
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
                    self.progress!.styleAs(progressStyle: .activityWithText)
                    self.progress!.minShowTime = 0.5
                    self.progress!.labelText = "Removing..."
                    self.progress!.removeFromSuperViewOnHide = true
                    self.progress!.show(true)
                    
                    if let group = StateController.instance.group {
                        let userId = self.inputUser.id!
                        FireController.instance.removeUserFromGroup(userId: userId, groupId: group.id!, then: { success in
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
            let selectedCell = tableView.cellForRow(at: indexPath)
            
            self.roleValue = selectedCell?.textLabel!.text!.lowercased()
            self.roleOwnerCell.accessoryType = .none
            self.roleMemberCell.accessoryType = .none
            self.roleGuestCell.accessoryType = .none
            
            selectedCell!.accessoryType = .checkmark
            self.tableView.reloadData()
        }
        else if self.roleValue == "guest" && indexPath.section == 1 {
            let controller = ChannelPickerController()
            let wrapper = AirNavigationController(rootViewController: controller)
            if self.channelsAfter.count > 0 {
                for channelId in self.channelsAfter.keys {
                    let channel = self.channelsAfter[channelId]
                    controller.channels[channelId] = channel
                }
            }
            controller.delegate = self
            self.navigationController?.present(wrapper, animated: true, completion: nil)
        }
    }

    override func numberOfSections(in: UITableView) -> Int {
        return self.roleValue == "guest" ? 3 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 3 }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 { return self.roleOwnerCell }
            if indexPath.row == 1 { return self.roleMemberCell }
            if indexPath.row == 2 { return self.roleGuestCell }
        }
        if (self.roleValue == "guest" && indexPath.section == 1) {
            bindChannels()
            return self.guestChannelsCell
        }
        return self.removeFromGroupCell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Group role".uppercased()
        }
        if self.roleValue == "guest" && section == 1 {
            return "Guest channels".uppercased()
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
}

extension MemberSettingsController: PickerDelegate {
    internal func update(channels: [String: Any]) {
        self.channelsAfter = channels
        self.tableView.reloadData()
    }
}

