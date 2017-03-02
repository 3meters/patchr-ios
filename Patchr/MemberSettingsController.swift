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
    var inputChannel: FireChannel!
    
    var progress: AirProgress?
    var channelsBefore: [String: Any] = [:]
    var channelsAfter: [String: Any] = [:]

    var roleOwnerCell = AirTableViewCell()
    var roleMemberCell = AirTableViewCell()
    var roleGuestCell = AirTableViewCell()
    var guestChannelsCell = AirTableViewCell()
    var removeCell = AirTableViewCell()
    var removeButton = AirLinkButton()
    
    var role: String? = nil
    var roleNext: String? = nil
    var target: MemberTarget = .group

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
        let viewWidth = min(Config.contentWidthMax, self.tableView.bounds.size.width)
        self.tableView.bounds.size.width = viewWidth
        self.removeButton.fillSuperview()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject?) {
        update()
    }

    func closeAction(sender: AnyObject?) {
        close(animated: true)
    }

    func removeAction(sender: AnyObject?) {
        if self.role == "owner" {    // Check if only owner
            let groupId = StateController.instance.groupId!
            let channelId = self.inputChannel.id!
            FireController.instance.channelRoleCount(groupId: groupId, channelId: channelId, role: "owner") { count in
                if count != nil && count! < 2 {
                    self.alert(title: "Only Owner", message: "Channels need at least one owner.")
                    return
                }
                self.remove()
            }
            return
        }
        remove()
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
        
        self.guestChannelsCell.textLabel?.numberOfLines = 10
        self.guestChannelsCell.textLabel?.text = nil
        self.guestChannelsCell.textLabel?.lineBreakMode = .byWordWrapping
        self.guestChannelsCell.bounds = CGRect(x: 0, y: 0, width: self.view.width(), height: 9999)
        
        let targetTitle = self.target == .group ? StateController.instance.group.title! : self.inputChannel.name!
        self.removeCell.contentView.addSubview(self.removeButton)
        self.removeCell.accessoryType = .none
        self.removeButton.setTitle("Remove from \(targetTitle) ".uppercased(), for: .normal)
        self.removeButton.addTarget(self, action: #selector(removeAction(sender:)), for: .touchUpInside)
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
        self.navigationItem.leftBarButtonItems = [closeButton]
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [doneButton]
    }
    
    func bind() {

        let groupId = StateController.instance.groupId!
        let userId = self.inputUser.id!
        
        if self.target == .group {
            
            self.role = self.inputUser.role
            self.roleNext = self.inputUser.role
            self.roleOwnerCell.accessoryType = self.role == "owner" ? .checkmark : .none
            self.roleMemberCell.accessoryType = self.role == "member" ? .checkmark : .none
            self.roleGuestCell.accessoryType = self.role == "guest" ? .checkmark : .none

            let path = "member-channels/\(userId)/\(groupId)"
            FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
                if !(snap.value is NSNull) {
                    let channels = snap.value as! [String: Any]
                    for channelId in channels.keys {
                        let path = "group-channels/\(groupId)/\(channelId)"
                        FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
                            if let channel = snap.value as? [String: Any] {
                                self.channelsBefore[channelId] = channel["name"]
                                self.channelsAfter[channelId] = channel["name"]
                                self.tableView.reloadData()
                            }
                        }, withCancel: { error in
                            Log.w("Permission denied reading: \(path)")
                        })
                    }
                }
            }, withCancel: { error in
                Log.w("Permission denied reading: \(path)")
            })
        }
        else {
            let channelId = self.inputChannel.id!
            let path = "group-channel-members/\(groupId)/\(channelId)/\(userId)/role"
            FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
                if let memberRole = snap.value as? String {
                    self.role = memberRole
                    self.roleNext = memberRole
                    self.roleOwnerCell.accessoryType = self.role == "owner" ? .checkmark : .none
                    self.roleMemberCell.accessoryType = self.role == "member" ? .checkmark : .none
                }
            }, withCancel: { error in
                Log.w("Permission denied reading: \(path)")
            })
        }
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

        if self.target == .group {
            if self.roleNext != self.role {

                let role = self.roleNext!
                let memberGroupsPath = "member-groups/\(userId)/\(groupId)/role"
                let groupMembersPath = "group-members/\(groupId)/\(userId)/role"

                let updates: [String: Any] = [
                    groupMembersPath: role,
                    memberGroupsPath: role
                ]

                FireController.db.updateChildValues(updates)

                /* Switching to full member */
                if self.role == "guest" {
                    FireController.db.child("groups/\(groupId)/default_channels")
                            .observeSingleEvent(of: .value, with: { snap in
                                if let channelIds = snap.value as? [String] {
                                    for channelId in channelIds {
                                        if self.channelsAfter[channelId] == nil {
                                            FireController.instance.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: nil)
                                        }
                                    }
                                }
                            }, withCancel: { error in
                                Log.w("Permission denied reading: groups/\(groupId)/default_channels")
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
            closeAction(sender: nil)
        }
        else {
            if self.roleNext != self.role {
                
                let groupId = StateController.instance.groupId!
                let channelId = self.inputChannel.id!
                let memberChannelsPath = "member-channels/\(userId)/\(groupId)/\(channelId)/role"
                let channelMembersPath = "group-channel-members/\(groupId)/\(channelId)/\(userId)/role"

                if self.role == "owner" {    // Check if only owner
                    FireController.instance.channelRoleCount(groupId: groupId, channelId: channelId, role: "owner") { count in
                        if count != nil && count! < 2 {
                            self.alert(title: "Only Owner", message: "Channels need at least one owner.")
                            return
                        }
                        let updates: [String: Any] = [
                            memberChannelsPath: self.roleNext!,
                            channelMembersPath: self.roleNext!
                        ]
                        FireController.db.updateChildValues(updates)
                        self.closeAction(sender: nil)
                    }
                    return
                }

                let updates: [String: Any] = [
                    memberChannelsPath: self.roleNext!,
                    channelMembersPath: self.roleNext!
                ]
                FireController.db.updateChildValues(updates)
                closeAction(sender: nil)
            }
        }
    }
    
    func remove() {
        let userTitle = self.inputUser!.profile?.fullName ?? self.inputUser!.username!
        let targetTitle = self.target == .group ? "group" : "channel"
        
        DeleteConfirmationAlert(
            title: "Confirm",
            message: "Are you sure you want to remove \(userTitle) from this \(targetTitle)?",
        actionTitle: "Remove", cancelTitle: "Cancel", delegate: self) { doIt in
            if doIt {
                self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                self.progress!.mode = MBProgressHUDMode.indeterminate
                self.progress!.styleAs(progressStyle: .activityWithText)
                self.progress!.minShowTime = 0.5
                self.progress!.labelText = "Removing..."
                self.progress!.removeFromSuperViewOnHide = true
                self.progress!.show(true)
                
                let userId = self.inputUser.id!
                let groupId = StateController.instance.groupId!
                if self.target == .group {
                    FireController.instance.removeUserFromGroup(userId: userId, groupId: groupId) { success in
                        self.progress?.hide(true)
                        if success {
                            self.closeAction(sender: nil)
                        }
                    }
                }
                else {
                    let channelId = self.inputChannel.id!
                    let channelName = self.inputChannel.name!
                    FireController.instance.removeUserFromChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName) { success in
                        self.progress?.hide(true)
                        if success {
                            self.closeAction(sender: nil)
                        }
                    }
                }
            }
        }
    }
}

extension MemberSettingsController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if self.target == .group {
            if indexPath.section == 0 {
                let selectedCell = tableView.cellForRow(at: indexPath)
                self.roleNext = selectedCell?.textLabel!.text!.lowercased()
                self.roleOwnerCell.accessoryType = .none
                self.roleMemberCell.accessoryType = .none
                self.roleGuestCell.accessoryType = .none
                selectedCell!.accessoryType = .checkmark
                self.tableView.reloadData()
            }
            else if self.roleNext == "guest" && indexPath.section == 1 {
                let controller = ChannelPickerController()
                let wrapper = AirNavigationController(rootViewController: controller)
                if self.channelsAfter.count > 0 {
                    for channelId in self.channelsAfter.keys {
                        let channel = self.channelsAfter[channelId]
                        controller.channels[channelId] = channel
                    }
                }
                controller.delegate = self
                controller.simplePicker = true
                self.navigationController?.present(wrapper, animated: true, completion: nil)
            }
        }
        else {
            if indexPath.section == 0 {
                let selectedCell = tableView.cellForRow(at: indexPath)
                self.roleNext = selectedCell?.textLabel!.text!.lowercased()
                self.roleOwnerCell.accessoryType = .none
                self.roleMemberCell.accessoryType = .none
                selectedCell!.accessoryType = .checkmark
                self.tableView.reloadData()
            }
        }
    }

    override func numberOfSections(in: UITableView) -> Int {
        if self.target == .group {
            return self.roleNext == "guest" ? 3 : 2
        }
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.target == .group {
            if section == 0 { return 3 }
            return 1
        }
        if section == 0 { return 2 }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.target == .group {
            if indexPath.section == 0 {
                if indexPath.row == 0 { return self.roleOwnerCell }
                if indexPath.row == 1 { return self.roleMemberCell }
                if indexPath.row == 2 { return self.roleGuestCell }
            }
            if (self.roleNext == "guest" && indexPath.section == 1) {
                bindChannels()
                return self.guestChannelsCell
            }
            return self.removeCell
        }
        if indexPath.section == 0 {
            if indexPath.row == 0 { return self.roleOwnerCell }
            if indexPath.row == 1 { return self.roleMemberCell }
        }
        return self.removeCell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.target == .group {
            if section == 0 {
                return "Group role".uppercased()
            }
            if self.roleNext == "guest" && section == 1 {
                return "Guest channels".uppercased()
            }
            return nil
        }
        if section == 0 {
            return "Channel role".uppercased()
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
    
    enum MemberTarget: Int {
        case group
        case channel
    }
}

extension MemberSettingsController: PickerDelegate {
    internal func update(channels: [String: Any]) {
        self.channelsAfter = channels
        self.tableView.reloadData()
    }
}
